# 🗺️ GeoJSON Processing Pipeline

A production-ready, serverless GeoJSON ingestion pipeline built on AWS with complete Infrastructure as Code. Automatically processes spatial data files and stores them in a PostGIS database.

[![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20S3%20%7C%20RDS-blue)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-purple)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-Spatial%20Database-green)](https://postgis.net/)

## ✨ Features

- 🚀 **Serverless Architecture** - Event-driven processing with AWS Lambda
- 🗄️ **Spatial Database** - PostGIS for advanced geospatial queries
- 📦 **Infrastructure as Code** - Complete Terraform modules
- 🔧 **Fully Modular** - No hardcoded values, everything configurable
- 🐳 **Local Development** - Docker Compose for testing
- 🔒 **Production Ready** - Security, monitoring, error handling
- 🧪 **Tested** - Unit tests for core functionality

## 🏗️ Architecture

```
S3 Upload → Lambda Trigger → GeoJSON Processing → PostGIS Database
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## 🚀 Quick Start

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd geojson-pipeline
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **Start services:**
   ```bash
   docker-compose up --build
   ```

3. **Test the API:**
   ```bash
   # Health check
   curl http://localhost:5000/health
   
   # Upload GeoJSON
   curl -X POST -F "file=@app/geojson_sample/sample.geojson" http://localhost:5000/upload
   
   # Get data
   curl http://localhost:5000/data
   ```

### AWS Deployment

**For detailed AWS setup, see [SETUP_AWS.md](SETUP_AWS.md)**

1. **Configure AWS:**
   ```bash
   aws configure
   ```

2. **Create Terraform backend bucket:**
   ```bash
   aws s3 mb s3://your-terraform-state-bucket --region us-east-1
   ```

3. **Configure Terraform:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars - customize all names!
   ```

4. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📁 Project Structure

```
geojson-pipeline/
├── app/                    # Application code
│   ├── entrypoint.py      # Core processing logic
│   ├── lambda_handler.py  # AWS Lambda entry point
│   ├── run_local.py       # Local Flask API
│   └── requirements.txt   # Dependencies
├── terraform/             # Infrastructure as Code
│   ├── main.tf           # Main configuration
│   ├── modules/          # Reusable modules
│   │   ├── database/    # RDS PostGIS
│   │   ├── lambda/      # Lambda function
│   │   ├── storage/     # S3 bucket
│   │   ├── vpc/         # Networking
│   │   └── ...
│   └── variables.tf     # All configurable variables
├── tests/               # Unit tests
├── db/                  # Database schema
└── docs/                # Documentation
```

## ⚙️ Configuration

**Everything is configurable!** No hardcoded values.

Edit `terraform/terraform.tfvars`:

```hcl
# Project Configuration
project_name = "my-custom-pipeline"  # Your project name
environment  = "dev"

# AWS Configuration
aws_region = "us-east-1"

# Resource Names (all customizable)
s3_bucket_name = "my-unique-bucket-name"
lambda_function_name = "my-processor"
db_name = "mydb"
# ... and more
```

See `terraform/terraform.tfvars.example` for all options.

## 🧪 Testing

```bash
# Install test dependencies
pip install -r requirements-dev.txt

# Run tests
pytest tests/ -v

# With coverage
pytest tests/ --cov=app --cov-report=html
```

## 📊 Database Schema

```sql
CREATE TABLE geo_data (
  id SERIAL PRIMARY KEY,
  name TEXT,
  geom GEOMETRY(Geometry, 4326),
  uploaded_at TIMESTAMP DEFAULT NOW()
);
```

## 🔒 Security Features

- ✅ VPC with private subnets for RDS
- ✅ IAM roles with least privilege
- ✅ S3 and RDS encryption at rest
- ✅ Security groups for network isolation
- ✅ Secrets management ready

## 📈 Monitoring

- CloudWatch logs for Lambda execution
- CloudWatch metrics for performance
- Error tracking and alerting
- Database connection monitoring

## 💰 Cost Estimation

**Development Environment**: ~$15-20/month
- RDS db.t3.micro: ~$15/month
- Lambda: Free tier (1M requests/month)
- S3: Minimal storage costs

## 📚 Documentation

- [SETUP_AWS.md](SETUP_AWS.md) - Complete AWS setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture details
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview
- [QUICK_START.md](QUICK_START.md) - Quick reference

## 🛠️ Technology Stack

- **Infrastructure**: Terraform
- **Compute**: AWS Lambda (Python 3.11)
- **Storage**: S3
- **Database**: RDS PostgreSQL with PostGIS
- **Libraries**: GeoPandas, psycopg2, boto3, Flask

## 🎯 Use Cases

- Geospatial data ingestion
- Spatial analytics and queries
- Automated data pipelines
- REST API for spatial data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📊 Project Status

✅ **Production Ready** - Fully tested and deployed  
✅ **CI/CD** - Automated testing with GitHub Actions  
✅ **Documented** - Comprehensive documentation  
✅ **Modular** - Reusable Terraform modules  
✅ **Secure** - Production-grade security practices

## 🙏 Acknowledgments

Built with AWS, Terraform, Python, PostGIS, and Docker.

---

**Ready for production deployment and LinkedIn showcase!** 🚀
