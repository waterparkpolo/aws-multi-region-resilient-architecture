variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}
############################################
# ALB / ASG Configuration
############################################

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Normal ASG desired capacity"
  type        = number
}

variable "min_size" {
  description = "Minimum ASG size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG size"
  type        = number
  default     = 6
}