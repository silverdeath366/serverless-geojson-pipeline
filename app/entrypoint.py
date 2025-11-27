"""
Core GeoJSON processing module for Lambda and local execution.
"""
import os
import json
import logging
import psycopg2
from typing import Dict, Any

logger = logging.getLogger(__name__)


def get_db_conn() -> psycopg2.extensions.connection:
    """
    Create and return a PostgreSQL database connection with retry logic.
    
    Reads connection parameters from environment variables:
    - DB_HOST: Database hostname (optionally with port as host:port)
    - DB_PORT: Database port (default: 5432)
    - DB_NAME: Database name
    - DB_USER/DB_USERNAME: Database username
    - DB_PASS/DB_PASSWORD: Database password
    
    Returns:
        psycopg2 connection object
        
    Raises:
        psycopg2.Error: If connection fails after retries
    """
    import time
    
    db_host = os.getenv("DB_HOST", "")
    db_port = os.getenv("DB_PORT", "5432")
    
    # Handle DB_HOST that includes port (format: host:port)
    if ":" in db_host:
        parts = db_host.split(":")
        db_host = parts[0]
        if len(parts) > 1:
            db_port = parts[1]
    
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER") or os.getenv("DB_USERNAME")
    db_password = os.getenv("DB_PASS") or os.getenv("DB_PASSWORD")
    
    if not all([db_host, db_name, db_user, db_password]):
        raise ValueError("Missing required database connection parameters")
    
    # Retry logic for connection
    max_retries = 3
    retry_delay = 1
    
    for attempt in range(max_retries):
        try:
            conn = psycopg2.connect(
                dbname=db_name,
                user=db_user,
                password=db_password,
                host=db_host,
                port=db_port,
                connect_timeout=10
            )
            logger.info(f"Database connection established to {db_host}:{db_port}")
            return conn
        except psycopg2.Error as e:
            if attempt < max_retries - 1:
                logger.warning(f"Connection attempt {attempt + 1} failed: {e}. Retrying...")
                time.sleep(retry_delay * (attempt + 1))
            else:
                logger.error(f"Failed to connect to database after {max_retries} attempts: {e}")
                raise


def process_geojson(filepath: str) -> int:
    """
    Process a GeoJSON file and insert features into PostGIS database.
    
    Args:
        filepath: Path to the GeoJSON file to process
        
    Returns:
        Number of features inserted
        
    Raises:
        FileNotFoundError: If file doesn't exist
        json.JSONDecodeError: If file is not valid JSON
        ValueError: If GeoJSON structure is invalid
        psycopg2.Error: If database operation fails
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"GeoJSON file not found: {filepath}")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in file {filepath}: {e}")
        raise

    # Validate GeoJSON structure
    if not isinstance(data, dict):
        raise ValueError("GeoJSON must be a JSON object")
    
    if data.get("type") != "FeatureCollection":
        raise ValueError(f"GeoJSON type must be 'FeatureCollection', got '{data.get('type')}'")

    features = data.get("features", [])
    if not features:
        logger.warning(f"No features found in {filepath}")
        return 0

    logger.info(f"Processing {len(features)} features from {filepath}")
    
    try:
        with get_db_conn() as conn:
            with conn.cursor() as cur:
                inserted_count = 0
                for idx, feature in enumerate(features):
                    try:
                        if not isinstance(feature, dict) or feature.get("type") != "Feature":
                            logger.warning(f"Skipping invalid feature at index {idx}")
                            continue
                        
                        properties = feature.get("properties", {})
                        name = properties.get("name", f"Feature_{idx}")
                        geometry = feature.get("geometry")
                        
                        if not geometry:
                            logger.warning(f"Skipping feature {idx}: no geometry")
                            continue
                        
                        geom_json = json.dumps(geometry)
                        cur.execute(
                            "INSERT INTO geo_data (name, geom) VALUES (%s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326))",
                            (name, geom_json)
                        )
                        inserted_count += 1
                    except Exception as e:
                        logger.error(f"Error inserting feature {idx}: {e}")
                        # Continue processing other features
                        continue
                
                conn.commit()
                logger.info(f"Successfully inserted {inserted_count} features into database")
                return inserted_count
                
    except psycopg2.Error as e:
        logger.error(f"Database error while processing {filepath}: {e}")
        raise
