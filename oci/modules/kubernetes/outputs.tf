output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.this.id
}

output "cluster_endpoint" {
  description = "OKE cluster control-plane endpoint (https URL)"
  value       = "https://${oci_containerengine_cluster.this.endpoints[0].public_endpoint}"
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the OKE cluster (extracted from the kubeconfig CA segment; base64decode before use)"
  value       = try(yamldecode(data.oci_containerengine_cluster_kube_config.this.content).clusters[0].cluster["certificate-authority-data"], "")
  # CA certificate marks the cluster trust boundary — never echo to console (T-05-21)
  sensitive = true
}

output "kubeconfig" {
  description = "Kubeconfig for the OKE cluster (used by the helm/kubernetes providers, never echoed to console)"
  value       = data.oci_containerengine_cluster_kube_config.this.content
  # Embeds CA + token auth — sensitive (T-05-21)
  sensitive = true
}

output "node_pool_names" {
  description = "Names of the OKE node pools"
  value       = [oci_containerengine_node_pool.this.name]
}