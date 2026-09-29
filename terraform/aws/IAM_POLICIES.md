# IAM policies in terraform/aws

What each IAM identity in this stack can do, and who can assume each role.

## `aws_iam_user.user` — inline policy `aws_iam_user_policy.userpolicy` (iam.tf)

Replaces the old `ec2:*`, `s3:*`, `lambda:*`, `cloudwatch:*` on `Resource: "*"`.
Every statement is scoped to one resource managed by this stack.

| Sid | Actions | Resource |
| --- | --- | --- |
| `ListDataBucket` | `s3:ListBucket` | `aws_s3_bucket.data` |
| `ReadWriteDataBucketObjects` | `s3:GetObject`, `s3:PutObject` | objects in `aws_s3_bucket.data` (`<bucket-arn>/*`) |
| `InvokeAnalysisLambda` | `lambda:GetFunction`, `lambda:InvokeFunction` | `aws_lambda_function.analysis_lambda` |
| `OperateDbAppInstance` | `ec2:StartInstances`, `ec2:StopInstances`, `ec2:RebootInstances` | `aws_instance.db_app` |
| `ReadAnalysisLambdaLogs` | `logs:DescribeLogStreams`, `logs:GetLogEvents`, `logs:FilterLogEvents` | log group `/aws/lambda/<analysis function name>` |

Not allowed any more: deleting objects or buckets, changing bucket policies/ACLs,
creating/updating/deleting Lambda functions, any other EC2 action (including
`RunInstances`, security groups, `Describe*`), and CloudWatch metrics/alarms.
CloudWatch metric read APIs (`cloudwatch:GetMetricData`, `ListMetrics`, ...) do
not support resource-level permissions, so they cannot be granted without
`Resource: "*"` and were dropped.

## `aws_iam_role.iam_for_lambda` — trust policy (lambda.tf)

Only `lambda.amazonaws.com` may call `sts:AssumeRole`, and only when
`aws:SourceAccount` equals this account's ID (cross-service confused deputy
protection). No permission policy is attached to the role.

## `aws_iam_role.iam_for_eks` — trust policy (eks.tf)

Only `eks.amazonaws.com` may call `sts:AssumeRole`, and only when
`aws:SourceAccount` equals this account's ID and `aws:SourceArn` matches
`arn:aws:eks:<region>:<account>:cluster/<prefix>-eks` (the cluster in this
stack). Permissions come from the AWS managed `AmazonEKSClusterPolicy` and
`AmazonEKSServicePolicy` attachments (unchanged).

## `aws_iam_role.ec2role` — trust policy (db-app.tf)

Only `ec2.amazonaws.com` may call `sts:AssumeRole` (unchanged). EC2 does not
populate `aws:SourceAccount`/`aws:SourceArn` when it assumes an instance-profile
role, so adding those conditions would stop the instance from getting
credentials; instance profiles also cannot be attached cross-account.
The role's permission policy `aws_iam_role_policy.ec2policy` still grants
`s3:*`, `ec2:*`, `rds:*` on `*` and is out of scope for this change.
