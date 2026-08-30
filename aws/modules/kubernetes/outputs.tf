output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the EKS cluster (base64decode to PEM before use)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for the EKS cluster (sensitive — used by helm/kubernetes providers, never echoed)"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = aws_eks_cluster.this.name
      cluster = {
        server                     = aws_eks_cluster.this.endpoint
        certificate-authority-data = aws_eks_cluster.this.certificate_authority[0].data
      }
    }]
    contexts = [{
      name = aws_eks_cluster.this.name
      context = {
        cluster = aws_eks_cluster.this.name
        user    = aws_eks_cluster.this.name
      }
    }]
    current-context = aws_eks_cluster.this.name
    users = [{
      name = aws_eks_cluster.this.name
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
  sensitive = true
}

output "node_pool_names" {
  description = "Names of the EKS node pools"
  value       = [aws_eks_node_group.this.node_group_name]
}

output "oidc_provider_arn" {
  description = "ARN of the IRSA OIDC provider (for phase 3 IAM service-account roles)"
  value       = aws_iam_openid_connect_provider.main.arn
}