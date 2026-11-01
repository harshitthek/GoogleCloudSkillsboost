#!/bin/bash
set -e

# Setup Zone and Region
if [ -z "$ZONE" ]; then
  ZONE=$(gcloud config get compute/zone 2>/dev/null)
fi

if [ -z "$ZONE" ]; then
  echo "Error: ZONE environment variable is not set."
  echo "Please set it before running: export ZONE=us-east1-c"
  exit 1
fi

export REGION="${ZONE%-*}"
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# Task 5: Managed Instance Groups
gcloud compute instances stop frontend --zone="$ZONE"
gcloud compute instances stop backend --zone="$ZONE"

gcloud compute instance-templates create fancy-fe \
  --source-instance-zone="$ZONE" \
  --source-instance=frontend

gcloud compute instance-templates create fancy-be \
  --source-instance-zone="$ZONE" \
  --source-instance=backend

gcloud compute instances delete backend --zone="$ZONE" --quiet

gcloud compute instance-groups managed create fancy-fe-mig \
  --zone="$ZONE" \
  --base-instance-name fancy-fe \
  --size 2 \
  --template fancy-fe

gcloud compute instance-groups managed create fancy-be-mig \
  --zone="$ZONE" \
  --base-instance-name fancy-be \
  --size 2 \
  --template fancy-be

gcloud compute instance-groups set-named-ports fancy-fe-mig \
  --zone="$ZONE" \
  --named-ports frontend:8080

gcloud compute instance-groups set-named-ports fancy-be-mig \
  --zone="$ZONE" \
  --named-ports orders:8081,products:8082

gcloud compute health-checks create http fancy-fe-hc \
  --port 8080 \
  --check-interval 30s \
  --healthy-threshold 1 \
  --timeout 10s \
  --unhealthy-threshold 3

gcloud compute health-checks create http fancy-be-hc \
  --port 8081 \
  --request-path=/api/orders \
  --check-interval 30s \
  --healthy-threshold 1 \
  --timeout 10s \
  --unhealthy-threshold 3

gcloud compute firewall-rules create allow-health-check \
  --allow tcp:8080-8081 \
  --source-ranges 130.211.0.0/22,35.191.0.0/16 \
  --network default || true

gcloud compute instance-groups managed update fancy-fe-mig \
  --zone="$ZONE" \
  --health-check fancy-fe-hc \
  --initial-delay 300

gcloud compute instance-groups managed update fancy-be-mig \
  --zone="$ZONE" \
  --health-check fancy-be-hc \
  --initial-delay 300

# Task 6: Load Balancer
gcloud compute health-checks create http fancy-fe-frontend-hc \
  --request-path=/ \
  --port=8080

gcloud compute health-checks create http fancy-be-orders-hc \
  --request-path=/api/orders \
  --port=8081

gcloud compute health-checks create http fancy-be-products-hc \
  --request-path=/api/products \
  --port=8082

gcloud compute backend-services create fancy-fe-frontend \
  --health-checks=fancy-fe-frontend-hc \
  --port-name=frontend \
  --global

gcloud compute backend-services create fancy-be-orders \
  --health-checks=fancy-be-orders-hc \
  --port-name=orders \
  --global

gcloud compute backend-services create fancy-be-products \
  --health-checks=fancy-be-products-hc \
  --port-name=products \
  --global

gcloud compute backend-services add-backend fancy-fe-frontend \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-fe-mig \
  --global

gcloud compute backend-services add-backend fancy-be-orders \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-be-mig \
  --global

gcloud compute backend-services add-backend fancy-be-products \
  --instance-group-zone="$ZONE" \
  --instance-group fancy-be-mig \
  --global

gcloud compute url-maps create fancy-map \
  --default-service fancy-fe-frontend

gcloud compute url-maps add-path-matcher fancy-map \
  --default-service fancy-fe-frontend \
  --path-matcher-name orders \
  --path-rules "/api/orders=fancy-be-orders,/api/products=fancy-be-products"

gcloud compute target-http-proxies create fancy-proxy \
  --url-map fancy-map

gcloud compute forwarding-rules create fancy-http-rule \
  --global \
  --target-http-proxy fancy-proxy \
  --ports 80

# Retrieve Load Balancer IP and update frontend
LB_IP=""
while [ -z "$LB_IP" ]; do
  sleep 3
  LB_IP=$(gcloud compute forwarding-rules describe fancy-http-rule --global --format='get(IPAddress)')
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 22

cd ~/monolith-to-microservices/react-app
cat > .env << ENV_EOF
REACT_APP_ORDERS_URL=http://$LB_IP/api/orders
REACT_APP_PRODUCTS_URL=http://$LB_IP/api/products
ENV_EOF

npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$DEVSHELL_PROJECT_ID/"

gcloud compute instance-groups managed rolling-action replace fancy-fe-mig \
  --zone="$ZONE" \
  --max-unavailable 100%

# Task 7: Autoscaling and CDN
gcloud compute instance-groups managed set-autoscaling fancy-fe-mig \
  --zone="$ZONE" \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute instance-groups managed set-autoscaling fancy-be-mig \
  --zone="$ZONE" \
  --max-num-replicas 2 \
  --target-load-balancing-utilization 0.60

gcloud compute backend-services update fancy-fe-frontend \
  --enable-cdn \
  --global

# Task 8: Update the website
gcloud compute instances set-machine-type frontend \
  --zone="$ZONE" \
  --machine-type e2-small

gcloud compute instance-templates create fancy-fe-new \
  --region="$REGION" \
  --source-instance=frontend \
  --source-instance-zone="$ZONE"

gcloud compute instance-groups managed rolling-action start-update fancy-fe-mig \
  --zone="$ZONE" \
  --version template=fancy-fe-new

cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js

cd ~/monolith-to-microservices/react-app
npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$DEVSHELL_PROJECT_ID/"

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
