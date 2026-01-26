
terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "haven-terraform-state-bucket"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "haven-terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
