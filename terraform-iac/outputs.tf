output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}


output "alertmanager_slack_secret_arn" {
  value       = aws_secretsmanager_secret.alertmanager_slack.arn
  description = "ARN of the Alertmanager Slack secret"
}

output "external_secrets_role_arn" {
  value       = aws_iam_role.external_secrets.arn
  description = "IAM role ARN for External Secrets Operator"
}
