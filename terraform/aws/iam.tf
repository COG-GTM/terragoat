resource "aws_iam_user" "user" {
  name          = "${local.resource_prefix.value}-user"
  force_destroy = true

  tags = merge({
    Name        = "${local.resource_prefix.value}-user"
    Environment = local.resource_prefix.value
    }, {
    git_commit           = "d68d2897add9bc2203a5ed0632a5cdd8ff8cefb0"
    git_file             = "terraform/aws/iam.tf"
    git_last_modified_at = "2020-06-16 14:46:24"
    git_last_modified_by = "nimrodkor@gmail.com"
    git_modifiers        = "nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "9b45b298-c1ea-426a-9644-610780021eaa"
  })

}

resource "aws_iam_access_key" "user" {
  user = aws_iam_user.user.name
}

data "aws_iam_policy_document" "userpolicy" {
  # Start, stop and reboot the db-app EC2 instance only.
  statement {
    sid    = "ManageDbAppInstance"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
    ]
    resources = [aws_instance.db_app.arn]
  }

  # List the data bucket.
  statement {
    sid       = "ListDataBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn]
  }

  # Read and write objects in the data bucket (no delete, ACL or policy changes).
  statement {
    sid    = "ReadWriteDataBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.data.arn}/*"]
  }

  # Read configuration of and invoke the analysis Lambda function (no code or permission changes).
  statement {
    sid    = "InvokeAnalysisLambda"
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:InvokeFunction",
    ]
    resources = [aws_lambda_function.analysis_lambda.arn]
  }

  # Read the analysis Lambda function's CloudWatch Logs.
  statement {
    sid    = "ReadAnalysisLambdaLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.analysis_lambda.function_name}:*",
    ]
  }
}

resource "aws_iam_user_policy" "userpolicy" {
  name   = "${local.resource_prefix.value}-user-policy"
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.userpolicy.json
}

output "username" {
  value = aws_iam_user.user.name
}

output "secret" {
  value = aws_iam_access_key.user.encrypted_secret
}

