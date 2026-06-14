# AWS Deployment Plan - Restaurant Ordering Assistant

**Project**: Restaurant Ordering Assistant  
**Date**: January 2025  
**Environment**: Development  
**Region**: us-east-1  

## Executive Summary

This deployment plan provides step-by-step instructions to deploy a production-ready serverless restaurant voice ordering platform on AWS. The solution uses Python for application logic and Terraform for infrastructure-as-code deployment.

## Architecture Overview

### Compute Layer
- 8 AWS Lambda functions (Python 3.11)
- 256 MB memory allocation
- 30-second timeout
- Distributed across availability zones

### Data Layer
- DynamoDB with 4 tables (Session, Order, Menu, Inventory)
- On-demand billing (auto-scaling)
- Point-in-time recovery enabled
- Encryption at rest (KMS)

### API & Integration Layer
- API Gateway (regional)
- EventBridge (custom event bus)
- Step Functions (order processing workflow)
- AWS Bedrock (Claude 3.5 Sonnet AI)

### Monitoring & Security
- CloudWatch (logs, metrics, alarms)
- X-Ray (distributed tracing)
- CloudTrail (audit logging)
- KMS (encryption)

## Prerequisites Checklist

- [ ] AWS Account with appropriate IAM permissions
- [ ] AWS CLI v2 installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Python 3.9+ installed
- [ ] Git for version control
- [ ] ~$20/month budget for AWS resources

## Deployment Phases

### Phase 1: Preparation (30 minutes)

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd Restaurant_Orders
   ```

2. **Validate AWS Credentials**
   ```bash
   aws sts get-caller-identity
   # Output should show your AWS Account ID
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   chmod +x scripts/deploy.sh
   ```

4. **Review Terraform Variables**
   ```bash
   # Check current values in terraform/variables.tf
   # Customize as needed for your environment
   ```

### Phase 2: Infrastructure Deployment (45 minutes)

1. **Run Deployment Script**
   ```bash
   ./scripts/deploy.sh dev us-east-1
   ```

   This will:
   - ✅ Build Lambda deployment packages
   - ✅ Initialize Terraform
   - ✅ Validate Terraform configuration
   - ✅ Create infrastructure plan
   - ✅ Apply infrastructure changes
   - ✅ Export deployment outputs

2. **Deployment Outputs**
   After successful deployment, you'll receive:
   - API Gateway endpoint URL
   - Lambda function ARNs
   - DynamoDB table names
   - EventBridge bus name
   - CloudWatch dashboard URL

### Phase 3: Configuration (20 minutes)

1. **Create Bedrock Agent**
   ```bash
   # See: src/bedrock-agent/BEDROCK_AGENT_CONFIG.md
   # Manually create agent in AWS Bedrock Console:
   # 1. Navigate to Agents
   # 2. Create new agent: RestaurantOrderingAgent
   # 3. Attach Lambda tool functions
   # 4. Configure agent instructions
   ```

2. **Configure Alexa Skill**
   - Update skill manifest with API endpoint
   - Configure OAuth 2.0 if using AWS Lambda custom authorizer
   - Test intents with test data

3. **Integrate with POS System**
   - Update POS webhook URL in Lambda environment variables
   - Test order delivery to POS

### Phase 4: Testing & Validation (30 minutes)

1. **Unit Tests**
   ```bash
   # Run test suite
   pytest src/services/*/tests/ -v
   ```

2. **Integration Tests**
   ```bash
   # Test API endpoints
   API_ENDPOINT=$(terraform output -raw api_gateway_endpoint)
   curl $API_ENDPOINT/menu
   ```

3. **Load Testing**
   ```bash
   # Simulate 500 concurrent users
   ./scripts/load-test.sh $API_ENDPOINT 500 300
   
   # Verify metrics:
   # - p99 latency < 1500ms ✓
   # - Error rate < 1% ✓
   ```

4. **Manual Testing**
   - [ ] Test Alexa launch intent
   - [ ] Test menu browsing
   - [ ] Test adding items to cart
   - [ ] Test order confirmation
   - [ ] Test POS integration
   - [ ] Test KDS notifications

## Infrastructure Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| Lambda (10M invocations) | $2.00 |
| DynamoDB (on-demand) | $5.00 |
| API Gateway (10M requests) | $3.50 |
| CloudWatch (logs/metrics) | $5.00 |
| Step Functions (100K executions) | $2.50 |
| EventBridge | $0.35 |
| X-Ray | $1.00 |
| KMS (key + encryption) | $1.00 |
| **Total Estimated** | **$20.35** |

*Note: Costs vary based on actual usage. This assumes development/testing levels.*

## Post-Deployment Steps

### 1. Monitor Initial Operations
```bash
# Watch Lambda logs in real-time
aws logs tail /aws/lambda/restaurant-ordering-dev-alexa-skill-handler --follow

# Check CloudWatch metrics
# AWS Console → CloudWatch → Dashboards → restaurant-ordering-dev-dashboard
```

### 2. Configure Alerts
- [ ] Set up SNS notifications for alarms
- [ ] Configure email alerts for error rates > 5%
- [ ] Enable automated remediation if possible

### 3. Setup CI/CD Pipeline
- [ ] Configure GitHub Actions or CodePipeline
- [ ] Automate Lambda deployment on code push
- [ ] Setup approval gates for production

### 4. Documentation
- [ ] Document custom configurations
- [ ] Create operational runbook
- [ ] Record API endpoints and IDs
- [ ] Setup disaster recovery procedures

## Monitoring & Observability

### Key Metrics to Monitor

```
Lambda Performance:
- Invocation count: Target > 100/min during peak
- Error rate: Target < 1%
- Duration p99: Target < 1500ms
- Throttling: Should be 0

DynamoDB:
- Read/write throttling: Should be 0
- Consumed capacity: Monitor for hot partitions
- Item count growth: Track data retention

API Gateway:
- Request count: Should spike during meal times
- Latency p99: Target < 1500ms
- 4XX/5XX errors: Target < 1%

EventBridge:
- Rule matches: Should correlate with orders
- Failed invocations: Should be 0
```

### CloudWatch Alarms

Automatically created alarms:
- `restaurant-ordering-dev-lambda-errors` (threshold: 10 errors/5min)
- `restaurant-ordering-dev-api-latency` (threshold: 1500ms)

### Viewing Logs

```bash
# Alexa Skill Handler
aws logs tail /aws/lambda/restaurant-ordering-dev-alexa-skill-handler --follow

# Order Service
aws logs tail /aws/lambda/restaurant-ordering-dev-order-service --follow

# API Gateway Access Logs
aws logs tail /aws/apigateway/restaurant-ordering-dev --follow

# State Machine Logs
aws logs tail /aws/states/restaurant-ordering-dev --follow
```

## Scaling Considerations

### Current Capacity
- **Concurrency**: 500 simultaneous Alexa sessions
- **Request Rate**: 1000+ requests per second
- **Data Storage**: ~500MB for 90-day retention

### Scaling Triggers
If you exceed these metrics, consider:

| Metric | Trigger | Action |
|--------|---------|--------|
| Lambda concurrency | > 900/1000 | Increase reserved concurrency |
| DynamoDB | Frequent throttling | Review partition key design |
| API Gateway | > 10K req/s | Use caching, increase throttle settings |

## Disaster Recovery

### Backup Strategy
- **DynamoDB**: Point-in-time recovery enabled (35-day retention)
- **Terraform State**: S3 backend with versioning
- **Lambda Code**: Git repository with version history

### Recovery Procedures

**If Lambda function corrupted:**
```bash
# Redeploy from source
cd src/services/menu-service
zip -r lambda_deployment.zip lambda_handler.py
aws lambda update-function-code \
  --function-name restaurant-ordering-dev-menu-service \
  --zip-file fileb://lambda_deployment.zip
```

**If DynamoDB data lost:**
```bash
# Restore from point-in-time recovery
aws dynamodb restore-table-to-point-in-time \
  --source-table-name restaurant-ordering-dev-sessions \
  --target-table-name restaurant-ordering-dev-sessions-restored \
  --restore-date-time 2024-01-01T12:00:00Z
```

**If entire stack needs rebuild:**
```bash
# Destroy and redeploy
./scripts/destroy.sh dev
./scripts/deploy.sh dev us-east-1
```

## Troubleshooting Guide

### Deployment Failures

**Issue**: Terraform validation fails  
**Solution**:
```bash
cd terraform
terraform fmt -recursive
terraform validate
```

**Issue**: Lambda permissions denied  
**Solution**:
```bash
# Check IAM role
aws iam get-role-policy \
  --role-name restaurant-ordering-dev-lambda-execution-role \
  --policy-name restaurant-ordering-dev-lambda-dynamodb-policy
```

### Runtime Issues

**Issue**: "Table does not exist" error  
**Solution**:
```bash
# Verify table exists
aws dynamodb list-tables --query 'TableNames[?contains(@, `sessions`)]'

# Check table status
aws dynamodb describe-table --table-name restaurant-ordering-dev-sessions
```

**Issue**: API returns 502 Bad Gateway  
**Solution**:
```bash
# Check Lambda logs
aws logs tail /aws/lambda/restaurant-ordering-dev-* --follow

# Invoke Lambda directly to test
aws lambda invoke --function-name restaurant-ordering-dev-menu-service /tmp/response.json
cat /tmp/response.json
```

## Security Validation

- [ ] KMS encryption enabled for DynamoDB
- [ ] CloudTrail logging enabled
- [ ] API Gateway authorizers configured
- [ ] IAM roles follow least-privilege principle
- [ ] No hardcoded secrets in code
- [ ] SSL/TLS enabled on all endpoints
- [ ] DynamoDB encryption at rest enabled
- [ ] VPC endpoints configured (if using VPC)

## Sign-Off Checklist

Before going to production:

- [ ] All deployment steps completed successfully
- [ ] All tests passed (unit, integration, load)
- [ ] CloudWatch dashboards configured
- [ ] Alarms and notifications tested
- [ ] Backup and disaster recovery procedures documented
- [ ] Security review completed
- [ ] Performance testing meets requirements (p99 < 1.5s)
- [ ] Documentation completed
- [ ] Team trained on operations
- [ ] Cost monitoring setup

## Support & Escalation

For issues contact:
1. Review AWS CloudWatch logs and X-Ray traces
2. Check AWS service health dashboard
3. Consult AWS documentation
4. Contact AWS Support (production support plan recommended)

## Next Steps

1. **Execute Phase 1**: Preparation (follow checklist)
2. **Execute Phase 2**: Run deployment script
3. **Execute Phase 3**: Configure Bedrock and Alexa
4. **Execute Phase 4**: Comprehensive testing
5. **Monitor**: Setup ongoing monitoring and alerts
6. **Optimize**: Fine-tune based on actual usage patterns

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Ready for Deployment
