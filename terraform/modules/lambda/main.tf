# Lambda Module - All Lambda Functions

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "python_runtime" {
  type = string
}

variable "lambda_timeout" {
  type = number
}

variable "lambda_memory" {
  type = number
}

variable "lambda_ephemeral_storage" {
  type = number
}

variable "iam_lambda_role_arn" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "enable_xray" {
  type = bool
}

variable "session_table_name" {
  type = string
}

variable "order_table_name" {
  type = string
}

variable "menu_table_name" {
  type = string
}

variable "inventory_table_name" {
  type = string
}

variable "eventbridge_bus_name" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "enable_kms_encryption" {
  type = bool
}

variable "tags" {
  type = map(string)
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "alexa_skill_handler_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-alexa-skill-handler"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "menu_service_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-menu-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "cart_service_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-cart-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "inventory_service_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-inventory-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "upsell_service_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-upsell-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "order_service_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-order-service"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "pos_webhook_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-pos-webhook"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "kds_publisher_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-kds-publisher"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Alexa Skill Handler Lambda
resource "aws_lambda_function" "alexa_skill_handler" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-alexa-skill-handler"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      SESSION_TABLE     = var.session_table_name
      EVENTBRIDGE_BUS   = var.eventbridge_bus_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.alexa_skill_handler_logs]

  tags = var.tags
}

# Menu Service Lambda
resource "aws_lambda_function" "menu_service" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-menu-service"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      MENU_TABLE        = var.menu_table_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.menu_service_logs]

  tags = var.tags
}

# Cart Service Lambda
resource "aws_lambda_function" "cart_service" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-cart-service"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      SESSION_TABLE     = var.session_table_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.cart_service_logs]

  tags = var.tags
}

# Inventory Service Lambda
resource "aws_lambda_function" "inventory_service" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-inventory-service"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      INVENTORY_TABLE   = var.inventory_table_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.inventory_service_logs]

  tags = var.tags
}

# Upsell Service Lambda
resource "aws_lambda_function" "upsell_service" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-upsell-service"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      MENU_TABLE        = var.menu_table_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.upsell_service_logs]

  tags = var.tags
}

# Order Service Lambda
resource "aws_lambda_function" "order_service" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-order-service"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      ORDER_TABLE       = var.order_table_name
      EVENTBRIDGE_BUS   = var.eventbridge_bus_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.order_service_logs]

  tags = var.tags
}

# POS Webhook Lambda
resource "aws_lambda_function" "pos_webhook" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-pos-webhook"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      ORDER_TABLE       = var.order_table_name
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.pos_webhook_logs]

  tags = var.tags
}

# KDS Publisher Lambda
resource "aws_lambda_function" "kds_publisher" {
  filename            = "lambda_placeholder.zip"
  function_name       = "${var.project_name}-${var.environment}-kds-publisher"
  role                = var.iam_lambda_role_arn
  handler             = "lambda_handler.lambda_handler"
  runtime             = var.python_runtime
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory
  ephemeral_storage {
    size = var.lambda_ephemeral_storage
  }

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      AWS_REGION        = data.aws_region.current.name
      XRAY_ENABLED      = var.enable_xray ? "true" : "false"
    }
  }

  dynamic "kms_key_arn" {
    for_each = var.enable_kms_encryption ? [var.kms_key_id] : []
    content {
      kms_key_arn = kms_key_arn.value
    }
  }

  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  depends_on = [aws_cloudwatch_log_group.kds_publisher_logs]

  tags = var.tags
}

# Outputs
output "alexa_skill_handler_lambda_arn" {
  value = aws_lambda_function.alexa_skill_handler.arn
}

output "alexa_skill_handler_lambda_name" {
  value = aws_lambda_function.alexa_skill_handler.function_name
}

output "menu_service_lambda_arn" {
  value = aws_lambda_function.menu_service.arn
}

output "menu_service_lambda_name" {
  value = aws_lambda_function.menu_service.function_name
}

output "cart_service_lambda_arn" {
  value = aws_lambda_function.cart_service.arn
}

output "cart_service_lambda_name" {
  value = aws_lambda_function.cart_service.function_name
}

output "inventory_service_lambda_arn" {
  value = aws_lambda_function.inventory_service.arn
}

output "inventory_service_lambda_name" {
  value = aws_lambda_function.inventory_service.function_name
}

output "upsell_service_lambda_arn" {
  value = aws_lambda_function.upsell_service.arn
}

output "upsell_service_lambda_name" {
  value = aws_lambda_function.upsell_service.function_name
}

output "order_service_lambda_arn" {
  value = aws_lambda_function.order_service.arn
}

output "order_service_lambda_name" {
  value = aws_lambda_function.order_service.function_name
}

output "pos_webhook_lambda_arn" {
  value = aws_lambda_function.pos_webhook.arn
}

output "pos_webhook_lambda_name" {
  value = aws_lambda_function.pos_webhook.function_name
}

output "kds_publisher_lambda_arn" {
  value = aws_lambda_function.kds_publisher.arn
}

output "kds_publisher_lambda_name" {
  value = aws_lambda_function.kds_publisher.function_name
}
