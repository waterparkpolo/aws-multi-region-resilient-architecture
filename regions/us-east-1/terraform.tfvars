name = "project5-use1"

environment = "primary"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.101.0/24",
  "10.0.102.0/24"
]
############################################
# ALB / ASG
############################################

instance_type = "t3.micro"

desired_capacity = 3

min_size = 1

max_size = 6