resource "aws_neptune_cluster" "default" {
  cluster_identifier                   = var.neptune-dbname
  engine                               = "neptune"
  engine_version                       = "1.3.2.1"
  backup_retention_period              = 5
  preferred_backup_window              = "07:00-09:00"
  skip_final_snapshot                  = true
  iam_database_authentication_enabled  = false
  apply_immediately                    = true
  storage_encrypted                    = true
  kms_key_arn                          = aws_kms_key.neptune.arn
  enable_cloudwatch_logs_exports       = ["audit"]
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.audit.name
  tags = {
    git_commit           = "aa8fd16fd94cccf6af206e2f0922b5558f8ac514"
    git_file             = "terraform/aws/neptune.tf"
    git_last_modified_at = "2020-08-21 19:14:35"
    git_last_modified_by = "matt@bridgecrew.io"
    git_modifiers        = "matt"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "0d4cbb85-73ed-4ca0-b1da-296e4185f34e"
  }
}

resource "aws_neptune_cluster_instance" "default" {
  count              = 1
  cluster_identifier = aws_neptune_cluster.default.id
  engine             = "neptune"
  instance_class     = "db.t3.medium" # Smallest instance type listed for neptune https://aws.amazon.com/neptune/pricing/
  apply_immediately  = true
  #publicly_accessible                = true # No longer supported, API returns create error. See https://docs.aws.amazon.com/neptune/latest/userguide/api-instances.html#CreateDBInstance
  tags = {
    git_commit           = "5c6b5d60a8aa63a5d37e60f15185d13a967f0542"
    git_file             = "terraform/aws/neptune.tf"
    git_last_modified_at = "2021-05-02 10:06:10"
    git_last_modified_by = "nimrodkor@users.noreply.github.com"
    git_modifiers        = "matt/nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "9b2b45fd-6f9f-44fd-b8bc-868b1db178b3"
  }
}

resource "aws_neptune_cluster_snapshot" "default" {
  #checkov:skip=CKV_AWS_279:Snapshot encryption is inherited from the source cluster (storage_encrypted = true); aws_neptune_cluster_snapshot exposes storage_encrypted only as a read-only attribute
  #checkov:skip=CKV_AWS_280:Snapshot uses the source cluster's CMK (aws_kms_key.neptune); aws_neptune_cluster_snapshot exposes kms_key_id only as a read-only attribute
  db_cluster_identifier          = aws_neptune_cluster.default.id
  db_cluster_snapshot_identifier = "resourcetestsnapshot1"
}

resource "aws_neptune_cluster_parameter_group" "audit" {
  family      = "neptune1.3"
  name_prefix = "${var.environment}-neptune-audit-"
  description = "Neptune cluster parameters with audit logging enabled"

  parameter {
    name  = "neptune_enable_audit_log"
    value = "1"
  }
}

resource "aws_kms_key" "neptune" {
  description             = "${local.resource_prefix.value}-neptune storage key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}
