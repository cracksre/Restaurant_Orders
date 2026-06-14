You are a Senior AWS Solutions Architect and Principal Software Engineer.

Build a complete production-ready Alexa Restaurant Ordering Demo.

Goal:

Implement a voice ordering system where a user can:

1. Launch Alexa skill
2. Ask for menu items
3. Add an item
4. Confirm order
5. Receive generated Order ID

Technology Requirements

AWS Services:

* Alexa Custom Skill
* API Gateway
* Lambda Python 3.12
* Amazon Bedrock
* DynamoDB
* CloudWatch
* KMS
* IAM

Infrastructure Requirements

Generate Terraform code for every AWS resource.

Terraform version:

> =1.7

AWS Provider:

> =5.0

Create separate Terraform modules:

modules/

api_gateway/
lambda/
dynamodb/
iam/
kms/
bedrock/
cloudwatch/

Create reusable variables and outputs.

Python Requirements

Generate Lambda code using:

boto3
ask-sdk-core
ask-sdk-model
pydantic
aws-lambda-powertools

Create requirements.txt.

Alexa Skill Requirements

LaunchRequest

Response:

"Welcome to Alexa Restaurant. Would you like to hear today's menu?"

Intent:

ShowMenuIntent

Sample Utterances:

Show menu

What do you have

Show entrees

Response:

Read menu items stored in DynamoDB.

Intent:

AddItemIntent

Slots:

MenuItem

Response:

Add item to cart.

Store cart in SessionTable.

Intent:

ConfirmOrderIntent

Response:

Create order.

Generate UUID order id.

Persist order to OrdersTable.

Read confirmation back to user.

Bedrock Requirements

Create RestaurantOrderingAgent.

Agent must have:

MenuLookupTool
OrderConfirmationTool

Implement Bedrock invocation using boto3.

Prompt Template:

You are a restaurant ordering assistant.

Never invent menu items.

Only use items returned from MenuTable.

Security Requirements

Enable KMS encryption.

Enable TLS.

Least privilege IAM policies.

No hardcoded secrets.

Use Secrets Manager.

DynamoDB Requirements

MenuTable

PK:
menuItemId

Attributes:

name
price
category

SessionTable

PK:
sessionId

Attributes:

cart
updatedAt

TTL:
2 hours

OrdersTable

PK:
orderId

Attributes:

items
total
status
createdAt

TTL:
90 days

CloudWatch Requirements

Create dashboard:

Alexa Requests
Lambda Duration
Lambda Errors
Order Count

Deployment Requirements

Generate:

terraform init

terraform plan

terraform apply

commands.

Generate GitHub Actions workflow.

Workflow stages:

lint
unit-test
terraform-plan
terraform-apply

Testing Requirements

Generate pytest test cases.

Create mock Alexa requests.

Create mock Bedrock responses.

Create mock DynamoDB responses.

Deliverables

Generate all source code.

Generate all Terraform.

Generate architecture documentation.

Generate deployment guide.

Generate sample Alexa interaction transcripts.

The generated solution must deploy successfully into AWS and be runnable end-to-end.
