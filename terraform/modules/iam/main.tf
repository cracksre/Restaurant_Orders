# IAM Module - Roles and Policies

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_kms_encryption" {
  type = bool
}

variable "kms_key_id" {
  type = string
}

variable "session_table_arn" {
  type = string
}

variable "order_table_arn" {
  type = string
}

variable "menu_table_arn" {
  type = string
}

variable "inventory_table_arn" {
  type = string
}

variable "eventbridge_bus_arn" {
  type = string
}

variable "cloudwatch_logs_group_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Execution Policy (if needed)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda DynamoDB Access Policy
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-${var.environment}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          var.session_table_arn,
          var.order_table_arn,
          var.menu_table_arn,
          var.inventory_table_arn,
          "${var.session_table_arn}/index/*",
          "${var.order_table_arn}/index/*",
          "${var.menu_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Lambda EventBridge Policy
resource "aws_iam_role_policy" "lambda_eventbridge_policy" {
  name = "${var.project_name}-${var.environment}-lambda-eventbridge-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = var.eventbridge_bus_arn
      }
    ]
  })
}

# Lambda Bedrock Policy
resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "${var.project_name}-${var.environment}-lambda-bedrock-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent",
          "bedrock:InvokeModel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda X-Ray Write Policy
resource "aws_iam_role_policy" "lambda_xray_policy" {
  name = "${var.project_name}-${var.environment}-lambda-xray-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda KMS Policy
resource "aws_iam_role_policy" "lambda_kms_policy" {
  count = var.enable_kms_encryption ? 1 : 0
  name  = "${var.project_name}-${var.environment}-lambda-kms-policy"
  role  = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_id
      }
    ]
  })
}

# API Gateway Invocation Role
resource "aws_iam_role" "api_gateway_invocation_role" {
  name = "${var.project_name}-${var.environment}-api-gateway-invocation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# API Gateway Lambda Invocation Policy
resource "aws_iam_role_policy" "api_gateway_lambda_invocation" {
  name = "${var.project_name}-${var.environment}-api-gateway-lambda-invocation"
  role = aws_iam_role.api_gateway_invocation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

# Step Functions Execution Role
resource "aws_iam_role" "step_functions_execution_role" {
  name = "${var.project_name}-${var.environment}-step-functions-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Step Functions Lambda Invocation Policy
resource "aws_iam_role_policy" "step_functions_lambda_invocation" {
  name = "${var.project_name}-${var.environment}-step-functions-lambda-invocation"
  role = aws_iam_role.step_functions_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

# Outputs
output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  value = aws_iam_role.lambda_execution_role.name
}

output "api_gateway_invocation_role_arn" {
  value = aws_iam_role.api_gateway_invocation_role.arn
}

output "step_functions_execution_role_arn" {
  value = aws_iam_role.step_functions_execution_role.arn
}
