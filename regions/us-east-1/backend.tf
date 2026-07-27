terraform {
  backend "s3" {
    bucket         = "mikah-terraform-state-2026"
    key            = "project5/us-east-1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}