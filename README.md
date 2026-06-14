# Restaurant Ordering Assistant - AWS Deployment Guide

A production-ready serverless restaurant voice ordering platform built on AWS that enables guests to place food orders through Alexa devices located at restaurant tables and kiosks.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Security](#security)

## 🎯 Overview

### Features

✅ **Voice-Based Ordering** - Alexa integration for hands-free ordering  
✅ **Natural Language Processing** - Claude Sonnet 3.5 AI for intelligent interactions  
✅ **Real-Time Inventory** - Dynamic 86'd item management  
✅ **Smart Upsells** - AI-powered contextual recommendations  
✅ **POS Integration** - Seamless integration with point-of-sale systems  
✅ **Kitchen Display** - Real-time order routing to kitchen  
✅ **Event-Driven Architecture** - Scalable EventBridge-based design  
✅ **High Availability** - Multi-AZ deployment with auto-scaling  

### Business Goals

- Reduce order entry errors
- Reduce front-of-house staffing during peak periods
- Increase average check size through AI-generated upsells
- Provide hands-free ordering experience

### Non-Functional Requirements

- **p99 Latency**: ≤ 1.5 seconds
- **Concurrency**: Support 500 concurrent Alexa sessions
- **Encryption**: AES-256 at rest, TLS 1.2+ in transit
- **Data Retention**: 90 days for orders, 2 hours for sessions
- **Uptime**: 99.9% availability

## 🏗️ Architecture

### Core Components

```
┌─────────────┐
│  Alexa      │
│  Devices    │
└──────┬──────┘
       │
┌──────▼──────────────────────┐
│   AWS API Gateway           │
│   REST API (regional)       │
└──────┬──────────────────────┘
       │
┌──────▼──────────────────────────────────────────────┐
│           AWS Lambda Functions (Python)             │
├────────────────┬──────────────┬──────────────────┤
│ Alexa Handler  │ Menu Service │ Cart Service     │
│ Inventory Svc  │ Order Svc    │ Upsell Svc       │
│ POS Webhook    │ KDS Publisher│                  │
└──────┬──────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────┐
│         AWS Data Layer                              │
├─────────────────┬──────────────┬───────────────────┤
│ DynamoDB        │ AWS Bedrock  │ EventBridge       │
│ (Session/Order) │ (Claude)     │ (Order Events)    │
│                 │              │                   │
│ Step Functions  │ CloudWatch   │ X-Ray             │
└─────────────────┴──────────────┴───────────────────┘
       │
┌──────▼──────────────────────────────────────────────┐
│    External Integrations                            │
├─────────────────┬──────────────┬───────────────────┤
│ POS System      │ Kitchen      │ Analytics         │
└─────────────────┴──────────────┴───────────────────┘
```

### AWS Services Used

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **Lambda** | Compute for microservices | Python 3.11, 256 MB memory, 30s timeout |
| **DynamoDB** | NoSQL database | 4 tables, PAY_PER_REQUEST billing |
| **API Gateway** | REST API endpoint | Regional API with CloudWatch logging |
| **EventBridge** | Event-driven integration | Custom event bus for order events |
| **Step Functions** | Workflow orchestration | Order processing state machine |
| **Bedrock + Claude** | AI/ML capabilities | Upsell recommendations & NLP |
| **KMS** | Encryption | AES-256 for data at rest |
| **CloudWatch** | Monitoring | Logs, metrics, alarms, dashboards |
| **X-Ray** | Distributed tracing | End-to-end request tracking |
| **CloudTrail** | Audit logging | API call history & compliance |

## 📋 Prerequisites

### Required Tools

- **AWS Account** with appropriate permissions
- **AWS CLI v2** - Configure with `aws configure`
- **Terraform >= 1.0**
- **Python 3.9+**
- **Git** for version control

### AWS Permissions

Your IAM user/role needs permissions for:
- Lambda, DynamoDB, API Gateway, EventBridge, Step Functions
- KMS, CloudWatch, X-Ray, CloudTrail, IAM

### Recommended Configuration

- **Region**: us-east-1 (or your preferred region)
- **Account Level**: Production AWS account (separate from dev)
- **VPC**: Default VPC (Lambda functions run serverless)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Restaurant_Orders
```

### 2. Install Dependencies

```bash
# Install Python packages
pip install -r requirements.txt

# Install Terraform (if not already installed)
# macOS
brew install terraform

# Linux
curl -fsSL https://apt.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### 3. Configure AWS Credentials

```bash
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 4. Deploy the Solution

```bash
# Make deployment script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh dev us-east-1

# For remote state backend (optional)
./scripts/deploy.sh dev us-east-1 true
```

## 📦 Deployment

### Deployment Process

The `deploy.sh` script performs the following steps:

1. **Validate AWS Credentials** - Ensures AWS CLI is properly configured
2. **Build Lambda Packages** - Creates deployment packages for all 8 Lambda functions
3. **Initialize Terraform** - Sets up Terraform working directory
4. **Create Configuration** - Generates `terraform.tfvars` with deployment parameters
5. **Validate Terraform** - Runs `terraform validate` to check syntax
6. **Plan Deployment** - Creates deployment plan via `terraform plan`
7. **Apply Deployment** - Executes infrastructure provisioning via `terraform apply`
8. **Export Outputs** - Saves deployment outputs to `deployment-outputs.json`

### Manual Terraform Commands

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# View outputs
terraform output
terraform output api_gateway_endpoint

# Destroy resources (⚠️ BE CAREFUL)
terraform destroy
```

### Deployment Variables

Edit `terraform/terraform.tfvars` to customize:

```hcl
aws_region                = "us-east-1"
project_name              = "restaurant-ordering"
environment               = "dev"
lambda_timeout            = 30         # seconds
lambda_memory             = 256        # MB
dynamodb_billing_mode     = "PAY_PER_REQUEST"
enable_kms_encryption     = true
enable_xray               = true
enable_cloudtrail         = true
log_retention_days        = 30
```

## ⚙️ Configuration

### Environment Variables

Each Lambda function uses environment variables for configuration:

```
SESSION_TABLE       - DynamoDB session table name
ORDER_TABLE         - DynamoDB order table name
MENU_TABLE          - DynamoDB menu table name
INVENTORY_TABLE     - DynamoDB inventory table name
EVENTBRIDGE_BUS     - EventBridge event bus name
ENVIRONMENT         - Deployment environment (dev/staging/prod)
AWS_REGION          - AWS region
XRAY_ENABLED        - Enable X-Ray tracing (true/false)
```

### DynamoDB Tables

#### SessionTable
- **Partition Key**: sessionId (String)
- **TTL**: expiresAt (2 hours)
- **Attributes**: cart, guestCount, conversationState, userId

#### OrderTable
- **Partition Key**: orderId (String)
- **Sort Key**: createdAt (String)
- **TTL**: expiresAt (90 days)
- **GSI**: sessionId-createdAt-index
- **Attributes**: items, subtotal, tax, total, status

#### MenuTable
- **Partition Key**: menuItemId (String)
- **GSI**: category-index
- **Attributes**: name, category, price, description

#### InventoryTable
- **Partition Key**: itemId (String)
- **Attributes**: available, quantity

### API Gateway Endpoints

```
GET     /menu                     - Get menu categories
GET     /menu?category=Appetizers - Get category items
POST    /cart                     - Add to cart
GET     /cart?sessionId=...       - Get cart
DELETE  /cart?sessionId=...       - Clear cart
POST    /order                    - Create order
GET     /order?id=...             - Get order
POST    /inventory/check          - Check availability
```

## 🧪 Testing

### Unit Tests

```bash
# Test individual Lambda functions
python -m pytest src/services/*/tests/

# Run specific test
python -m pytest src/services/menu-service/tests/test_menu.py
```

### Integration Tests

```bash
# Test API endpoints
curl https://<api-endpoint>/menu

# Add to cart
curl -X POST https://<api-endpoint>/cart \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"test-123","item":{"name":"Burger","price":12.99,"quantity":1}}'
```

### Load Testing

```bash
# Run load test (requires k6)
chmod +x scripts/load-test.sh
./scripts/load-test.sh https://<api-endpoint> 500 300

# Expected results:
# - p99 latency: < 1500ms
# - Error rate: < 1%
# - Concurrent users: 500
```

## 📊 Monitoring

### CloudWatch Dashboard

View the auto-generated dashboard:

```bash
# Get dashboard URL from Terraform outputs
terraform output dashboard_url

# Or access directly in AWS Console:
# CloudWatch → Dashboards → restaurant-ordering-dev-dashboard
```

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| Lambda Errors | > 10 errors | Check CloudWatch logs |
| API Latency | > 1500ms | Review Lambda performance |
| DynamoDB Throttling | Any | Increase throughput |
| Order Confirmation Rate | < 95% | Check POS integration |

### CloudWatch Alarms

Alarms are automatically created for:
- Lambda function errors (> 10 in 5 minutes)
- API Gateway latency (> 1.5 seconds average)
- DynamoDB throttling
- State machine failures

### X-Ray Tracing

Enable X-Ray to trace requests end-to-end:

```bash
# View service map
aws xray describe-service-graph --start-time 2024-01-01T00:00:00Z

# Get trace details
aws xray get-trace-summaries --start-time 2024-01-01T00:00:00Z
```

### CloudTrail Logging

All API calls are logged to CloudTrail for audit:

```bash
# Query CloudTrail events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=restaurant-ordering-dev
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Lambda Timeout

**Symptom**: "Task timed out after 30 seconds"  
**Solution**: 
- Increase `lambda_timeout` in terraform.tfvars
- Optimize Lambda code (remove unnecessary operations)
- Check DynamoDB performance

#### 2. DynamoDB Throttling

**Symptom**: "ProvisionedThroughputExceededException"  
**Solution**:
- Already using PAY_PER_REQUEST (auto-scaling)
- Check for hot partitions
- Review query patterns

#### 3. API Gateway 502 Bad Gateway

**Symptom**: "502 Bad Gateway" response  
**Solution**:
- Check Lambda function logs: `aws logs tail /aws/lambda/restaurant-ordering-dev-menu-service --follow`
- Verify Lambda has correct IAM permissions
- Check VPC configuration if using VPC Lambda

#### 4. EventBridge Rules Not Triggering

**Symptom**: Orders not being routed to POS/KDS  
**Solution**:
- Verify event bus name matches in Lambda environment variables
- Check EventBridge rule patterns in Terraform modules/eventbridge/main.tf
- Enable EventBridge rule: `aws events enable-rule --name restaurant-ordering-dev-order-confirmed`

#### 5. Bedrock Agent Errors

**Symptom**: "Access denied" when invoking Bedrock  
**Solution**:
- Ensure Lambda IAM role has bedrock:InvokeAgent permission
- Verify Bedrock is available in your region
- Check Bedrock model ID is correct

### Debug Commands

```bash
# Check Lambda logs
aws logs tail /aws/lambda/restaurant-ordering-dev-alexa-skill-handler --follow

# Check API Gateway logs
aws logs tail /aws/apigateway/restaurant-ordering-dev --follow

# Check DynamoDB table status
aws dynamodb describe-table --table-name restaurant-ordering-dev-sessions

# List all Lambda functions deployed
aws lambda list-functions --query 'Functions[?contains(FunctionName, `restaurant-ordering-dev`)]'

# Test Lambda directly
aws lambda invoke --function-name restaurant-ordering-dev-menu-service response.json
cat response.json
```

## 💰 Cost Optimization

### Cost Breakdown (Estimated Monthly)

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Lambda | 10M invocations | $2.00 |
| DynamoDB | On-demand | $5.00 |
| API Gateway | 10M requests | $3.50 |
| CloudWatch | Logs & metrics | $5.00 |
| **Total** | | **~$15-20** |

### Cost Optimization Tips

1. **Use DynamoDB On-Demand** (already configured)
   - No upfront capacity planning
   - Auto-scales with demand

2. **Lambda Optimization**
   - Use 256 MB memory (current setting is optimal)
   - Keep code lightweight (no heavy dependencies)
   - Use connection pooling for AWS services

3. **CloudWatch Logs**
   - Set appropriate retention (currently 30 days)
   - Use log filters to reduce log volume

4. **API Gateway**
   - Cache frequently accessed data
   - Use API keys/throttling to prevent abuse

## 🔐 Security

### Encryption

✅ **Data at Rest**: AES-256 via KMS (configurable)  
✅ **Data in Transit**: TLS 1.2+ via API Gateway  
✅ **Secrets**: Stored in AWS Secrets Manager  

### IAM Security

- ✅ Least privilege principle applied
- ✅ Service-specific roles created
- ✅ No wildcard (*) permissions
- ✅ Resource-based policies configured

### Authentication & Authorization

- ✅ API Gateway authentication via Alexa device tokens
- ✅ IAM roles for Lambda → AWS services
- ✅ Session tokens managed in DynamoDB
- ✅ No PCI card data stored (Alexa Payments)

### Audit & Compliance

- ✅ CloudTrail logging enabled
- ✅ All API calls logged
- ✅ X-Ray distributed tracing
- ✅ CloudWatch alarms for security events

### Security Best Practices

1. **Regularly Update Dependencies**
   ```bash
   pip install --upgrade boto3 requests
   ```

2. **Review IAM Permissions**
   ```bash
   aws iam get-role-policy --role-name restaurant-ordering-dev-lambda-execution-role --policy-name ...
   ```

3. **Monitor Unauthorized Access**
   - Check CloudTrail for failed API calls
   - Review X-Ray for anomalies

4. **Rotate Credentials**
   - AWS Access Keys: Rotate every 90 days
   - Database passwords: Use AWS Secrets Manager

## 📚 Additional Resources

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/latest/developerguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Bedrock User Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/)
- [Alexa Skills Kit Documentation](https://developer.amazon.com/en-US/docs/alexa/ask-overviews/what-is-the-alexa-skills-kit.html)

## 🤝 Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review AWS service documentation
3. Check CloudWatch logs for errors
4. Contact AWS Support if needed

## 📄 License

This project is provided as-is for restaurant ordering solutions.

---

**Last Updated**: January 2025  
**Version**: 1.0.0
