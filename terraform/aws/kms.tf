resource "aws_kms_key" "logs_key" {
  description = "${local.resource_prefix.value}-logs bucket key"

  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags = {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/kms.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "cd8fa2a7-4868-4cd1-993d-da4644808ce5"
  }
}

resource "aws_kms_alias" "logs_key_alias" {
  name          = "alias/${local.resource_prefix.value}-logs-bucket-key"
  target_key_id = aws_kms_key.logs_key.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
  # checkov:skip=CKV_AWS_109:Key policy; "*" resource refers only to the key it is attached to
  # checkov:skip=CKV_AWS_111:Key policy; "*" resource refers only to the key it is attached to
  # checkov:skip=CKV_AWS_356:Key policy; "*" resource refers only to the key it is attached to
  statement {
    sid       = "EnableAccountIAMPermissions"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "${local.resource_prefix.value} S3 data buckets key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags = {
    Name = "${local.resource_prefix.value}-s3-key"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/${local.resource_prefix.value}-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_kms_key" "rds_key" {
  description             = "${local.resource_prefix.value} RDS clusters key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags = {
    Name = "${local.resource_prefix.value}-rds-key"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/${local.resource_prefix.value}-rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

resource "aws_kms_key" "es_key" {
  description             = "${local.resource_prefix.value} Elasticsearch domain key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags = {
    Name = "${local.resource_prefix.value}-es-key"
  }
}

resource "aws_kms_alias" "es_key_alias" {
  name          = "alias/${local.resource_prefix.value}-es-key"
  target_key_id = aws_kms_key.es_key.key_id
}
