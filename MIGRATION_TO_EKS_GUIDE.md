# Migration Guide: Lambda → EKS (geojson-ingestion-saas)

## 🎯 Quick Decision Matrix

If Lambda doesn't work after troubleshooting tomorrow:
- ✅ **Switch to geojson-ingestion-saas** (EKS/Kubernetes deployment)
- ✅ **Already fixed and ready** - database service bugs fixed
- ✅ **Docker Compose tested** - can deploy locally first

## 📋 Pre-Deployment Checklist

### 1. Prerequisites ✅

- [ ] EKS cluster available (or create one)
- [ ] kubectl configured and connected
- [ ] AWS credentials configured
- [ ] Docker installed (for local testing)
- [ ] ECR repository created (or use existing)

### 2. Database Connection

The EKS project uses the **same RDS PostGIS database** as Lambda:

```bash
# From your Lambda Terraform outputs or AWS console:
DB_HOST=silver-saas-postgres.csbuekwioimk.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=geojson_db  # or geojson_production_db
DB_USER=geojson_admin  # or your RDS username
DB_PASSWORD=<your-password>
```

### 3. Update Kubernetes Secret

Edit `geojson-ingestion-saas/k8s/secret.yaml`:

```bash
cd geojson-ingestion-saas/k8s

# Encode your values:
echo -n "your-db-host" | base64
echo -n "your-db-password" | base64
echo -n "your-db-name" | base64
echo -n "your-db-user" | base64

# Update secret.yaml with encoded values
```

Or use kubectl directly:

```bash
kubectl create secret generic geojson-db-secret \
  --from-literal=DB_HOST='your-rds-endpoint' \
  --from-literal=DB_PORT='5432' \
  --from-literal=DB_NAME='your-db-name' \
  --from-literal=DB_USER='your-db-user' \
  --from-literal=DB_PASSWORD='your-db-password' \
  --from-literal=DB_SSLMODE='prefer' \
  --dry-run=client -o yaml > secret.yaml
```

## 🚀 Quick Start Options

### Option 1: Local Docker Compose (Test First) ✅ RECOMMENDED

**Test locally before deploying to EKS:**

```bash
cd geojson-ingestion-saas

# Create .env file
cat > .env << EOF
DB_HOST=your-rds-endpoint
DB_PORT=5432
DB_NAME=your-db-name
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_SSLMODE=prefer
LOG_LEVEL=INFO
EOF

# Start services
docker-compose up --build

# Test health check
curl http://localhost:8000/healthz

# Test ingestion
curl -X POST http://localhost:8000/ingest \
  -F "file=@app/test.geojson"
```

**If Docker Compose works → EKS deployment will work!**

### Option 2: Deploy to EKS

#### Step 1: Build and Push Docker Image

```bash
cd geojson-ingestion-saas

# Set your ECR repository
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/geojson-ingestion"

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

# Build image
docker build -t geojson-ingestion:latest .

# Tag for ECR
docker tag geojson-ingestion:latest ${ECR_REPO}:latest

# Push to ECR
docker push ${ECR_REPO}:latest
```

#### Step 2: Update Deployment Image

Edit `geojson-ingestion-saas/k8s/deployment.yaml`:

```yaml
image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/geojson-ingestion:latest
```

Or replace with your ECR URL.

#### Step 3: Deploy to Kubernetes

```bash
cd geojson-ingestion-saas/k8s

# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

Or manually:

```bash
# Apply secret
kubectl apply -f secret.yaml

# Apply deployment
kubectl apply -f deployment.yaml

# Apply service
kubectl apply -f service.yaml

# Apply HPA (optional)
kubectl apply -f hpa.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/geojson-ingestion
```

#### Step 4: Get Service URL

```bash
# Get LoadBalancer IP/URL
kubectl get service geojson-ingestion-service

# Check pods
kubectl get pods -l app=geojson-ingestion

# Check logs
kubectl logs -l app=geojson-ingestion --tail=100
```

## 🔍 Testing After Deployment

### Health Check

```bash
# Get service endpoint
SERVICE_URL=$(kubectl get service geojson-ingestion-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health
curl http://${SERVICE_URL}/healthz
```

Expected response:
```json
{
  "status": "healthy",
  "service": "geojson-ingestion",
  "database_connected": true,
  "feature_count": 0
}
```

### Ingest GeoJSON

```bash
curl -X POST http://${SERVICE_URL}/ingest \
  -F "file=@test.geojson"
```

Or from S3:

```bash
# Download from S3 first
aws s3 cp s3://your-bucket/test.geojson /tmp/test.geojson

# Upload to API
curl -X POST http://${SERVICE_URL}/ingest \
  -F "file=@/tmp/test.geojson"
```

## 📊 Monitoring

```bash
# Watch pods
kubectl get pods -l app=geojson-ingestion -w

# View logs
kubectl logs -f -l app=geojson-ingestion

# Check HPA
kubectl get hpa geojson-ingestion-hpa

# Describe deployment
kubectl describe deployment geojson-ingestion

# Check service
kubectl describe service geojson-ingestion-service
```

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -l app=geojson-ingestion

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Database Connection Issues

```bash
# Test secret
kubectl get secret geojson-db-secret -o yaml

# Verify secret values (decoded)
kubectl get secret geojson-db-secret -o jsonpath='{.data.DB_HOST}' | base64 -d
kubectl get secret geojson-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Check if database is accessible from EKS
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h <your-rds-endpoint> -U <your-user> -d <your-db>
```

### Image Pull Errors

```bash
# Check if image exists in ECR
aws ecr describe-images --repository-name geojson-ingestion --region us-east-1

# Verify ECR permissions
aws ecr get-authorization-token --region us-east-1
```

## 🔄 Differences from Lambda

| Aspect | Lambda | EKS |
|--------|--------|-----|
| **Trigger** | S3 events (automatic) | HTTP API (manual/scripted) |
| **Scaling** | Automatic (AWS managed) | HPA (configurable) |
| **Cost** | Pay per invocation | Pay for running pods |
| **Latency** | Cold starts possible | Always warm |
| **Debugging** | CloudWatch Logs | kubectl logs |

## 📝 Integration with S3

Since EKS uses HTTP API (not S3 triggers), you'll need to:

### Option A: Use Lambda to Trigger EKS API

Keep a small Lambda that triggers the EKS API:

```python
import requests
import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    eks_url = os.getenv('EKS_SERVICE_URL')
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        # Download from S3
        file_obj = s3.get_object(Bucket=bucket, Key=key)
        file_content = file_obj['Body'].read()
        
        # Send to EKS API
        response = requests.post(
            f'{eks_url}/ingest',
            files={'file': (key, file_content, 'application/geo+json')}
        )
        
        return response.json()
```

### Option B: Cron Job / Scheduler

Use Kubernetes CronJob to poll S3 and ingest files:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: s3-geojson-ingester
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: s3-sync
            image: awscli:latest
            command:
            - /bin/sh
            - -c
            - |
              aws s3 sync s3://your-bucket/new/ /tmp/geojson/
              for file in /tmp/geojson/*.geojson; do
                curl -X POST http://geojson-ingestion-service/ingest -F "file=@$file"
                aws s3 mv "$file" s3://your-bucket/processed/
              done
```

## ✅ Success Criteria

After deployment, verify:

- [ ] Health check returns `database_connected: true`
- [ ] Can ingest GeoJSON files via `/ingest` endpoint
- [ ] Features appear in database
- [ ] Logs show successful processing
- [ ] Pods are running and healthy
- [ ] Service is accessible via LoadBalancer

## 🆘 If Still Having Issues

1. **Test locally first** - Docker Compose is easier to debug
2. **Check database connectivity** - RDS security groups must allow EKS access
3. **Verify secrets** - Base64 decode and verify values
4. **Check logs** - `kubectl logs` is your friend
5. **Review Kubernetes events** - `kubectl get events`

## 📞 Next Steps After Successful Deployment

1. Set up monitoring/alerting
2. Configure auto-scaling (HPA)
3. Set up CI/CD pipeline
4. Add authentication (if needed)
5. Set up API Gateway (optional)

---

**The geojson-ingestion-saas project is now fixed and ready for deployment!**

All critical bugs in `database_service.py` have been fixed. The project should work out of the box.

