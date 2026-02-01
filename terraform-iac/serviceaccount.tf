resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = "external-secrets-system"
  }
}



# Create the ServiceAccount with IRSA annotation
resource "kubernetes_service_account_v1" "external_secrets" {
  metadata {
    name      = "external-secrets"
     namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
    
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
    }
  }

  depends_on = [aws_iam_role.external_secrets]
}