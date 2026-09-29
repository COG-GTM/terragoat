
data "aws_caller_identity" "current" {}

variable "company_name" {
  default = "acme"
}

variable "environment" {
  default = "dev"
}

locals {
  resource_prefix = {
    value = "${data.aws_caller_identity.current.account_id}-${var.company_name}-${var.environment}"
  }
}



variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-west-2"
}

variable ami {
  type    = "string"
  default = "ami-09a5b0b7edf08843d"
}

variable "dbname" {
  type        = "string"
  description = "Name of the Database"
  default     = "db1"
}

variable "password" {
  type        = "string"
  description = "Database password"
  default     = "Aa1234321Bb"
}

variable "neptune-dbname" {
  type        = "string"
  description = "Name of the Neptune graph database"
  default     = "neptunedb1"
}

variable "log_retention_days" {
  type        = number
  description = "Retention for CloudWatch log groups and S3 log archives (CIS/PCI require at least 365 days)"
  default     = 365
}
