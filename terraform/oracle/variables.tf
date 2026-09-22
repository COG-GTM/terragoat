variable "tenancy_id" {
  description = "value supplied by env var"
  default     = ""
}

variable "bucket_kms_key_id" {
  description = "OCID of the customer managed KMS key used to encrypt the object storage bucket. Empty uses Oracle managed keys."
  type        = string
  default     = ""
}