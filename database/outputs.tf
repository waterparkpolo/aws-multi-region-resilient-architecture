############################################
# Aurora Global Database Outputs
############################################

output "global_cluster_identifier" {
  description = "Aurora Global Database identifier"
  value       = aws_rds_global_cluster.this.id
}


############################################
# Primary Region Outputs
############################################

output "primary_cluster_endpoint" {
  description = "Primary Aurora writer endpoint"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_cluster_reader_endpoint" {
  description = "Primary Aurora reader endpoint"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "primary_cluster_arn" {
  description = "Primary Aurora cluster ARN"
  value       = aws_rds_cluster.primary.arn
}


############################################
# Secondary Region Outputs
############################################

output "secondary_cluster_endpoint" {
  description = "Secondary Aurora cluster endpoint"
  value       = aws_rds_cluster.secondary.endpoint
}

output "secondary_cluster_arn" {
  description = "Secondary Aurora cluster ARN"
  value       = aws_rds_cluster.secondary.arn
}


############################################
# Security Group Outputs
############################################

output "primary_db_security_group_id" {
  description = "Primary database security group ID"
  value       = aws_security_group.primary_db.id
}

output "secondary_db_security_group_id" {
  description = "Secondary database security group ID"
  value       = aws_security_group.secondary_db.id
}
############################################
# Secrets Manager Outputs
############################################

output "primary_secret_arn" {
  description = "ARN of the primary region database secret"

  value = aws_secretsmanager_secret.db_credentials.arn
}


output "secondary_secret_arn" {
  description = "ARN of the secondary region database secret"

  value = aws_secretsmanager_secret.db_credentials_secondary.arn
}