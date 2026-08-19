output "bucket_id" {
  description = "ID of the GCS storage bucket"
  value       = google_storage_bucket.storage.id
}

output "bucket_name" {
  description = "Name of the GCS storage bucket"
  value       = google_storage_bucket.storage.name
}

output "bucket_url" {
  description = "URL of the GCS storage bucket"
  value       = google_storage_bucket.storage.url
}
