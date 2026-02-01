resource "aws_ecr_repository" "app" {
  name                 = "ludacris-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = data.aws_subnets.eks.ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_eks_node_group" "megatron_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "cheap-ng"
  node_role_arn  = aws_iam_role.eks_node_role.arn
  subnet_ids     = data.aws_subnets.eks.ids

  instance_types = ["t3.medium"]   
  disk_size      = 20

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  capacity_type = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}

# alertmanager-slack-secret.tf

resource "aws_secretsmanager_secret" "alertmanager_slack" {
  name        = "prod/alertmanager/slackk"
  description = "Slack webhook URL for Alertmanager notifications"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "alertmanager-slack-integration"
  }

  lifecycle {
    ignore_changes = [
      # Don't let Terraform change the actual secret value
    ]
  }
}


# external-secrets-irsa.tf

# Data source to get your existing EKS cluster
data "aws_eks_cluster" "this" {
  name = "ludacris-cluster"
}
data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Extract OIDC provider from cluster
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  oidc_provider_id = "E13ACEB7DAF0642A828B4808A257C4AF"
  oidc_provider    = "oidc.eks.${local.region}.amazonaws.com/id/${local.oidc_provider_id}"
}


# IAM Role for External Secrets Service Account (IRSA)
resource "aws_iam_role" "external_secrets" {
  name = "external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/${local.oidc_provider_id}:sub" = "system:serviceaccount:external-secrets-system:external-secrets"
            "oidc.eks.us-east-1.amazonaws.com/id/${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "external-secrets-role"
    ManagedBy = "terraform"
  }
}


resource "aws_iam_role_policy_attachment" "external_secrets" {
  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}



# IAM Policy for External Secrets to read from Secrets Manager
resource "aws_iam_policy" "external_secrets" {
  name        = "ExternalSecretsPolicy"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:prod/alertmanager/*"
      }
    ]
  })
}

