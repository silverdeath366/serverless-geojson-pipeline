"""
AWS Lambda handler for processing GeoJSON files from S3 events.
"""
import json
import boto3
import os
import logging
from typing import Dict, Any
from entrypoint import process_geojson

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for S3 event-triggered GeoJSON processing.
    
    Processes GeoJSON files uploaded to S3 and inserts features into PostGIS database.
    
    Args:
        event: S3 event containing Records with bucket and object information
        context: Lambda context object
        
    Returns:
        Response dictionary with statusCode and body containing insertion count
        
    Raises:
        KeyError: If event structure is invalid
        Exception: If file processing or database insertion fails
    """
    """
    Process S3 event records and return results.
    """
    results = []
    
    if not event.get("Records"):
        logger.warning("No records found in event")
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "No records in event"})
        }
    
    for record in event["Records"]:
        try:
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]
            
            # Sanitize filename to prevent path traversal
            import re
            safe_filename = re.sub(r'[^a-zA-Z0-9._-]', '_', os.path.basename(key))
            tmp_path = f"/tmp/{safe_filename}"
            
            logger.info(f"Processing file: s3://{bucket}/{key}")
            
            # Download file from S3
            s3.download_file(bucket, key, tmp_path)
            logger.info(f"Downloaded file to {tmp_path}")
            
            # Process GeoJSON
            inserted = process_geojson(tmp_path)
            logger.info(f"Successfully processed {inserted} features from {key}")
            
            results.append({
                "key": key,
                "inserted": inserted,
                "status": "success"
            })
            
        except KeyError as e:
            error_msg = f"Invalid event structure: {str(e)}"
            logger.error(error_msg, exc_info=True)
            results.append({
                "key": record.get("s3", {}).get("object", {}).get("key", "unknown"),
                "error": error_msg,
                "status": "error"
            })
        except Exception as e:
            error_msg = f"Failed to process {key}: {str(e)}"
            logger.error(error_msg, exc_info=True)
            results.append({
                "key": key,
                "error": error_msg,
                "status": "error"
            })
        finally:
            # Clean up temporary file
            if 'tmp_path' in locals() and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except OSError as e:
                    logger.warning(f"Failed to remove temp file {tmp_path}: {e}")

    # Determine overall status
    has_errors = any(r.get("status") == "error" for r in results)
    status_code = 500 if has_errors else 200
    
    return {
        "statusCode": status_code,
        "body": json.dumps({
            "results": results,
            "processed": len(results),
            "successful": sum(1 for r in results if r.get("status") == "success"),
            "failed": sum(1 for r in results if r.get("status") == "error")
        })
    }
