# 🏗️ Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                │
│  │   S3 Bucket  │────────▶│ Lambda Func  │                │
│  │ (GeoJSON)    │  Event  │ (Processor)  │                │
│  └──────────────┘         └──────┬───────┘                │
│                                   │                         │
│                                   ▼                         │
│                            ┌──────────────┐                │
│                            │  RDS PostGIS │                │
│                            │   Database   │                │
│                            └──────────────┘                │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ CloudWatch   │         │  VPC (Private)│                │
│  │    Logs      │         │   Subnets     │                │
│  └──────────────┘         └──────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. **S3 Bucket**
- **Purpose**: Stores GeoJSON files
- **Trigger**: Automatically triggers Lambda on file upload
- **Features**: Versioning, encryption, lifecycle policies

### 2. **Lambda Function**
- **Purpose**: Processes GeoJSON files
- **Trigger**: S3 object creation events
- **Runtime**: Python 3.11
- **Features**: 
  - Validates GeoJSON structure
  - Extracts features and properties
  - Inserts into PostGIS database
  - Error handling and logging

### 3. **RDS PostGIS Database**
- **Purpose**: Stores spatial data
- **Engine**: PostgreSQL with PostGIS extension
- **Features**:
  - Spatial indexing
  - Geometry storage (SRID 4326)
  - JSONB for flexible properties

### 4. **VPC & Networking**
- **Purpose**: Secure network isolation
- **Components**:
  - Public subnets (for internet access)
  - Private subnets (for RDS and Lambda)
  - Security groups (firewall rules)
  - NAT Gateway (for Lambda internet access)

### 5. **CloudWatch**
- **Purpose**: Monitoring and logging
- **Features**:
  - Lambda execution logs
  - Error tracking
  - Performance metrics

## Data Flow

1. **Upload**: User uploads GeoJSON file to S3 bucket
2. **Trigger**: S3 event triggers Lambda function
3. **Process**: Lambda downloads file, validates, and processes
4. **Store**: Features inserted into PostGIS database
5. **Log**: All actions logged to CloudWatch

## Local Development Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                           │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                │
│  │  PostGIS DB   │◀────────│  Flask API    │                │
│  │  Container    │         │  Container     │                │
│  └──────────────┘         └──────────────┘                │
│                                   │                         │
│                                   ▼                         │
│                            REST Endpoints:                  │
│                            - POST /upload                  │
│                            - GET /data                      │
│                            - GET /health                    │
└─────────────────────────────────────────────────────────────┘
```

## Security Features

1. **Network Isolation**: RDS in private subnets
2. **IAM Roles**: Least privilege access
3. **Encryption**: S3 and RDS encryption at rest
4. **Secrets**: Database passwords in variables (use Secrets Manager in prod)
5. **VPC**: Lambda and RDS in private network

## Scalability

- **Lambda**: Auto-scales with S3 events
- **RDS**: Can scale vertically (instance size) or horizontally (read replicas)
- **S3**: Unlimited storage, handles any file size

## Cost Optimization

- **Lambda**: Pay per invocation (free tier: 1M requests/month)
- **RDS**: Use db.t3.micro for dev (free tier eligible)
- **S3**: Pay for storage and requests (minimal for dev)
- **Estimated**: ~$15-20/month for dev environment

## Technology Stack

- **Infrastructure**: Terraform (Infrastructure as Code)
- **Compute**: AWS Lambda (serverless)
- **Storage**: S3 (object storage)
- **Database**: RDS PostgreSQL with PostGIS
- **Language**: Python 3.11
- **Libraries**: 
  - GeoPandas (spatial data processing)
  - psycopg2 (PostgreSQL driver)
  - boto3 (AWS SDK)

## Deployment Options

1. **Local Development**: Docker Compose
2. **AWS Deployment**: Terraform
3. **Hybrid**: Local testing, AWS production

