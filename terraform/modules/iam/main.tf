#  ECS Task Execution Role 
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_exec" {
  name               = "${var.environment}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = {
    Environment = var.environment
  }
}

# ECS-managed policy for ECR pulls & CloudWatch Logs
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy: S3 access + ECS service update
data "aws_iam_policy_document" "ecs_task_inline" {
  # Read raw-data bucket
  statement {
    sid     = "AllowReadRaw"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetObject", "s3:HeadObject"]
    resources = [
      var.raw_bucket_arn,
      "${var.raw_bucket_arn}/*",
    ]
  }

  # Read processed-data bucket
  statement {
    sid     = "AllowReadProcessed"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetObject", "s3:HeadObject"]
    resources = [
      var.processed_bucket_arn,
      "${var.processed_bucket_arn}/*",
    ]
  }

  # Write processed-data bucket
  statement {
    sid     = "AllowWriteProcessed"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
    resources = [
      var.processed_bucket_arn,
      "${var.processed_bucket_arn}/*",
    ]
  }

  # Write model bucket
  statement {
    sid     = "AllowWriteModel"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:HeadObject", "s3:GetObject"]
    resources = [
      var.model_bucket_arn,
      "${var.model_bucket_arn}/*",
    ]
  }

  # Allow updating the serve ECS service after training
  statement {
    sid     = "ECSControl"
    effect  = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition",
    ]
    resources = [
      var.cluster_arn,
      var.serve_service_arn,
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_inline" {
  name   = "${var.environment}-ecs-task-exec-inline"
  role   = aws_iam_role.ecs_task_exec.id
  policy = data.aws_iam_policy_document.ecs_task_inline.json
}


#  EventBridge → ECS RunTask Role 

data "aws_iam_policy_document" "eb_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eb_run_task" {
  name               = "${var.environment}-eb-run-task-role"
  assume_role_policy = data.aws_iam_policy_document.eb_assume.json

  tags = {
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "eb_run_policy" {
  # Allow EventBridge to launch your train task
  statement {
    sid     = "AllowRunTask"
    effect  = "Allow"
    actions = ["ecs:RunTask"]
    resources = [
      # family-only and all revisions
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.train_task_family}",
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.train_task_family}:*",
    ]
    condition {
      test     = "ArnLike"
      variable = "ecs:cluster"
      values   = [var.cluster_arn]
    }
  }

  # Allow EventBridge to pass execution role to ECS
  statement {
    sid     = "AllowPassRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eb_run_attach" {
  name   = "${var.environment}-eb-run-task-policy"
  role   = aws_iam_role.eb_run_task.id
  policy = data.aws_iam_policy_document.eb_run_policy.json
}
