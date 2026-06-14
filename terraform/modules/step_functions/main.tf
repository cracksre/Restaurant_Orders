# Step Functions Module

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "order_service_lambda_arn" {
  type = string
}

variable "pos_webhook_lambda_arn" {
  type = string
}

variable "kds_publisher_lambda_arn" {
  type = string
}

variable "iam_step_functions_role_arn" {
  type = string
}

variable "eventbridge_bus_arn" {
  type = string
}

variable "log_retention_days" {
  type = number
}

variable "tags" {
  type = map(string)
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/states/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Order Processing State Machine
resource "aws_sfn_state_machine" "order_processing" {
  name       = "${var.project_name}-${var.environment}-order-processing"
  role_arn   = var.iam_step_functions_role_arn
  definition = jsonencode({
    Comment = "Order Processing Workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type = "Task"
        Resource = var.order_service_lambda_arn
        Next = "CreateOrder"
        ResultPath = "$.validation"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "OrderFailed"
          ResultPath  = "$.error"
        }]
      }
      CreateOrder = {
        Type = "Task"
        Resource = var.order_service_lambda_arn
        Next = "PublishOrderEvent"
        ResultPath = "$.order"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "OrderFailed"
          ResultPath  = "$.error"
        }]
      }
      PublishOrderEvent = {
        Type = "Task"
        Resource = "arn:aws:states:::events:putEvents"
        Parameters = {
          "Entries" = [{
            "Source"      = ["restaurant.ordering"]
            "DetailType"  = ["OrderConfirmed"]
            "Detail"      = "$.order"
            "EventBusName" = var.eventbridge_bus_arn
          }]
        }
        Next = "NotifyPOS"
        ResultPath = "$.event"
      }
      NotifyPOS = {
        Type = "Task"
        Resource = var.pos_webhook_lambda_arn
        Next = "NotifyKDS"
        ResultPath = "$.pos_notification"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "OrderFailed"
          ResultPath  = "$.error"
        }]
      }
      NotifyKDS = {
        Type = "Task"
        Resource = var.kds_publisher_lambda_arn
        Next = "OrderSuccess"
        ResultPath = "$.kds_notification"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "OrderFailed"
          ResultPath  = "$.error"
        }]
      }
      OrderSuccess = {
        Type = "Succeed"
      }
      OrderFailed = {
        Type = "Fail"
        Error = "OrderProcessingFailed"
        Cause = "Order processing workflow failed"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

  tags = var.tags
}

# Outputs
output "order_processing_state_machine_arn" {
  value = aws_sfn_state_machine.order_processing.arn
}

output "order_processing_state_machine_name" {
  value = aws_sfn_state_machine.order_processing.name
}
