#!/bin/bash
set -e

# Setup Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

# Setup Zone and Region
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
fi

if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE="us-east1-c"
fi

export REGION="${ZONE%-*}"
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo "=========================================="
echo "Running Part 2 with:"
echo "Project ID: $PROJECT_ID"
echo "Zone:       $ZONE"
echo "Region:     $REGION"
echo "=========================================="

# Task 5: Managed Instance Groups
echo "Stopping original instances..."
gcloud compute instances stop frontend --zone="$ZONE" 2>/dev/null || true
gcloud compute instances stop backend --zone="$ZONE" 2>/dev/null || true

echo "Creating instance templates..."
gcloud compute instance-templates create fancy-fe \
  --source-instance-zone="$ZONE" \
  --source-instance=frontend 2>/dev/null || true

gcloud compute instance-templates create fancy-be \
  --source-instance-zone="$ZONE" \
  --source-instance=backend 2>/dev/null || true

echo "Deleting backend instance to free resources..."
gcloud compute instances delete backend --zone="$ZONE" --quiet 2>/dev/null || true

echo "Creating Managed Instance Groups..."
gcloud compute instance-groups managed create fancy-fe-mig \
  --zone="$ZONE" \
  --base-instance-name fancy-fe \
  --size 2 \
  --template fancy-fe 2>/dev/null || true

gcloud compute instance-groups managed create fancy-be-mig \
  --zone="$ZONE" \
  --base-instance-name fancy-be \
  --size 2 \
  --template fancy-be 2>/dev/null || true

gcloud compute instance-groups set-named-ports fancy-fe-mig \
  --zone="$ZONE" \
  --named-ports frontend:8080

gcloud compute instance-groups set-named-ports fancy-be-mig \
  --zone="$ZONE" \
  --named-ports orders:8081,products:8082

echo "Creating autohealing health checks..."
gcloud compute health-checks create http fancy-fe-hc \
  --port 8080 \
  --check-interval 30s \
  --healthy-threshold 1 \
  --timeout 10s \
  --unhealthy-threshold 3 2>/dev/null || true

gcloud compute health-checks create http fancy-be-hc \
  --port 8081 \
  --request-path=/api/orders \
  --check-interval 30s \
  --healthy-threshold 1 \
  --timeout 10s \
  --unhealthy-threshold 3 2>/dev/null || true

gcloud compute firewall-rules create allow-health-check \
  --allow tcp:8080-8081 \
  --source-ranges 130.211.0.0/22,35.191.0.0/16 \
  --network default 2>/dev/null || true

gcloud compute instance-groups managed update fancy-fe-mig \
  --zone="$ZONE" \
  --health-check fancy-fe-hc \
  --initial-delay 300

gcloud compute instance-groups managed update fancy-be-mig \
  --zone="$ZONE" \
  --health-check fancy-be-hc \
  --initial-delay 300

# Task 6: Load Balancer
echo "Setting up Load Balancer..."
gcloud compute health-checks create http fancy-fe-frontend-hc \
  --request-path=/ \
  --port=8080 2>/dev/null || true

gcloud compute health-checks create http fancy-be-orders-hc \
  --request-path=/api/orders \
  --port=8081 2>/dev/null || true

gcloud compute health-checks create http fancy-be-products-hc \
  --request-path=/api/products \
  --port=8082 2>/dev/null || true

gcloud compute backend-services create fancy-fe-frontend \
  --health-checks=fancy-fe-frontend-hc \
  --port-name=frontend \
  --global 2>/dev/null || true

gcloud compute backend-services create fancy-be-orders \
  --health-checks=fancy-be-orders-hc \
  --port-name=orders \
  --global 2>/dev/null || true

gcloud compute backend-services create fancy-be-products \
  --health-checks=fancy-be-products-hc \
  --port-name=products \
  --global 2>/dev/null || true

gcloud compute backend-services add-backend fancy-fe-frontend \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-fe-mig \
  --global 2>/dev/null || true

gcloud compute backend-services add-backend fancy-be-orders \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-be-mig \
  --global 2>/dev/null || true

gcloud compute backend-services add-backend fancy-be-products \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-be-mig \
  --global 2>/dev/null || true

gcloud compute url-maps create fancy-map \
  --default-service fancy-fe-frontend 2>/dev/null || true

gcloud compute url-maps add-path-matcher fancy-map \
  --default-service fancy-fe-frontend \
  --path-matcher-name orders \
  --path-rules "/api/orders=fancy-be-orders,/api/products=fancy-be-products" 2>/dev/null || true

gcloud compute target-http-proxies create fancy-proxy \
  --url-map fancy-map 2>/dev/null || true

gcloud compute forwarding-rules create fancy-http-rule \
  --global \
  --target-http-proxy fancy-proxy \
  --ports 80 2>/dev/null || true

# Retrieve Load Balancer IP and update frontend
echo "Fetching Load Balancer IP..."
LB_IP=""
while [ -z "$LB_IP" ]; do
  sleep 3
  LB_IP=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')
done
echo "Load Balancer IP: $LB_IP"

# Load nvm safely if present
for nvm_path in "$HOME/.nvm/nvm.sh" "/usr/local/nvm/nvm.sh" "/opt/nvm/nvm.sh" "/usr/share/nvm/init-nvm.sh"; do
  if [ -s "$nvm_path" ]; then
    # shellcheck source=/dev/null
    source "$nvm_path"
    break
  fi
done

if command -v nvm &>/dev/null; then
  nvm use 22 2>/dev/null || true
fi

cd ~/monolith-to-microservices/react-app
cat > .env << ENV_EOF
REACT_APP_ORDERS_URL=http://$LB_IP/api/orders
REACT_APP_PRODUCTS_URL=http://$LB_IP/api/products
ENV_EOF

npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$PROJECT_ID/"

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone="$ZONE" \
  --max-unavailable 100%

# Task 7: Autoscaling and CDN
echo "Setting up autoscaling & CDN..."
gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
  --zone="$ZONE" \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60 2>/dev/null || true

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
  --zone="$ZONE" \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60 2>/dev/null || true

gcloud compute backend-services update fancy-fe-frontend \
  --enable-cdn \
  --global 2>/dev/null || true

# Task 8: Update the website
echo "Updating website..."
gcloud compute instances set-machine-type frontend \
  --zone="$ZONE" \
  --machine-type e2-small 2>/dev/null || true

gcloud compute instance-templates create fancy-fe-new \
  --region="$REGION" \
  --source-instance=frontend \
  --source-instance-zone="$ZONE" 2>/dev/null || true

gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone="$ZONE" \
  --version template=fancy-fe-new 2>/dev/null || true

cd ~/monolith-to-microservices/react-app/src/pages/Home
if [ -f index.js.new ]; then
  mv index.js.new index.js
fi

cd ~/monolith-to-microservices/react-app
npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$PROJECT_ID/"

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone="$ZONE" \
  --max-unavailable=100%

echo "=========================================================="
echo "Part 2 completed. Check progress on all remaining tasks:"
echo "- Task 5 (Create managed instance groups)"
echo "- Task 6 (Create HTTP(S) load balancers)"
echo "- Task 6 (Update the frontend instances)"
echo "- Task 7 (Scale Compute Engine)"
echo "- Task 8 (Update the website)"
echo "=========================================================="
