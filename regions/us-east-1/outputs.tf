############################################
# VPC Outputs
############################################

output "vpc_id" {
  description = "Primary region VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Primary region private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

############################################
# Application Outputs
############################################

output "instance_security_group_id" {
  description = "Primary region EC2 Security Group ID"
  value       = module.alb_asg.instance_security_group_id
}

output "alb_dns_name" {
  description = "Primary region ALB DNS name"
  value       = module.alb_asg.alb_dns_name
}

output "alb_zone_id" {
  description = "Primary region ALB Hosted Zone ID"
  value       = module.alb_asg.alb_zone_id
}