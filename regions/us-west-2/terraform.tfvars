name = "project5-usw2"

environment = "secondary"

vpc_cidr = "10.1.0.0/16"

availability_zones = [
  "us-west-2a",
  "us-west-2b"
]

public_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]

private_subnet_cidrs = [
  "10.1.101.0/24",
  "10.1.102.0/24"
]
############################################
# ALB / ASG
############################################

instance_type = "t3.micro"

desired_capacity = 1

min_size = 1

max_size = 6