variable "subscription_id" {
  type        = string
  description = "The subscription ID to be scanned"
  default     = null
}

variable "location" {
  type    = string
  default = "East US"
}

variable "security_contact_email" {
  type        = string
  description = "Monitored email address that receives Defender for Cloud alerts"
}

variable "environment" {
  default     = "dev"
  description = "Must be all lowercase letters or numbers"
}