output "bucket_name" {
  description = "Name of the OCI Object Storage bucket"
  value       = oci_objectstorage_bucket.state.name
}

output "bucket_id" {
  description = "ID of the OCI Object Storage bucket"
  value       = oci_objectstorage_bucket.state.id
}

output "namespace" {
  description = "OCI Object Storage namespace of the bucket"
  value       = oci_objectstorage_bucket.state.namespace
}
