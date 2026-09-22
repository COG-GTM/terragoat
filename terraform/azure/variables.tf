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

variable "mssql_administrator_login" {
  type        = string
  default     = "missadministrator"
  description = "Administrator login for the Azure SQL servers"
}