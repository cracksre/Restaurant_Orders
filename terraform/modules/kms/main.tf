# KMS Module for encryption

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_kms" {
  type = bool
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type = map(string)
}

# KMS Key for DynamoDB
resource "aws_kms_key" "dynamodb_key" {
  count       = var.enable_kms ? 1 : 0
  description = "KMS key for DynamoDB encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  count         = var.enable_kms ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb_key[0].key_id
}

# KMS Key for Lambda Environment Variables
resource "aws_kms_key" "lambda_key" {
  count       = var.enable_kms ? 1 : 0
  description = "KMS key for Lambda environment variables encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "lambda_key_alias" {
  count         = var.enable_kms ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-lambda"
  target_key_id = aws_kms_key.lambda_key[0].key_id
}

# Outputs
output "dynamodb_key_id" {
  value = var.enable_kms ? aws_kms_key.dynamodb_key[0].id : ""
}

output "dynamodb_key_arn" {
  value = var.enable_kms ? aws_kms_key.dynamodb_key[0].arn : ""
}

output "lambda_key_id" {
  value = var.enable_kms ? aws_kms_key.lambda_key[0].id : ""
}

output "lambda_key_arn" {
  value = var.enable_kms ? aws_kms_key.lambda_key[0].arn : ""
}
