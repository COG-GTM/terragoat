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

variable "sql_authorized_networks" {
  description = "CIDR ranges authorized to reach the Cloud SQL instance public IP. Empty by default, which authorizes no network."
  type = list(object({
    name = string
    cidr = string
  }))
  default = []

  validation {
    condition     = alltrue([for n in var.sql_authorized_networks : n.cidr != "0.0.0.0/0"])
    error_message = "sql_authorized_networks must not contain 0.0.0.0/0."
  }
}

variable "location" {
  default = "us-central1c"
  type    = string
}