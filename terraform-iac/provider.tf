
terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "haven-terraform-state-bucket"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "haven-terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name]
  }
}
provider "helm" {
  # no nested "kubernetes" block here — Helm will use the cluster context
}