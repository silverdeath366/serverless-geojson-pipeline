"""
Unit tests for entrypoint.py
"""
import unittest
import json
import tempfile
import os
from unittest.mock import patch, MagicMock
import sys

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

from entrypoint import process_geojson, get_db_conn


class TestEntrypoint(unittest.TestCase):
    """Test cases for entrypoint functions"""

    def setUp(self):
        """Set up test fixtures"""
        # Create a sample GeoJSON file
        self.sample_geojson = {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "properties": {"name": "Test Point 1"},
                    "geometry": {
                        "type": "Point",
                        "coordinates": [100.0, 0.0]
                    }
                },
                {
                    "type": "Feature",
                    "properties": {"name": "Test Point 2"},
                    "geometry": {
                        "type": "Point",
                        "coordinates": [101.0, 1.0]
                    }
                }
            ]
        }

    def test_process_geojson_valid_file(self):
        """Test processing a valid GeoJSON file"""
        # Create temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.geojson', delete=False) as f:
            json.dump(self.sample_geojson, f)
            temp_path = f.name

        try:
            # Mock database connection
            with patch('entrypoint.get_db_conn') as mock_conn:
                mock_cursor = MagicMock()
                mock_conn.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = mock_cursor
                mock_conn.return_value.__enter__.return_value.commit = MagicMock()

                # Call function
                result = process_geojson(temp_path)

                # Assertions
                self.assertEqual(result, 2)  # 2 features
                self.assertEqual(mock_cursor.execute.call_count, 2)  # 2 inserts
        finally:
            os.unlink(temp_path)

    def test_process_geojson_missing_name(self):
        """Test processing GeoJSON with missing name property"""
        geojson_no_name = {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "properties": {},
                    "geometry": {
                        "type": "Point",
                        "coordinates": [100.0, 0.0]
                    }
                }
            ]
        }

        with tempfile.NamedTemporaryFile(mode='w', suffix='.geojson', delete=False) as f:
            json.dump(geojson_no_name, f)
            temp_path = f.name

        try:
            with patch('entrypoint.get_db_conn') as mock_conn:
                mock_cursor = MagicMock()
                mock_conn.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = mock_cursor
                mock_conn.return_value.__enter__.return_value.commit = MagicMock()

                result = process_geojson(temp_path)

                # Should use "Unnamed" as default
                self.assertEqual(result, 1)
                # Check that "Unnamed" was used
                call_args = mock_cursor.execute.call_args[0]
                self.assertIn("Unnamed", call_args[1][0])
        finally:
            os.unlink(temp_path)

    @patch.dict(os.environ, {
        'DB_NAME': 'test_db',
        'DB_USER': 'test_user',
        'DB_PASS': 'test_pass',
        'DB_HOST': 'localhost',
        'DB_PORT': '5432'
    })
    @patch('entrypoint.psycopg2.connect')
    def test_get_db_conn(self, mock_connect):
        """Test database connection creation"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn

        conn = get_db_conn()

        mock_connect.assert_called_once_with(
            dbname='test_db',
            user='test_user',
            password='test_pass',
            host='localhost',
            port='5432'
        )
        self.assertEqual(conn, mock_conn)


if __name__ == '__main__':
    unittest.main()

