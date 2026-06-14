# Restaurant Ordering Assistant - Bedrock Agent Configuration

This file contains the configuration for the Bedrock Agent that will be created in your AWS account.

## Agent Name
RestaurantOrderingAgent

## Agent Description
An intelligent agent that manages restaurant ordering operations, including menu lookups, cart management, inventory checking, and providing AI-powered upsell recommendations.

## Required Tools

The following tools must be created in AWS Bedrock and attached to the agent:

### 1. MenuLookupTool
- **Type**: Lambda Function
- **Function**: menu-service Lambda
- **Description**: Returns menu categories and menu items
- **Parameters**:
  - action: "get_categories" | "get_items" | "search"
  - category: string (optional)
  - query: string (optional)

### 2. CartTool
- **Type**: Lambda Function
- **Function**: cart-service Lambda
- **Description**: Manages shopping cart state
- **Parameters**:
  - action: "add" | "remove" | "get" | "clear"
  - sessionId: string
  - item: object (for add action)

### 3. InventoryTool
- **Type**: Lambda Function
- **Function**: inventory-service Lambda
- **Description**: Checks item availability and 86'd items
- **Parameters**:
  - action: "check" | "update"
  - itemId: string
  - quantity: number (optional)

### 4. OrderTool
- **Type**: Lambda Function
- **Function**: order-service Lambda
- **Description**: Creates and manages orders
- **Parameters**:
  - action: "create" | "get" | "update_status"
  - orderId: string (optional)
  - orderData: object (for create action)

### 5. UpsellTool
- **Type**: Lambda Function
- **Function**: upsell-service Lambda
- **Description**: Provides contextual upsell recommendations
- **Parameters**:
  - items: array of ordered items
  - useAI: boolean (use Claude for AI recommendations)

### 6. PricingTool
- **Type**: Lambda Function
- **Function**: order-service Lambda
- **Description**: Calculates order totals
- **Parameters**:
  - items: array
  - applyDiscount: boolean (optional)

### 7. POSIntegrationTool
- **Type**: Lambda Function
- **Function**: pos-webhook Lambda
- **Description**: Sends order payload to external POS
- **Parameters**:
  - orderId: string
  - action: "send" | "acknowledge" | "error"

### 8. KDSTool
- **Type**: Lambda Function
- **Function**: kds-publisher Lambda
- **Description**: Publishes kitchen order events
- **Parameters**:
  - orderId: string
  - action: "publish" | "status_update" | "item_ready"

## Agent Instructions

The agent should follow these guidelines:

1. **Natural Language Understanding**: Parse customer requests naturally
2. **Context Management**: Maintain session context across interactions
3. **Order Validation**: Validate items are available before adding to cart
4. **Smart Recommendations**: Suggest relevant items based on order history
5. **Error Handling**: Provide helpful messages for unavailable items
6. **Order Confirmation**: Confirm all order details before submission
7. **POS Integration**: Ensure seamless integration with point-of-sale systems

## Manual Setup Steps in AWS Bedrock

1. Navigate to AWS Bedrock Console
2. Go to Agents → Create Agent
3. Enter agent name: `RestaurantOrderingAgent`
4. Add description as above
5. For each tool:
   - Click "Add tool"
   - Select "Lambda function"
   - Choose the corresponding Lambda function
   - Configure parameters as specified above
6. Define agent instructions (as per guidelines above)
7. Create and test the agent

## Testing the Agent

```bash
aws bedrock-agent-runtime invoke-agent \
  --agent-id <agent-id> \
  --agent-alias-id <alias-id> \
  --session-id test-session \
  --input-text "I'd like to order a burger and fries"
```

## Integration with Alexa

The Alexa skill should call the Bedrock Agent using:

```python
import boto3

bedrock_agent = boto3.client('bedrock-agent-runtime')

response = bedrock_agent.invoke_agent(
    agentId='<agent-id>',
    agentAliasId='<alias-id>',
    sessionId=session_id,
    inputText=user_utterance
)
```

## Monitoring

Monitor agent performance through:
- CloudWatch Logs: /aws/bedrock/agents/RestaurantOrderingAgent
- CloudWatch Metrics: Agent invocations, latency, errors
- X-Ray: Distributed tracing of agent execution
