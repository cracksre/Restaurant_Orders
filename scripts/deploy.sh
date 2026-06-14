#!/bin/bash
# Deployment script for Restaurant Ordering Assistant
# Prerequisites: AWS CLI, Terraform, Python 3.9+

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="restaurant-ordering"
ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
TERRAFORM_BACKEND="${3:-false}"

echo -e "${YELLOW}Restaurant Ordering Assistant Deployment${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"

# Step 1: Validate AWS credentials
echo -e "\n${YELLOW}Step 1: Validating AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}Error: AWS credentials not configured or invalid${NC}"
    exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account: $ACCOUNT_ID${NC}"

# Step 2: Build Lambda deployment packages
echo -e "\n${YELLOW}Step 2: Building Lambda deployment packages...${NC}"

SERVICES=(
    "src/services/alexa-skill-handler"
    "src/services/menu-service"
    "src/services/cart-service"
    "src/services/inventory-service"
    "src/services/upsell-service"
    "src/services/order-service"
    "src/services/pos-webhook"
    "src/services/kds-publisher"
)

for service in "${SERVICES[@]}"; do
    if [ -f "$service/lambda_handler.py" ]; then
        echo "Building $service..."
        cd "$service"
        
        # Create deployment package
        mkdir -p build
        cp lambda_handler.py build/
        
        # Install dependencies if requirements.txt exists
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt -t build/ --quiet
        fi
        
        # Create zip file
        cd build
        zip -r -q ../lambda_deployment.zip .
        cd ..
        
        # Copy to terraform directory
        cp lambda_deployment.zip ../../../terraform/
        
        cd ../../../
        echo -e "${GREEN}✓ Built $service${NC}"
    fi
done

# Create placeholder zip if using initial Terraform apply
if ! [ -f "terraform/lambda_placeholder.zip" ]; then
    echo "Creating placeholder Lambda package..."
    cd terraform
    echo "lambda handler placeholder" > placeholder.txt
    zip -q lambda_placeholder.zip placeholder.txt
    rm placeholder.txt
    cd ..
    echo -e "${GREEN}✓ Created Lambda placeholder${NC}"
fi

# Step 3: Initialize Terraform
echo -e "\n${YELLOW}Step 3: Initializing Terraform...${NC}"
cd terraform

# Configure backend if enabled
if [ "$TERRAFORM_BACKEND" = "true" ]; then
    echo "Configuring remote backend..."
    terraform init \
        -backend-config="bucket=$PROJECT_NAME-tf-state-$ACCOUNT_ID" \
        -backend-config="key=$ENVIRONMENT/terraform.tfstate" \
        -backend-config="region=$AWS_REGION" \
        -backend-config="encrypt=true" \
        -backend-config="dynamodb_table=terraform-locks"
else
    terraform init
fi

echo -e "${GREEN}✓ Terraform initialized${NC}"

# Step 4: Create terraform.tfvars
echo -e "\n${YELLOW}Step 4: Creating terraform.tfvars...${NC}"
cat > terraform.tfvars <<EOF
aws_region                = "$AWS_REGION"
project_name              = "$PROJECT_NAME"
environment               = "$ENVIRONMENT"
lambda_timeout            = 30
lambda_memory             = 256
lambda_ephemeral_storage  = 512
dynamodb_billing_mode     = "PAY_PER_REQUEST"
enable_kms_encryption     = true
enable_xray               = true
enable_cloudtrail         = true
log_retention_days        = 30

tags = {
  Environment = "$ENVIRONMENT"
  Project     = "$PROJECT_NAME"
  ManagedBy   = "Terraform"
}
EOF
echo -e "${GREEN}✓ terraform.tfvars created${NC}"

# Step 5: Validate Terraform
echo -e "\n${YELLOW}Step 5: Validating Terraform configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Terraform configuration valid${NC}"

# Step 6: Plan Terraform deployment
echo -e "\n${YELLOW}Step 6: Planning Terraform deployment...${NC}"
terraform plan -out=tfplan -input=false

# Step 7: Apply Terraform deployment
echo -e "\n${YELLOW}Step 7: Applying Terraform deployment...${NC}"
read -p "Do you want to proceed with the deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

terraform apply tfplan
TERRAFORM_EXIT_CODE=$?

if [ $TERRAFORM_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform deployment completed successfully${NC}"
    
    # Export outputs
    echo -e "\n${YELLOW}Step 8: Exporting deployment outputs...${NC}"
    terraform output -json > deployment-outputs.json
    
    API_ENDPOINT=$(terraform output -raw api_gateway_endpoint 2>/dev/null || echo "Not available yet")
    echo -e "${GREEN}✓ Deployment completed${NC}"
    echo ""
    echo -e "${GREEN}API Gateway Endpoint: $API_ENDPOINT${NC}"
    echo ""
    echo "Deployment outputs saved to: terraform/deployment-outputs.json"
else
    echo -e "${RED}✗ Terraform deployment failed${NC}"
    exit 1
fi

cd ..

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
