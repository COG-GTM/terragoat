resource "aws_elasticsearch_domain" "monitoring-framework" {
  domain_name           = "tg-${var.environment}-es"
  elasticsearch_version = "2.3"

  cluster_config {
    instance_type            = "t2.small.elasticsearch"
    instance_count           = 1
    dedicated_master_enabled = false
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = 1
  }


  ebs_options {
    ebs_enabled = true
    volume_size = 30
  }
  tags = {
    git_commit           = "e6d83b21346fe85d4fe28b16c0b2f1e0662eb1d7"
    git_file             = "terraform/aws/es.tf"
    git_last_modified_at = "2023-04-27 12:47:51"
    git_last_modified_by = "nadler@paloaltonetworks.com"
    git_modifiers        = "nadler/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "95131dec-d7c9-49bb-9aff-eb0e2736603b"
  }
}

variable "es_allowed_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs allowed to access the Elasticsearch domain. Defaults to the current account root."
  default     = []
}

locals {
  es_principal_arns = length(var.es_allowed_principal_arns) > 0 ? var.es_allowed_principal_arns : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

data aws_iam_policy_document "policy" {
  statement {
    actions = [
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpDelete",
    ]
    principals {
      type        = "AWS"
      identifiers = local.es_principal_arns
    }
    resources = [
      aws_elasticsearch_domain.monitoring-framework.arn,
      "${aws_elasticsearch_domain.monitoring-framework.arn}/*",
    ]
  }
}

resource "aws_elasticsearch_domain_policy" "monitoring-framework-policy" {
  domain_name     = aws_elasticsearch_domain.monitoring-framework.domain_name
  access_policies = data.aws_iam_policy_document.policy.json
}
