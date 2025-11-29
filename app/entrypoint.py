"""
Core GeoJSON processing module for Lambda and local execution.
"""
import os
import json
import logging
# Lazy import psycopg2 to allow Lambda to start even if import fails
# import psycopg2  # Moved inside function
from typing import Dict, Any, List

logger = logging.getLogger(__name__)


def get_db_conn():  # Type hint removed since psycopg2 is lazy imported
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
        ImportError: If psycopg2 cannot be imported
    """
    import time
    import psycopg2  # Lazy import - allows Lambda to start even if this fails
    
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


def validate_geojson_feature(feature: Dict[str, Any], index: int) -> Dict[str, Any]:
    """
    Validate a GeoJSON feature using Shapely for geometry validation.
    
    Args:
        feature: Feature dictionary to validate
        index: Feature index for error reporting
        
    Returns:
        Validated feature dictionary
        
    Raises:
        ValueError: If feature is invalid
    """
    # Lazy import shapely to avoid Lambda import issues
    try:
        from shapely.geometry import shape
        from shapely.validation import explain_validity
    except ImportError:
        logger.warning("Shapely not available, skipping geometry validation")
        # Fall back to basic validation
        if not isinstance(feature, dict):
            raise ValueError(f"Feature {index}: Feature must be a dictionary")
        if feature.get("type") != "Feature":
            raise ValueError(f"Feature {index}: Feature type must be 'Feature'")
        if "geometry" not in feature:
            raise ValueError(f"Feature {index}: Feature must have a 'geometry' field")
        return feature
    
    # Validate feature structure
    if not isinstance(feature, dict):
        raise ValueError(f"Feature {index}: Feature must be a dictionary")
    
    if feature.get("type") != "Feature":
        raise ValueError(f"Feature {index}: Feature type must be 'Feature'")
    
    if "geometry" not in feature:
        raise ValueError(f"Feature {index}: Feature must have a 'geometry' field")
    
    geometry = feature.get("geometry")
    if not isinstance(geometry, dict):
        raise ValueError(f"Feature {index}: Geometry must be a dictionary")
    
    if "type" not in geometry or "coordinates" not in geometry:
        raise ValueError(f"Feature {index}: Geometry must have 'type' and 'coordinates' fields")
    
    # Validate geometry using Shapely
    try:
        shapely_geom = shape(geometry)
        if not shapely_geom.is_valid:
            validity_explanation = explain_validity(shapely_geom)
            raise ValueError(f"Feature {index}: Invalid geometry: {validity_explanation}")
    except Exception as e:
        raise ValueError(f"Feature {index}: Geometry validation failed: {str(e)}")
    
    return feature


def process_geojson(filepath: str) -> int:
    """
    Process a GeoJSON file and insert features into PostGIS database.
    Enhanced with validation similar to geojson-ingestion-saas.
    
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
    if not isinstance(features, list):
        raise ValueError("Features must be an array")
    
    if not features:
        logger.warning(f"No features found in {filepath}")
        return 0

    logger.info(f"Processing {len(features)} features from {filepath}")
    
    # Validate and process features
    validated_features = []
    for i, feature in enumerate(features):
        try:
            validated_feature = validate_geojson_feature(feature, i)
            validated_features.append(validated_feature)
        except ValueError as e:
            logger.warning(f"Feature {i} validation failed: {e}")
            continue
        except Exception as e:
            logger.warning(f"Feature {i} validation error: {e}")
            continue
    
    if not validated_features:
        logger.warning(f"No valid features found in {filepath}")
        return 0
    
    logger.info(f"Validated {len(validated_features)} out of {len(features)} features")
    
    try:
        with get_db_conn() as conn:
            with conn.cursor() as cur:
                # Ensure table exists with proper schema
                cur.execute("""
                    CREATE EXTENSION IF NOT EXISTS postgis;
                    CREATE TABLE IF NOT EXISTS geo_data (
                        id SERIAL PRIMARY KEY,
                        name TEXT,
                        geom GEOMETRY(Geometry, 4326),
                        uploaded_at TIMESTAMP DEFAULT NOW()
                    );
                    CREATE INDEX IF NOT EXISTS idx_geo_data_geom ON geo_data USING GIST (geom);
                """)
                conn.commit()
                
                inserted_count = 0
                errors = []
                
                for idx, feature in enumerate(validated_features):
                    try:
                        properties = feature.get("properties", {})
                        name = properties.get("name") or properties.get("NAME") or properties.get("id") or f"Feature_{idx}"
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
                        error_msg = f"Error inserting feature {idx}: {e}"
                        logger.error(error_msg)
                        errors.append(error_msg)
                        # Continue processing other features
                        continue
                
                conn.commit()
                logger.info(f"Successfully inserted {inserted_count} features into database")
                if errors:
                    logger.warning(f"Encountered {len(errors)} errors during processing")
                return inserted_count
                
    except Exception as e:
        logger.error(f"Database error while processing {filepath}: {e}")
        raise
