# Agents.md

## Project

Alexa Restaurant Voice Ordering Assistant

Build and deploy a production-ready serverless restaurant ordering platform that allows guests to place food orders through Alexa devices located at restaurant tables and kiosks.

The platform must support natural-language ordering, menu browsing, item customization, contextual upsells, cart management, inventory-aware recommendations, and POS/KDS integration.

---

## Business Goals

Reduce order entry errors.

Reduce front-of-house staffing requirements during peak periods.

Increase average check size through AI-generated upsells.

Provide a hands-free ordering experience.

---

## Acceptance Criteria

### Functional

Guest can:

* Launch Alexa skill
* Browse menu categories
* Add items with modifications
* Remove items
* Change quantities
* Review cart
* Confirm order
* Receive spoken order ID

### Non Functional

* p99 latency <= 1.5 seconds
* Support 500 concurrent Alexa sessions
* AES-256 encryption at rest
* TLS 1.2+ encryption in transit
* No payment card storage
* Order retention 90 days

---

## Required AWS Services

### Voice Layer

Amazon Alexa Custom Skill

### AI Layer

Amazon Bedrock
Claude Sonnet model

### Compute

AWS Lambda

### APIs

Amazon API Gateway

### Workflow

AWS Step Functions

### Data

Amazon DynamoDB

Tables:

MenuTable

PartitionKey:
menuItemId

OrderTable

PartitionKey:
orderId

TTL:
90 days

SessionTable

PartitionKey:
sessionId

InventoryTable

PartitionKey:
itemId

---

## Agent Design

Create a Bedrock Agent named:

RestaurantOrderingAgent

The agent must expose the following tools.

### MenuLookupTool

Returns menu categories and menu items.

### InventoryTool

Checks if an item is 86'd.

### CartTool

Maintains cart state.

### UpsellTool

Provides contextual upsells.

Examples:

Burger -> fries

Steak -> wine

Salmon -> dessert recommendation

### PricingTool

Calculates totals.

### OrderTool

Creates order.

### POSIntegrationTool

Sends order payload to external POS.

### KDSTool

Publishes kitchen order events.

---

## Alexa Intents

LaunchIntent

BrowseMenuIntent

AddItemIntent

ModifyItemIntent

RemoveItemIntent

ReviewCartIntent

ConfirmOrderIntent

CancelIntent

HelpIntent

---

## DynamoDB Schema

SessionTable

PK:
sessionId

Attributes:

cart
guestCount
lastIntent
conversationState

TTL:
2 hours

OrderTable

PK:
orderId

Attributes:

items
subtotal
tax
total
status
createdAt

TTL:
90 days

---

## Lambda Functions

SkillHandlerFunction

MenuServiceFunction

CartServiceFunction

InventoryServiceFunction

UpsellServiceFunction

OrderServiceFunction

POSWebhookFunction

KDSPublisherFunction

---

## Event Driven Design

OrderConfirmed Event

Publish to EventBridge.

Consumers:

POS Integration

Kitchen Display Integration

Analytics Pipeline

Notification Service

---

## Security

Enable KMS encryption.

Store secrets in Secrets Manager.

Use least privilege IAM roles.

Enable CloudTrail.

Enable AWS WAF on API Gateway.

Use Cognito for admin APIs.

No PCI data storage.

---

## Observability

CloudWatch Metrics

CloudWatch Logs

AWS X-Ray

Create dashboards for:

Order Volume

Order Latency

Upsell Conversion

Inventory Rejections

Alexa Errors

---

## Deployment

Use AWS CDK TypeScript.

Create:

API Gateway

Lambda Functions

DynamoDB Tables

EventBridge Bus

Step Functions

CloudWatch Dashboards

IAM Roles

Deploy using:

cdk bootstrap

cdk synth

cdk deploy

---

## Load Testing

Create a load test simulating:

500 concurrent Alexa sessions

Success criteria:

p99 latency <= 1.5 seconds

Error rate < 1%

---

## Deliverables

Source Code

Infrastructure as Code

Deployment Pipeline

Architecture Diagram

API Documentation

Operational Runbook

Load Test Results

Security Review Report

README
