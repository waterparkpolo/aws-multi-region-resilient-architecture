terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


############################################
# Primary Region Provider
############################################

provider "aws" {
  region = "us-east-1"
}


############################################
# Secondary Region Provider
############################################

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}