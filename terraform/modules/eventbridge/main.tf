# EventBridge Module

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "bus_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

# EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "order_events" {
  name = var.bus_name

  tags = var.tags
}

# EventBridge Rules for order events
resource "aws_cloudwatch_event_rule" "order_confirmed" {
  name           = "${var.project_name}-${var.environment}-order-confirmed"
  event_bus_name = aws_cloudwatch_event_bus.order_events.name
  description    = "Triggered when an order is confirmed"

  event_pattern = jsonencode({
    source      = ["restaurant.ordering"]
    detail-type = ["OrderConfirmed"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "order_prepared" {
  name           = "${var.project_name}-${var.environment}-order-prepared"
  event_bus_name = aws_cloudwatch_event_bus.order_events.name
  description    = "Triggered when an order is prepared"

  event_pattern = jsonencode({
    source      = ["restaurant.ordering"]
    detail-type = ["OrderPrepared"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "order_ready" {
  name           = "${var.project_name}-${var.environment}-order-ready"
  event_bus_name = aws_cloudwatch_event_bus.order_events.name
  description    = "Triggered when an order is ready for pickup"

  event_pattern = jsonencode({
    source      = ["restaurant.ordering"]
    detail-type = ["OrderReady"]
  })

  tags = var.tags
}

# Outputs
output "event_bus_name" {
  value = aws_cloudwatch_event_bus.order_events.name
}

output "event_bus_arn" {
  value = aws_cloudwatch_event_bus.order_events.arn
}

output "order_confirmed_rule_name" {
  value = aws_cloudwatch_event_rule.order_confirmed.name
}

output "order_prepared_rule_name" {
  value = aws_cloudwatch_event_rule.order_prepared.name
}

output "order_ready_rule_name" {
  value = aws_cloudwatch_event_rule.order_ready.name
}
