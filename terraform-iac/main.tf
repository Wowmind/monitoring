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