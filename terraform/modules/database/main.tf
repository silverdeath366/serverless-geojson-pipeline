resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.environment}-lambda-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-lambda-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "main" {
  family = "postgres17"
  name   = "${var.environment}-db-parameter-group"

  parameter {
    name  = "rds.force_ssl"
    value = var.environment == "prod" ? "1" : "0"  # Enforce SSL in production
  }

  parameter {
    name  = "log_statement"
    value = var.environment == "prod" ? "all" : "none"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.environment == "prod" ? "1000" : "-1"
  }

  tags = {
    Name = "${var.environment}-db-parameter-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-postgis-db"

  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az = var.environment == "prod"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot  = true

  skip_final_snapshot = var.environment != "prod"
  deletion_protection  = var.environment == "prod"
  
  performance_insights_enabled = var.environment == "prod"
  performance_insights_retention_period = var.environment == "prod" ? 7 : null

  tags = {
    Name = "${var.environment}-postgis-db"
  }
}

# PostGIS extension will be installed via init script in db/init.sql
# The extension is automatically installed when the database is created 