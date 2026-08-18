output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.state.name
}

output "bucket_url" {
  description = "URL of the GCS bucket"
  value       = google_storage_bucket.state.url
}

output "bucket_id" {
  description = "ID of the GCS bucket"
  value       = google_storage_bucket.state.id
}
