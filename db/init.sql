-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create geo_data table (compatible with current Lambda code)
CREATE TABLE IF NOT EXISTS geo_data (
  id SERIAL PRIMARY KEY,
  name TEXT,
  geom GEOMETRY(Geometry, 4326),
  uploaded_at TIMESTAMP DEFAULT NOW()
);

-- Create spatial index for better query performance
CREATE INDEX IF NOT EXISTS idx_geo_data_geom ON geo_data USING GIST (geom);

-- Create index on name for faster searches
CREATE INDEX IF NOT EXISTS idx_geo_data_name ON geo_data (name);

-- Create index on uploaded_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_geo_data_uploaded_at ON geo_data (uploaded_at);
