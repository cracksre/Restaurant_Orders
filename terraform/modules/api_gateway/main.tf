# API Gateway Module

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "api_description" {
  type = string
}

variable "menu_service_lambda_arn" {
  type = string
}

variable "menu_service_lambda_name" {
  type = string
}

variable "cart_service_lambda_arn" {
  type = string
}

variable "cart_service_lambda_name" {
  type = string
}

variable "order_service_lambda_arn" {
  type = string
}

variable "order_service_lambda_name" {
  type = string
}

variable "inventory_service_lambda_arn" {
  type = string
}

variable "inventory_service_lambda_name" {
  type = string
}

variable "upsell_service_lambda_arn" {
  type = string
}

variable "upsell_service_lambda_name" {
  type = string
}

variable "api_gateway_invocation_role" {
  type = string
}

variable "enable_waf" {
  type = bool
}

variable "log_retention_days" {
  type = number
}

variable "tags" {
  type = map(string)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# API Gateway REST API
resource "aws_apigateway_rest_api" "restaurant_api" {
  name        = "${var.project_name}-${var.environment}-api"
  description = var.api_description

  tags = var.tags
}

# API Gateway Account (for CloudWatch logging)
resource "aws_apigateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch_role.arn
}

# IAM Role for API Gateway CloudWatch logging
resource "aws_iam_role" "apigateway_cloudwatch_role" {
  name = "${var.project_name}-${var.environment}-apigateway-cloudwatch-role"

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
}

resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch_policy" {
  role       = aws_iam_role.apigateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# API Gateway Resources
resource "aws_apigateway_resource" "menu" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id
  parent_id   = aws_apigateway_rest_api.restaurant_api.root_resource_id
  path_part   = "menu"
}

resource "aws_apigateway_resource" "cart" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id
  parent_id   = aws_apigateway_rest_api.restaurant_api.root_resource_id
  path_part   = "cart"
}

resource "aws_apigateway_resource" "order" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id
  parent_id   = aws_apigateway_rest_api.restaurant_api.root_resource_id
  path_part   = "order"
}

resource "aws_apigateway_resource" "inventory" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id
  parent_id   = aws_apigateway_rest_api.restaurant_api.root_resource_id
  path_part   = "inventory"
}

resource "aws_apigateway_resource" "upsell" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id
  parent_id   = aws_apigateway_rest_api.restaurant_api.root_resource_id
  path_part   = "upsell"
}

# Menu Service Methods
resource "aws_apigateway_method" "menu_get" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.menu.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "menu_get_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.menu.id
  http_method      = aws_apigateway_method.menu_get.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.menu_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

# Cart Service Methods
resource "aws_apigateway_method" "cart_get" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.cart.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "cart_get_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.cart.id
  http_method      = aws_apigateway_method.cart_get.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.cart_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

resource "aws_apigateway_method" "cart_post" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.cart.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "cart_post_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.cart.id
  http_method      = aws_apigateway_method.cart_post.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.cart_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

# Order Service Methods
resource "aws_apigateway_method" "order_post" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.order.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "order_post_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.order.id
  http_method      = aws_apigateway_method.order_post.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.order_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

# Inventory Service Methods
resource "aws_apigateway_method" "inventory_get" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.inventory.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "inventory_get_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.inventory.id
  http_method      = aws_apigateway_method.inventory_get.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.inventory_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

# Upsell Service Methods
resource "aws_apigateway_method" "upsell_post" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.upsell.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_apigateway_integration" "upsell_post_integration" {
  rest_api_id      = aws_apigateway_rest_api.restaurant_api.id
  resource_id      = aws_apigateway_resource.upsell.id
  http_method      = aws_apigateway_method.upsell_post.http_method
  type             = "AWS_PROXY"
  integration_http_method = "POST"
  uri              = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.upsell_service_lambda_arn}/invocations"
  credentials      = var.api_gateway_invocation_role
}

# API Deployment
resource "aws_apigateway_deployment" "restaurant_api_deployment" {
  rest_api_id = aws_apigateway_rest_api.restaurant_api.id

  depends_on = [
    aws_apigateway_integration.menu_get_integration,
    aws_apigateway_integration.cart_get_integration,
    aws_apigateway_integration.cart_post_integration,
    aws_apigateway_integration.order_post_integration,
    aws_apigateway_integration.inventory_get_integration,
    aws_apigateway_integration.upsell_post_integration
  ]
}

# API Stage
resource "aws_apigateway_stage" "restaurant_api_stage" {
  deployment_id = aws_apigateway_deployment.restaurant_api_deployment.id
  rest_api_id   = aws_apigateway_rest_api.restaurant_api.id
  stage_name    = var.environment

  access_log_settings {
    cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.api_gateway_logs.arn}:*"
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationLatency = "$context.integration.latency"
    })
  }

  xray_tracing_enabled = true

  tags = var.tags
}

# Lambda Permissions
resource "aws_lambda_permission" "menu_service_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.menu_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigateway_rest_api.restaurant_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "cart_service_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.cart_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigateway_rest_api.restaurant_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "order_service_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.order_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigateway_rest_api.restaurant_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "inventory_service_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.inventory_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigateway_rest_api.restaurant_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "upsell_service_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.upsell_service_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigateway_rest_api.restaurant_api.execution_arn}/*/*"
}

# Outputs
output "api_gateway_id" {
  value = aws_apigateway_rest_api.restaurant_api.id
}

output "api_gateway_invoke_url" {
  value = aws_apigateway_stage.restaurant_api_stage.invoke_url
}

output "api_gateway_root_resource_id" {
  value = aws_apigateway_rest_api.restaurant_api.root_resource_id
}
