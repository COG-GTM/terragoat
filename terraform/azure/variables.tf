variable "subscription_id" {
  type        = string
  description = "The subscription ID to be scanned"
  default     = null
}

variable "location" {
  type    = string
  default = "East US"
}

variable "environment" {
  default     = "dev"
  description = "Must be all lowercase letters or numbers"
}

variable "management_source_address_prefixes" {
  type        = list(string)
  description = "CIDR ranges (bastion/VPN) allowed to reach SSH (22) and RDP (3389)"
  default     = ["10.0.0.0/16"]

  validation {
    condition     = !contains(var.management_source_address_prefixes, "*") && !contains(var.management_source_address_prefixes, "0.0.0.0/0") && !contains(var.management_source_address_prefixes, "Internet")
    error_message = "Management access must not be open to the internet."
  }
}