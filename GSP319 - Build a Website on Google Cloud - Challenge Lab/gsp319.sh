#!/bin/bash
set -e

echo "=========================================="
echo "Starting GSP319 Challenge Lab Automation"
echo "Monolith to Microservices on GKE"
echo "=========================================="

# Authenticate if needed
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "Authenticating gcloud session..."
  gcloud auth login --quiet || true
fi

# Detect Project ID dynamically
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: Could not determine Project ID."
  exit 1
fi

gcloud config set project "$PROJECT_ID" --quiet 2>/dev/null || true
echo "Project ID: $PROJECT_ID"

# Prompt interactively for dynamic lab-specific parameters if not pre-set
if [ -z "$ZONE" ]; then
  read -p "Enter your assigned zone (e.g., us-west1-a): " ZONE
fi
if [ -z "$CLUSTER" ]; then
  read -p "Enter cluster name (e.g., fancy-prod-368): " CLUSTER
fi
if [ -z "$MON_IDENT" ]; then
  read -p "Enter monolith image/container name (e.g., fancy-monolith-565): " MON_IDENT
fi
if [ -z "$ORD_IDENT" ]; then
  read -p "Enter orders service image/container name (e.g., fancy-orders-111): " ORD_IDENT
fi
if [ -z "$PROD_IDENT" ]; then
  read -p "Enter products service image/container name (e.g., fancy-products-358): " PROD_IDENT
fi
if [ -z "$FRONT_IDENT" ]; then
  read -p "Enter frontend service image/container name (e.g., fancy-frontend-775): " FRONT_IDENT
fi

# Validate inputs
if [ -z "$ZONE" ] || [ -z "$CLUSTER" ] || [ -z "$MON_IDENT" ] || [ -z "$ORD_IDENT" ] || [ -z "$PROD_IDENT" ] || [ -z "$FRONT_IDENT" ]; then
  echo "Error: All configuration parameters (ZONE, CLUSTER, MON_IDENT, ORD_IDENT, PROD_IDENT, FRONT_IDENT) are required."
  exit 1
fi

echo
echo "Configuration Summary:"
echo "Zone:     $ZONE"
echo "Cluster:  $CLUSTER"
echo "Monolith: $MON_IDENT"
echo "Orders:   $ORD_IDENT"
echo "Products: $PROD_IDENT"
echo "Frontend: $FRONT_IDENT"
echo

# Set default compute zone and region
REGION=$(echo "$ZONE" | sed 's/-[a-z]$//')
gcloud config set compute/zone "$ZONE" --quiet 2>/dev/null || true
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true

# Enable required APIs (non-fatal if pre-activated or restricted)
echo "Enabling Cloud Build and Container APIs..."
gcloud services enable cloudbuild.googleapis.com --quiet 2>/dev/null || true
gcloud services enable container.googleapis.com --quiet 2>/dev/null || true

# Clone team repository if needed
echo
echo "Setting up repository..."
cd ~
if [ ! -d "monolith-to-microservices" ]; then
  git clone https://github.com/googlecodelabs/monolith-to-microservices.git
fi
cd ~/monolith-to-microservices
./setup.sh

# Safe non-interactive NVM check
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" || true
[ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh" || true
if command -v nvm &>/dev/null; then
  nvm install 22 || true
  nvm use 22 || true
fi

# Task 1: Build monolith container
echo
echo "Task 1: Building and pushing Monolith container (${MON_IDENT}:1.0.0)..."
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${MON_IDENT}:1.0.0" .

# Task 2: Create GKE cluster and deploy Monolith
echo
echo "Task 2: Creating GKE cluster ($CLUSTER)..."
if ! gcloud container clusters list --filter="name=$CLUSTER" --format="value(name)" 2>/dev/null | grep -q "$CLUSTER"; then
  gcloud container clusters create "$CLUSTER" \
    --zone "$ZONE" \
    --num-nodes 3 \
    --machine-type e2-medium \
    --quiet
fi

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --quiet

echo "Deploying Monolith on GKE..."
if ! kubectl get deployment "$MON_IDENT" &>/dev/null; then
  kubectl create deployment "$MON_IDENT" --image="gcr.io/${PROJECT_ID}/${MON_IDENT}:1.0.0"
fi

if ! kubectl get svc "$MON_IDENT" &>/dev/null; then
  kubectl expose deployment "$MON_IDENT" --type=LoadBalancer --port 80 --target-port 8080
fi

# Task 3: Create Orders and Products microservices
echo
echo "Task 3: Building Orders container (${ORD_IDENT}:1.0.0)..."
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${ORD_IDENT}:1.0.0" .

echo "Building Products container (${PROD_IDENT}:1.0.0)..."
cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${PROD_IDENT}:1.0.0" .

# Task 4: Deploy Orders and Products microservices
echo
echo "Task 4: Deploying Orders and Products microservices..."
if ! kubectl get deployment "$ORD_IDENT" &>/dev/null; then
  kubectl create deployment "$ORD_IDENT" --image="gcr.io/${PROJECT_ID}/${ORD_IDENT}:1.0.0"
fi
if ! kubectl get svc "$ORD_IDENT" &>/dev/null; then
  kubectl expose deployment "$ORD_IDENT" --type=LoadBalancer --port 80 --target-port 8081
fi

if ! kubectl get deployment "$PROD_IDENT" &>/dev/null; then
  kubectl create deployment "$PROD_IDENT" --image="gcr.io/${PROJECT_ID}/${PROD_IDENT}:1.0.0"
fi
if ! kubectl get svc "$PROD_IDENT" &>/dev/null; then
  kubectl expose deployment "$PROD_IDENT" --type=LoadBalancer --port 80 --target-port 8082
fi

# Task 5: Configure Frontend with Orders and Products external IPs
echo
echo "Task 5: Waiting for Orders and Products LoadBalancer external IPs..."
ORDERS_IP=""
for i in {1..40}; do
  ORDERS_IP=$(kubectl get svc "$ORD_IDENT" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ -n "$ORDERS_IP" ]; then
    break
  fi
  echo "Waiting for Orders LoadBalancer IP... ($i/40)"
  sleep 5
done

PRODUCTS_IP=""
for i in {1..40}; do
  PRODUCTS_IP=$(kubectl get svc "$PROD_IDENT" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [ -n "$PRODUCTS_IP" ]; then
    break
  fi
  echo "Waiting for Products LoadBalancer IP... ($i/40)"
  sleep 5
done

echo "Orders External IP:   $ORDERS_IP"
echo "Products External IP: $PRODUCTS_IP"

echo "Reconfiguring Frontend .env..."
cd ~/monolith-to-microservices/react-app
cat << EOF > .env
REACT_APP_ORDERS_URL=http://${ORDERS_IP}/api/orders
REACT_APP_PRODUCTS_URL=http://${PRODUCTS_IP}/api/products
EOF

echo "Rebuilding Frontend app..."
npm run build || true

# Task 6 & 7: Build and deploy Frontend microservice
echo
echo "Task 6: Building Frontend container (${FRONT_IDENT}:1.0.0)..."
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${FRONT_IDENT}:1.0.0" .

echo
echo "Task 7: Deploying Frontend microservice..."
if ! kubectl get deployment "$FRONT_IDENT" &>/dev/null; then
  kubectl create deployment "$FRONT_IDENT" --image="gcr.io/${PROJECT_ID}/${FRONT_IDENT}:1.0.0"
fi
if ! kubectl get svc "$FRONT_IDENT" &>/dev/null; then
  kubectl expose deployment "$FRONT_IDENT" --type=LoadBalancer --port 80 --target-port 8080
fi

echo
echo "=========================================="
echo "GSP319 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Download the monolith code and build your container"
echo "- Task 2: Create a kubernetes cluster and deploy the application"
echo "- Task 3: Create a containerized version of orders and product Microservices"
echo "- Task 4: Deploy the new microservices"
echo "- Task 6: Create a containerized version of the Frontend microservice"
echo "- Task 7: Deploy the Frontend microservice"
echo "=========================================="
