############################################
# Core Identity
############################################

variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

############################################
# Network Configuration
############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (must match number of AZs used)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (must match number of AZs used)"
  type        = list(string)
}

variable "availability_zones" {
  description = "AZs to deploy subnets into (must align 1:1 with subnet CIDRs)"
  type        = list(string)
}

############################################
# NAT Gateway Configuration
############################################

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet outbound traffic"
  type        = bool
  default     = true
}

############################################
# Cost / Architecture Controls
############################################

variable "single_nat_gateway" {
  description = "If true, only one NAT Gateway is created (cost optimization for dev/staging)"
  type        = bool
  default     = true
}

############################################
# Tagging
############################################

variable "tags" {
  description = "Extra tags applied to all resources"
  type        = map(string)
  default     = {}
}