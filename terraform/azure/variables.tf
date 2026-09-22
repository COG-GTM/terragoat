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

variable "security_alert_email_addresses" {
  type        = list(string)
  description = "Recipients of SQL Advanced Threat Protection and vulnerability assessment alerts"
  default     = ["securityengineer@bridgecrew.io"]
}