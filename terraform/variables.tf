variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for all resources"
  type        = string
  default     = "restaurant-ordering"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "restaurant-ordering-assistant"
}

variable "python_runtime" {
  description = "Python runtime version for Lambda"
  type        = string
  default     = "python3.11"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "lambda_ephemeral_storage" {
  description = "Lambda ephemeral storage in MB"
  type        = number
  default     = 512
}

variable "session_ttl_hours" {
  description = "Session TTL in hours"
  type        = number
  default     = 2
}

variable "order_ttl_days" {
  description = "Order retention in days"
  type        = number
  default     = 90
}

variable "max_concurrent_sessions" {
  description = "Maximum concurrent Alexa sessions"
  type        = number
  default     = 500
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for DynamoDB and Lambda environment"
  type        = bool
  default     = true
}

variable "enable_xray" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
