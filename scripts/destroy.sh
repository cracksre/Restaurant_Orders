#!/bin/bash
# Destroy script for Restaurant Ordering Assistant
# This will tear down all AWS resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT="${1:-dev}"

echo -e "${YELLOW}Restaurant Ordering Assistant - Destroy Resources${NC}"
echo -e "${YELLOW}================================================${NC}"
echo "Environment: $ENVIRONMENT"

read -p "Are you sure you want to destroy all resources in $ENVIRONMENT? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Destroy cancelled"
    exit 0
fi

echo -e "${RED}Destroying Terraform resources...${NC}"

cd terraform

terraform destroy \
    -var-file=terraform.tfvars \
    -input=false \
    -auto-approve

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Resources destroyed successfully${NC}"
else
    echo -e "${RED}✗ Destroy operation failed${NC}"
    exit 1
fi

cd ..

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Destroy Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
