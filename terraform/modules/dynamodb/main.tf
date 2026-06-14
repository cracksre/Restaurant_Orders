# DynamoDB Tables Module

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "session_ttl_hours" {
  type = number
}

variable "order_ttl_days" {
  type = number
}

variable "dynamodb_billing_mode" {
  type = string
}

variable "enable_kms_encryption" {
  type = bool
}

variable "kms_key_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# Session Table
resource "aws_dynamodb_table" "session_table" {
  name           = "${var.project_name}-${var.environment}-sessions"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "sessionId"
  
  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  stream_specification {
    stream_view_type = "NEW_AND_OLD_IMAGES"
  }

  dynamic "server_side_encryption_specification" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      enabled     = true
      kms_key_arn = var.kms_key_id
    }
  }

  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = true
  }

  tags = var.tags
}

# Order Table
resource "aws_dynamodb_table" "order_table" {
  name           = "${var.project_name}-${var.environment}-orders"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "orderId"
  range_key      = "createdAt"
  
  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  global_secondary_index {
    name            = "sessionId-createdAt-index"
    hash_key        = "sessionId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  stream_specification {
    stream_view_type = "NEW_AND_OLD_IMAGES"
  }

  dynamic "server_side_encryption_specification" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      enabled     = true
      kms_key_arn = var.kms_key_id
    }
  }

  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = true
  }

  tags = var.tags
}

# Menu Table
resource "aws_dynamodb_table" "menu_table" {
  name           = "${var.project_name}-${var.environment}-menu"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "menuItemId"
  
  attribute {
    name = "menuItemId"
    type = "S"
  }

  attribute {
    name = "category"
    type = "S"
  }

  global_secondary_index {
    name            = "category-index"
    hash_key        = "category"
    projection_type = "ALL"
  }

  dynamic "server_side_encryption_specification" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      enabled     = true
      kms_key_arn = var.kms_key_id
    }
  }

  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = true
  }

  tags = var.tags
}

# Inventory Table
resource "aws_dynamodb_table" "inventory_table" {
  name           = "${var.project_name}-${var.environment}-inventory"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "itemId"
  
  attribute {
    name = "itemId"
    type = "S"
  }

  dynamic "server_side_encryption_specification" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      enabled     = true
      kms_key_arn = var.kms_key_id
    }
  }

  point_in_time_recovery_specification {
    point_in_time_recovery_enabled = true
  }

  tags = var.tags
}

# Outputs
output "session_table_name" {
  value = aws_dynamodb_table.session_table.name
}

output "session_table_arn" {
  value = aws_dynamodb_table.session_table.arn
}

output "order_table_name" {
  value = aws_dynamodb_table.order_table.name
}

output "order_table_arn" {
  value = aws_dynamodb_table.order_table.arn
}

output "menu_table_name" {
  value = aws_dynamodb_table.menu_table.name
}

output "menu_table_arn" {
  value = aws_dynamodb_table.menu_table.arn
}

output "inventory_table_name" {
  value = aws_dynamodb_table.inventory_table.name
}

output "inventory_table_arn" {
  value = aws_dynamodb_table.inventory_table.arn
}
