data "aws_ami" "amazon_linux_2023" {

  most_recent = true

  owners = [
    "amazon"
  ]

  filter {
    name = "name"

    values = [
      "al2023-ami-*-x86_64"
    ]
  }

  filter {
    name = "architecture"

    values = [
      "x86_64"
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm"
    ]
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "alb_asg" {

  source = "../../modules/alb-asg"


  ############################################
  # Identity
  ############################################

  name = var.name

  environment = var.environment


  ############################################
  # Networking from VPC module
  ############################################

  vpc_id = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnet_ids

  private_subnet_ids = module.vpc.private_subnet_ids


  ############################################
  # Compute
  ############################################

  ami_id = data.aws_ami.amazon_linux_2023.id

  instance_type = var.instance_type


  ############################################
  # Scaling
  ############################################

  desired_capacity = var.desired_capacity

  min_size = var.min_size

  max_size = var.max_size
}