
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
# Kubernetes provider using data sources
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
provider "helm" {
  # no nested "kubernetes" block here — Helm will use the cluster context
}