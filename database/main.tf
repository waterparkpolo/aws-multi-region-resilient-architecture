############################################
# Remote State - Regional Infrastructure
############################################

data "terraform_remote_state" "primary" {
  backend = "s3"

  config = {
    bucket = "mikah-terraform-state-2026"
    key    = "project5/us-east-1/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "secondary" {
  backend = "s3"

  config = {
    bucket = "mikah-terraform-state-2026"
    key    = "project5/us-west-2/terraform.tfstate"
    region = "us-east-1"
  }
}


############################################
# Database Security Groups
############################################

resource "aws_security_group" "primary_db" {
  name        = "${var.name}-${var.environment}-primary-db-sg"
  description = "Allow Aurora access from application instances"
  vpc_id      = data.terraform_remote_state.primary.outputs.vpc_id

  ingress {
    description = "MySQL access from application tier"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"

    security_groups = [
      data.terraform_remote_state.primary.outputs.instance_security_group_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


resource "aws_security_group" "secondary_db" {
  provider = aws.secondary

  name        = "${var.name}-${var.environment}-secondary-db-sg"
  description = "Allow Aurora access from application instances"
  vpc_id      = data.terraform_remote_state.secondary.outputs.vpc_id

  ingress {
    description = "MySQL access from application tier"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"

    security_groups = [
      data.terraform_remote_state.secondary.outputs.instance_security_group_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


############################################
# DB Subnet Groups
############################################

resource "aws_db_subnet_group" "primary" {
  name = "${var.name}-${var.environment}-primary-subnet-group"

  subnet_ids = data.terraform_remote_state.primary.outputs.private_subnet_ids

  tags = var.tags
}


resource "aws_db_subnet_group" "secondary" {
  provider = aws.secondary

  name = "${var.name}-${var.environment}-secondary-subnet-group"

  subnet_ids = data.terraform_remote_state.secondary.outputs.private_subnet_ids

  tags = var.tags
}


############################################
# Aurora Global Database
############################################

resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = var.global_cluster_identifier

  engine         = var.engine
  engine_version = var.engine_version
}


############################################
# Primary Aurora Cluster (Writer)
############################################

resource "aws_rds_cluster" "primary" {

  cluster_identifier = "${var.name}-${var.environment}-primary"

  engine         = var.engine
  engine_version = var.engine_version

  global_cluster_identifier = aws_rds_global_cluster.this.id

  database_name = var.database_name

  db_subnet_group_name = aws_db_subnet_group.primary.name

  vpc_security_group_ids = [
    aws_security_group.primary_db.id
  ]

  manage_master_user_password = true

  master_username = "admin"

  storage_encrypted = true

  backup_retention_period = 7

  skip_final_snapshot = true

  tags = var.tags
}


resource "aws_rds_cluster_instance" "primary" {

  identifier = "${var.name}-${var.environment}-primary-instance"

  cluster_identifier = aws_rds_cluster.primary.id

  engine = aws_rds_cluster.primary.engine

  instance_class = var.instance_class

  publicly_accessible = false

  tags = var.tags
}


############################################
# Secondary Aurora Cluster (Read Replica)
############################################

resource "aws_rds_cluster" "secondary" {

  provider = aws.secondary

  cluster_identifier = "${var.name}-${var.environment}-secondary"

  engine = var.engine

  engine_version = var.engine_version

  global_cluster_identifier = aws_rds_global_cluster.this.id

  db_subnet_group_name = aws_db_subnet_group.secondary.name

  vpc_security_group_ids = [
    aws_security_group.secondary_db.id
  ]

  storage_encrypted = true

  skip_final_snapshot = true

  depends_on = [
    aws_rds_cluster.primary
  ]

  tags = var.tags
}


resource "aws_rds_cluster_instance" "secondary" {

  provider = aws.secondary

  identifier = "${var.name}-${var.environment}-secondary-instance"

  cluster_identifier = aws_rds_cluster.secondary.id

  engine = aws_rds_cluster.secondary.engine

  instance_class = var.instance_class

  publicly_accessible = false

  tags = var.tags
}