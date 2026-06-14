# API Gateway Outputs
output "api_gateway_endpoint" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.api_gateway_invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_gateway_id
}

# Lambda Function Outputs
output "alexa_skill_handler_lambda_arn" {
  description = "ARN of Alexa Skill Handler Lambda function"
  value       = module.lambda_functions.alexa_skill_handler_lambda_arn
}

output "menu_service_lambda_arn" {
  description = "ARN of Menu Service Lambda function"
  value       = module.lambda_functions.menu_service_lambda_arn
}

output "cart_service_lambda_arn" {
  description = "ARN of Cart Service Lambda function"
  value       = module.lambda_functions.cart_service_lambda_arn
}

output "order_service_lambda_arn" {
  description = "ARN of Order Service Lambda function"
  value       = module.lambda_functions.order_service_lambda_arn
}

# DynamoDB Outputs
output "session_table_name" {
  description = "DynamoDB Session Table Name"
  value       = module.dynamodb_tables.session_table_name
}

output "order_table_name" {
  description = "DynamoDB Order Table Name"
  value       = module.dynamodb_tables.order_table_name
}

output "menu_table_name" {
  description = "DynamoDB Menu Table Name"
  value       = module.dynamodb_tables.menu_table_name
}

output "inventory_table_name" {
  description = "DynamoDB Inventory Table Name"
  value       = module.dynamodb_tables.inventory_table_name
}

# EventBridge Outputs
output "eventbridge_bus_name" {
  description = "EventBridge Event Bus Name"
  value       = module.eventbridge.event_bus_name
}

output "eventbridge_bus_arn" {
  description = "EventBridge Event Bus ARN"
  value       = module.eventbridge.event_bus_arn
}

# Step Functions Outputs
output "order_processing_state_machine_arn" {
  description = "ARN of Order Processing State Machine"
  value       = module.step_functions.order_processing_state_machine_arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = module.monitoring.dashboard_url
}

# Deployment Information
output "deployment_info" {
  description = "Deployment summary information"
  value = {
    region      = var.aws_region
    environment = var.environment
    project     = var.project_name
  }
}
