# Monitoring Module - CloudWatch, CloudTrail, X-Ray

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "enable_cloudtrail" {
  type = bool
}

variable "enable_xray" {
  type = bool
}

variable "lambda_arns" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

data "aws_caller_identity" "current" {}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "restaurant_ordering" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average" }],
            ["AWS/Lambda", "Errors", { stat = "Sum" }],
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits"],
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits"],
            ["AWS/ApiGateway", "Count"],
            ["AWS/ApiGateway", "Latency"],
            ["AWS/States", "ExecutionsFailed"],
            ["AWS/States", "ExecutionsSucceeded"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_caller_identity.current.account_id
          title  = "Restaurant Ordering System Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message, @duration | stats avg(@duration), count() by bin(5m)"
          region  = data.aws_caller_identity.current.account_id
          title   = "Lambda Performance"
        }
      }
    ]
  })
}

# CloudWatch Alarms for Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when Lambda errors exceed threshold"
  alarm_actions       = []

  tags = var.tags
}

# CloudWatch Alarm for API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_latency_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = "1500"
  alarm_description   = "Alert when API latency exceeds 1.5 seconds (p99 requirement)"
  alarm_actions       = []

  tags = var.tags
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail Configuration
resource "aws_cloudtrail" "main" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket[0].id
  is_multi_region_trail         = true
  is_organization_trail         = false
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_bucket_policy[0]]
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role[0].arn

  tags = var.tags
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AWSCloudTrailAclCheck"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action   = "s3:GetBucketAcl"
      Resource = aws_s3_bucket.cloudtrail_bucket[0].arn
    },
    {
      Sid    = "AWSCloudTrailWrite"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.cloudtrail_bucket[0].arn}/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    }]
  })
}

# IAM Role for CloudTrail
resource "aws_iam_role" "cloudtrail_role" {
  count = var.enable_cloudtrail ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  count = var.enable_cloudtrail ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudtrail-policy"
  role  = aws_iam_role.cloudtrail_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
    }]
  })
}

# X-Ray Service Map
resource "aws_xray_sampling_rule" "restaurant_ordering" {
  count           = var.enable_xray ? 1 : 0
  rule_name       = "${var.project_name}-${var.environment}-sampling-rule"
  priority        = 1000
  version         = 1
  reservoir_size  = 1
  fixed_rate      = 0.05
  url_path        = "*"
  host            = "*"
  http_method     = "*"
  service_type    = "*"
  service_name    = "*"
  resource_arn    = "*"

  attributes = {
    environment = var.environment
    project     = var.project_name
  }
}

# Outputs
output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.restaurant_ordering.dashboard_name}"
}

output "cloudtrail_bucket_name" {
  value = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail_bucket[0].id : ""
}

output "cloudtrail_arn" {
  value = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : ""
}
