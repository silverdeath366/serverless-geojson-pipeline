"""
Minimal test handler to diagnose import issues
"""
import json
import logging
import sys

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Minimal test handler - no imports except stdlib
    """
    try:
        logger.info("Test handler started")
        logger.info(f"Event: {json.dumps(event)}")
        
        # Test basic imports
        try:
            import boto3
            logger.info("✅ boto3 imported successfully")
        except Exception as e:
            logger.error(f"❌ boto3 import failed: {e}")
            raise
        
        # Test entrypoint import
        try:
            from entrypoint import process_geojson
            logger.info("✅ entrypoint imported successfully")
        except Exception as e:
            logger.error(f"❌ entrypoint import failed: {e}")
            logger.error(f"Import error details: {type(e).__name__}: {str(e)}", exc_info=True)
            raise
        
        # Test psycopg2 import (from entrypoint)
        try:
            import psycopg2
            logger.info("✅ psycopg2 imported successfully")
        except Exception as e:
            logger.error(f"❌ psycopg2 import failed: {e}")
            logger.error(f"Import error details: {type(e).__name__}: {str(e)}", exc_info=True)
            raise
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "All imports successful",
                "event": event
            })
        }
        
    except Exception as e:
        # Force error to logs
        error_msg = f"CRITICAL ERROR: {type(e).__name__}: {str(e)}"
        print(error_msg, file=sys.stderr)
        logger.error(error_msg, exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "type": type(e).__name__
            })
        }

