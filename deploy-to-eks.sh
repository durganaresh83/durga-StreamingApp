#!/bin/bash
# Quick deployment script for Durga Streaming App on EKS

set -e

NAMESPACE="durga-streaming"
CHART_PATH="./helm/durga-streaming"
RELEASE_NAME="durga-streaming"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DURGA STREAMING APP - EKS DEPLOYMENT${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
for cmd in kubectl helm aws; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}❌ $cmd is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $cmd found${NC}"
done

echo ""
echo -e "${YELLOW}Create/Update Secrets (if not already created)${NC}"
echo -e "${BLUE}Note: Ensure the following secrets exist in the namespace:${NC}"
echo "  • mongodb-secret"
echo "  • app-secrets"
echo ""

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace '$NAMESPACE' ready${NC}"

echo ""
echo -e "${YELLOW}Deploying application with Helm...${NC}"
helm upgrade --install $RELEASE_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --values $CHART_PATH/values.yaml \
  --wait \
  --timeout 10m

echo ""
echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  -l app in (auth-service,streaming-service,admin-service,chat-service,frontend) \
  -n $NAMESPACE \
  --timeout=300s || true

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Pod Status:${NC}"
kubectl get pods -n $NAMESPACE

echo ""
echo -e "${YELLOW}Service Status:${NC}"
kubectl get svc -n $NAMESPACE

echo ""
echo -e "${YELLOW}Ingress Status:${NC}"
kubectl get ingress -n $NAMESPACE

echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View logs:      kubectl logs -n $NAMESPACE -l app=<service-name> -f"
echo "  Port forward:   kubectl port-forward -n $NAMESPACE svc/frontend 3000:80"
echo "  Check resources: kubectl top pods -n $NAMESPACE"
echo "  Update deploy:  helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE"
echo "  Rollback:       helm rollback $RELEASE_NAME -n $NAMESPACE"
echo ""
