############################################
# VPC
############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

############################################
# Subnets
############################################

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

############################################
# Networking Components
############################################

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "nat_eip_allocation_id" {
  description = "Elastic IP allocation ID for NAT (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].id : null
}

############################################
# Route Tables
############################################

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

############################################
# Metadata (useful for higher-level modules)
############################################

output "availability_zones" {
  description = "AZs used by this VPC"
  value       = var.availability_zones
}