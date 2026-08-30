output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "cluster_endpoint" {
  description = "Endpoint URL of the GKE cluster API"
  value       = google_container_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the GKE cluster (base64decode to PEM before use)"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for the GKE cluster (sensitive — used by helm/kubernetes providers, never echoed)"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = google_container_cluster.this.name
      cluster = {
        server                     = google_container_cluster.this.endpoint
        certificate-authority-data = google_container_cluster.this.master_auth[0].cluster_ca_certificate
      }
    }]
    contexts = [{
      name = google_container_cluster.this.name
      context = {
        cluster = google_container_cluster.this.name
        user    = google_container_cluster.this.name
      }
    }]
    current-context = google_container_cluster.this.name
    users = [{
      name = google_container_cluster.this.name
      user = {
        token = data.google_client_config.current.access_token
      }
    }]
  })
  sensitive = true
}

output "node_pool_names" {
  description = "Names of the GKE node pools"
  value       = [google_container_node_pool.this.name]
}
