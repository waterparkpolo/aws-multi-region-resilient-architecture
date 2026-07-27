terraform {
  backend "s3" {
    bucket         = "mikah-terraform-state-2026"
    key            = "project5/us-west-2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}