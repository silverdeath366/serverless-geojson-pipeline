"""
AWS Lambda handler for processing GeoJSON files from S3 events.
Enhanced with better error handling and logging.
"""
import json
import boto3
import os
import logging
import traceback
from typing import Dict, Any
from entrypoint import process_geojson

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize S3 client
s3 = boto3.client("s3")


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda handler for S3 event-triggered GeoJSON processing.
    Enhanced with better error handling, logging, and validation.
    
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
    # Log handler invocation for debugging
    logger.info(f"Lambda handler invoked. Event keys: {list(event.keys())}")
    logger.info(f"Context: function_name={context.function_name if context else 'N/A'}, "
                f"request_id={context.aws_request_id if context else 'N/A'}")
    
    results = []
    tmp_path = None
    
    try:
        if not event.get("Records"):
            logger.warning("No records found in event")
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "No records in event", "event": str(event)[:500]})
            }
        
        logger.info(f"Processing {len(event['Records'])} record(s)")
        
        for record_idx, record in enumerate(event["Records"]):
            tmp_path = None
            try:
                # Extract S3 information
                bucket = record["s3"]["bucket"]["name"]
                key = record["s3"]["object"]["key"]
                
                # Sanitize filename to prevent path traversal
                import re
                safe_filename = re.sub(r'[^a-zA-Z0-9._-]', '_', os.path.basename(key))
                tmp_path = f"/tmp/{safe_filename}"
                
                logger.info(f"Processing record {record_idx + 1}: s3://{bucket}/{key}")
                
                # Validate file extension
                if not key.lower().endswith(('.geojson', '.json')):
                    logger.warning(f"Skipping non-GeoJSON file: {key}")
                    results.append({
                        "key": key,
                        "error": "File must be GeoJSON (.geojson or .json)",
                        "status": "skipped"
                    })
                    continue
                
                # Download file from S3
                logger.info(f"Downloading file from S3 to {tmp_path}")
                s3.download_file(bucket, key, tmp_path)
                
                # Verify file was downloaded
                if not os.path.exists(tmp_path):
                    raise FileNotFoundError(f"Downloaded file not found at {tmp_path}")
                
                file_size = os.path.getsize(tmp_path)
                logger.info(f"Downloaded file size: {file_size} bytes")
                
                # Process GeoJSON
                logger.info(f"Starting GeoJSON processing for {key}")
                inserted = process_geojson(tmp_path)
                logger.info(f"Successfully processed {inserted} features from {key}")
                
                results.append({
                    "key": key,
                    "inserted": inserted,
                    "status": "success",
                    "file_size": file_size
                })
                
            except KeyError as e:
                error_msg = f"Invalid event structure: {str(e)}"
                logger.error(f"KeyError in record {record_idx}: {error_msg}", exc_info=True)
                logger.error(f"Record structure: {json.dumps(record, default=str)[:500]}")
                results.append({
                    "key": record.get("s3", {}).get("object", {}).get("key", "unknown"),
                    "error": error_msg,
                    "status": "error",
                    "error_type": "KeyError"
                })
            except Exception as e:
                error_msg = f"Failed to process {key if 'key' in locals() else 'unknown'}: {str(e)}"
                error_trace = traceback.format_exc()
                logger.error(f"Exception in record {record_idx}: {error_msg}")
                logger.error(f"Traceback: {error_trace}")
                results.append({
                    "key": key if 'key' in locals() else "unknown",
                    "error": error_msg,
                    "status": "error",
                    "error_type": type(e).__name__
                })
            finally:
                # Clean up temporary file
                if tmp_path and os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                        logger.debug(f"Cleaned up temp file: {tmp_path}")
                    except OSError as e:
                        logger.warning(f"Failed to remove temp file {tmp_path}: {e}")

        # Determine overall status
        has_errors = any(r.get("status") == "error" for r in results)
        successful = sum(1 for r in results if r.get("status") == "success")
        failed = sum(1 for r in results if r.get("status") == "error")
        
        status_code = 500 if has_errors and successful == 0 else 200
        
        response_body = {
            "results": results,
            "processed": len(results),
            "successful": successful,
            "failed": failed,
            "skipped": sum(1 for r in results if r.get("status") == "skipped")
        }
        
        logger.info(f"Processing complete: {successful} successful, {failed} failed")
        
        return {
            "statusCode": status_code,
            "body": json.dumps(response_body)
        }
        
    except Exception as e:
        # Catch-all for unexpected errors
        error_msg = f"Unexpected error in lambda_handler: {str(e)}"
        error_trace = traceback.format_exc()
        logger.error(error_msg)
        logger.error(f"Traceback: {error_trace}")
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": error_msg,
                "error_type": type(e).__name__,
                "results": results
            })
        }
