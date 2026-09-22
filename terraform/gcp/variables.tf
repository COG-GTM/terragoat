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

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "CIDR ranges allowed to reach instances in the VPC"
  default     = ["10.0.0.0/24"]
}

variable "location" {
  default = "us-central1c"
  type    = string
}