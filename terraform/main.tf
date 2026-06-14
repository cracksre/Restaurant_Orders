# DynamoDB Tables Module
module "dynamodb_tables" {
  source = "./modules/dynamodb"

  project_name                = var.project_name
  environment                 = var.environment
  session_ttl_hours           = var.session_ttl_hours
  order_ttl_days              = var.order_ttl_days
  dynamodb_billing_mode       = var.dynamodb_billing_mode
  enable_kms_encryption       = var.enable_kms_encryption
  kms_key_id                  = module.kms.dynamodb_key_id

  tags = var.tags
}

# IAM Roles and Policies Module
module "iam_roles" {
  source = "./modules/iam"

  project_name              = var.project_name
  environment               = var.environment
  enable_kms_encryption     = var.enable_kms_encryption
  kms_key_id                = module.kms.lambda_key_id
  session_table_arn         = module.dynamodb_tables.session_table_arn
  order_table_arn           = module.dynamodb_tables.order_table_arn
  menu_table_arn            = module.dynamodb_tables.menu_table_arn
  inventory_table_arn       = module.dynamodb_tables.inventory_table_arn
  eventbridge_bus_arn       = module.eventbridge.event_bus_arn
  cloudwatch_logs_group_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"

  tags = var.tags

  depends_on = [module.kms]
}

# Lambda Functions Module
module "lambda_functions" {
  source = "./modules/lambda"

  project_name                = var.project_name
  environment                 = var.environment
  python_runtime              = var.python_runtime
  lambda_timeout              = var.lambda_timeout
  lambda_memory               = var.lambda_memory
  lambda_ephemeral_storage    = var.lambda_ephemeral_storage
  iam_lambda_role_arn         = module.iam_roles.lambda_execution_role_arn
  log_retention_days          = var.log_retention_days
  enable_xray                 = var.enable_xray
  
  # DynamoDB table names
  session_table_name          = module.dynamodb_tables.session_table_name
  order_table_name            = module.dynamodb_tables.order_table_name
  menu_table_name             = module.dynamodb_tables.menu_table_name
  inventory_table_name        = module.dynamodb_tables.inventory_table_name
  
  # EventBridge bus
  eventbridge_bus_name        = module.eventbridge.event_bus_name
  
  # KMS
  kms_key_id                  = module.kms.lambda_key_id
  enable_kms_encryption       = var.enable_kms_encryption

  tags = var.tags

  depends_on = [
    module.iam_roles,
    module.dynamodb_tables,
    module.kms
  ]
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name                = var.project_name
  environment                 = var.environment
  api_description             = "REST API for Restaurant Ordering Assistant"
  
  # Lambda function ARNs
  menu_service_lambda_arn     = module.lambda_functions.menu_service_lambda_arn
  menu_service_lambda_name    = module.lambda_functions.menu_service_lambda_name
  cart_service_lambda_arn     = module.lambda_functions.cart_service_lambda_arn
  cart_service_lambda_name    = module.lambda_functions.cart_service_lambda_name
  order_service_lambda_arn    = module.lambda_functions.order_service_lambda_arn
  order_service_lambda_name   = module.lambda_functions.order_service_lambda_name
  inventory_service_lambda_arn = module.lambda_functions.inventory_service_lambda_arn
  inventory_service_lambda_name = module.lambda_functions.inventory_service_lambda_name
  upsell_service_lambda_arn   = module.lambda_functions.upsell_service_lambda_arn
  upsell_service_lambda_name  = module.lambda_functions.upsell_service_lambda_name
  
  # IAM role
  api_gateway_invocation_role = module.iam_roles.api_gateway_invocation_role_arn
  
  enable_waf                  = true
  log_retention_days          = var.log_retention_days

  tags = var.tags

  depends_on = [module.lambda_functions, module.iam_roles]
}

# EventBridge Module
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name            = var.project_name
  environment             = var.environment
  bus_name                = "${var.project_name}-${var.environment}-bus"

  tags = var.tags
}

# Step Functions Module
module "step_functions" {
  source = "./modules/step_functions"

  project_name                = var.project_name
  environment                 = var.environment
  order_service_lambda_arn    = module.lambda_functions.order_service_lambda_arn
  pos_webhook_lambda_arn      = module.lambda_functions.pos_webhook_lambda_arn
  kds_publisher_lambda_arn    = module.lambda_functions.kds_publisher_lambda_arn
  iam_step_functions_role_arn = module.iam_roles.step_functions_execution_role_arn
  eventbridge_bus_arn         = module.eventbridge.event_bus_arn
  log_retention_days          = var.log_retention_days

  tags = var.tags

  depends_on = [
    module.lambda_functions,
    module.eventbridge,
    module.iam_roles
  ]
}

# KMS Encryption Module
module "kms" {
  source = "./modules/kms"

  project_name    = var.project_name
  environment     = var.environment
  enable_kms      = var.enable_kms_encryption
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region      = var.aws_region

  tags = var.tags
}

# CloudWatch and Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  project_name                = var.project_name
  environment                 = var.environment
  log_retention_days          = var.log_retention_days
  enable_cloudtrail           = var.enable_cloudtrail
  enable_xray                 = var.enable_xray
  
  # Lambda ARNs for monitoring
  lambda_arns = [
    module.lambda_functions.alexa_skill_handler_lambda_arn,
    module.lambda_functions.menu_service_lambda_arn,
    module.lambda_functions.cart_service_lambda_arn,
    module.lambda_functions.inventory_service_lambda_arn,
    module.lambda_functions.upsell_service_lambda_arn,
    module.lambda_functions.order_service_lambda_arn,
    module.lambda_functions.pos_webhook_lambda_arn,
    module.lambda_functions.kds_publisher_lambda_arn
  ]

  tags = var.tags
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}
