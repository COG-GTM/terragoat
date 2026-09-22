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

variable "firewall_source_ranges" {
  description = "Trusted CIDR ranges allowed to reach tagged instances. Defaults to the Google IAP TCP forwarding range."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "firewall_allowed_tcp_ports" {
  description = "TCP ports opened to firewall_source_ranges on tagged instances"
  type        = list(string)
  default     = ["22"]
}