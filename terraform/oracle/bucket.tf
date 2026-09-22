resource "oci_objectstorage_bucket" "secretsquirrel" {
  compartment_id        = oci_identity_compartment.tf-compartment.id
  name                  = "myreallysecretstore"
  namespace             = data.oci_objectstorage_namespace.example.namespace
  object_events_enabled = true
  access_type           = "NoPublicAccess"
  versioning            = "Enabled"
  kms_key_id            = var.bucket_kms_key_id != "" ? var.bucket_kms_key_id : null
  metadata              = { "data" = "Blockofdata" }
  storage_tier          = "Standard"
  freeform_tags = {
    git_commit           = "7a7b957091945f77ecef712a92ac719c8d9a6498"
    git_file             = "terraform/oracle/bucket.tf"
    git_last_modified_at = "2022-04-06 10:43:57"
    git_last_modified_by = "james.woolfenden@gmail.com"
    git_modifiers        = "james.woolfenden"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "a854aa89-5141-4518-a5dc-0ffe3075f209"
  }
}



