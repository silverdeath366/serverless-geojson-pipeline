"""
Unit tests for lambda_handler.py
"""
import unittest
import json
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))


class TestLambdaHandler(unittest.TestCase):
    """Test cases for Lambda handler"""

    def setUp(self):
        """Set up test fixtures"""
        self.sample_event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-bucket"},
                        "object": {"key": "test.geojson"}
                    }
                }
            ]
        }
        self.sample_context = MagicMock()

    @patch('lambda_handler.process_geojson')
    @patch('lambda_handler.s3')
    def test_lambda_handler_success(self, mock_s3, mock_process):
        """Test successful Lambda execution"""
        from lambda_handler import lambda_handler

        # Mock S3 download
        mock_s3.download_file = MagicMock()

        # Mock processing
        mock_process.return_value = 5

        # Call handler
        result = lambda_handler(self.sample_event, self.sample_context)

        # Assertions
        self.assertEqual(result['statusCode'], 200)
        body = json.loads(result['body'])
        self.assertEqual(body['inserted'], 5)
        mock_s3.download_file.assert_called_once()
        mock_process.assert_called_once()

    @patch('lambda_handler.process_geojson')
    @patch('lambda_handler.s3')
    def test_lambda_handler_multiple_records(self, mock_s3, mock_process):
        """Test Lambda handler with multiple S3 records"""
        from lambda_handler import lambda_handler

        event_multiple = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-bucket"},
                        "object": {"key": "file1.geojson"}
                    }
                },
                {
                    "s3": {
                        "bucket": {"name": "test-bucket"},
                        "object": {"key": "file2.geojson"}
                    }
                }
            ]
        }

        mock_s3.download_file = MagicMock()
        mock_process.return_value = 3

        result = lambda_handler(event_multiple, self.sample_context)

        # Should process first record
        self.assertEqual(result['statusCode'], 200)
        self.assertEqual(mock_s3.download_file.call_count, 1)


if __name__ == '__main__':
    unittest.main()

