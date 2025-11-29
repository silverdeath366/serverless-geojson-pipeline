"""
Absolute minimal Lambda handler - just to test if Lambda can start
"""
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Minimal handler - no imports, just log and return
    """
    logger.info("MINIMAL HANDLER: Lambda started successfully!")
    logger.info(f"Event received: {json.dumps(event)}")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Minimal handler works!",
            "event": event
        })
    }

