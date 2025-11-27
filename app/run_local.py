import os
import json
import psycopg2
from flask import Flask, request, jsonify
from geojson import load
import geopandas as gpd
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

def get_db_conn():
    """Get database connection with error handling"""
    try:
        return psycopg2.connect(
            dbname=os.getenv("DB_NAME", "silver_saas"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASS", "password"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432")
        )
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise

def process_geojson(filepath):
    """Process GeoJSON file with GeoPandas and store in database"""
    try:
        # Load with GeoPandas for validation and processing
        gdf = gpd.read_file(filepath)
        
        # Validate geometry
        if not gdf.crs:
            gdf.set_crs(epsg=4326, inplace=True)
        
        with get_db_conn() as conn:
            with conn.cursor() as cur:
                # Create table if not exists
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS geo_data (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(255),
                        geom GEOMETRY(POINT, 4326),
                        properties JSONB,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                
                # Insert each feature
                for idx, row in gdf.iterrows():
                    name = row.get('name', f'Feature_{idx}')
                    geom = row.geometry.wkt
                    properties = json.dumps(row.drop('geometry').to_dict())
                    
                    cur.execute("""
                        INSERT INTO geo_data (name, geom, properties) 
                        VALUES (%s, ST_SetSRID(ST_GeomFromText(%s), 4326), %s)
                    """, (name, geom, properties))
                
                conn.commit()
                logger.info(f"Processed {len(gdf)} features from {filepath}")
                return len(gdf)
                
    except Exception as e:
        logger.error(f"Error processing {filepath}: {e}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Check database connection
        with get_db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        
        return jsonify({
            "status": "healthy",
            "database": "connected",
            "timestamp": "2024-01-01T00:00:00Z"
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "error": str(e)
        }), 500

@app.route('/ready', methods=['GET'])
def ready_check():
    """Readiness check endpoint"""
    try:
        # Check if application is ready to serve requests
        return jsonify({
            "status": "ready",
            "timestamp": "2024-01-01T00:00:00Z"
        }), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return jsonify({
            "status": "not_ready",
            "error": str(e)
        }), 500

@app.route('/upload', methods=['POST'])
def upload_geojson():
    """Upload and process GeoJSON file"""
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
        
        if not file.filename.endswith('.geojson'):
            return jsonify({"error": "File must be GeoJSON"}), 400
        
        # Sanitize filename to prevent path traversal
        import re
        safe_filename = re.sub(r'[^a-zA-Z0-9._-]', '_', os.path.basename(file.filename))
        if not safe_filename.endswith('.geojson'):
            safe_filename = safe_filename.rsplit('.', 1)[0] + '.geojson'
        
        # Save file temporarily with sanitized name
        temp_path = f"/tmp/{safe_filename}"
        file.save(temp_path)
        
        # Process the file
        features_processed = process_geojson(temp_path)
        
        # Clean up
        os.remove(temp_path)
        
        return jsonify({
            "message": "File processed successfully",
            "features_processed": features_processed,
            "filename": file.filename
        }), 200
        
    except Exception as e:
        logger.error(f"Upload failed: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/data', methods=['GET'])
def get_geo_data():
    """Retrieve processed geographic data"""
    try:
        with get_db_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, name, ST_AsGeoJSON(geom) as geometry, properties, created_at
                    FROM geo_data
                    ORDER BY created_at DESC
                    LIMIT 100
                """)
                rows = cur.fetchall()
                
                features = []
                for row in rows:
                    features.append({
                        "id": row[0],
                        "name": row[1],
                        "geometry": json.loads(row[2]),
                        "properties": row[3],
                        "created_at": row[4].isoformat()
                    })
                
                return jsonify({
                    "type": "FeatureCollection",
                    "features": features
                }), 200
                
    except Exception as e:
        logger.error(f"Data retrieval failed: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/', methods=['GET'])
def index():
    """Main application endpoint"""
    return jsonify({
        "name": "Silver SaaS GeoJSON Processor",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "ready": "/ready",
            "upload": "/upload",
            "data": "/data"
        }
    }), 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
