
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



variable "ssh_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to the web tier. Empty disables SSH ingress."
  default     = []

  validation {
    condition     = !contains(var.ssh_ingress_cidr_blocks, "0.0.0.0/0")
    error_message = "SSH must not be open to 0.0.0.0/0."
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