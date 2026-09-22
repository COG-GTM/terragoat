variable "credentials_path" {
  type        = string
  description = "Path to credentials file"
}

variable "project" {
  type        = string
  description = "The GCP project to be deployed to"
}

variable "region" {
  default = "us-central1"
  type    = string
}

variable "environment" {
  default     = "dev"
  description = "The environment name"
}

variable "location" {
  default = "us-central1c"
  type    = string
}

variable "bigquery_reader_group_emails" {
  type        = list(string)
  default     = []
  description = "Google group emails granted READER access to the BigQuery dataset"
}