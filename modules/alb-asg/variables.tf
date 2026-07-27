############################################
# Identity / Tagging
############################################

variable "name" {
  description = "Name prefix for ALB and ASG resources"
  type        = string
}

variable "environment" {
  description = "Environment identifier for resource tagging"
  type        = string
}

############################################
# Networking (from VPC module outputs)
############################################

variable "vpc_id" {
  description = "VPC ID where ALB and ASG resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where EC2 instances will be deployed"
  type        = list(string)
}

############################################
# Compute Configuration
############################################

variable "ami_id" {
  description = "AMI ID for EC2 Launch Template"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

############################################
# Auto Scaling Configuration
############################################

variable "desired_capacity" {
  description = "Number of EC2 instances running normally"
  type        = number
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances during scaling events"
  type        = number
  default     = 6
}

############################################
# Application Configuration
############################################

variable "app_port" {
  description = "Port application instances listen on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

############################################
# Tagging
############################################

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}