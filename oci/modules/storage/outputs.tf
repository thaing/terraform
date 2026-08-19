output "bucket_id" {
  description = "OCID of the Object Storage bucket"
  value       = oci_objectstorage_bucket.storage.id
}

output "bucket_name" {
  description = "Name of the Object Storage bucket"
  value       = oci_objectstorage_bucket.storage.name
}

output "namespace" {
  description = "Object Storage namespace"
  value       = oci_objectstorage_bucket.storage.namespace
}
