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
echo "Project ID: $PROJECT_ID"
echo "Zone:       $ZONE"
echo "Region:     $REGION"
echo "=========================================="

# Task 1: Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Task 2: Create Cloud Storage Bucket
gcloud storage buckets create "gs://fancy-store-$PROJECT_ID" 2>/dev/null || true

# Task 3: Clone source repository and setup
if [ ! -d ~/monolith-to-microservices/microservices ]; then
  cd ~
  rm -rf monolith-to-microservices
  git clone https://github.com/googlecodelabs/monolith-to-microservices.git
  cd ~/monolith-to-microservices
  ./setup.sh
fi

# Load nvm safely if present
for nvm_path in "$HOME/.nvm/nvm.sh" "/usr/local/nvm/nvm.sh" "/opt/nvm/nvm.sh" "/usr/share/nvm/init-nvm.sh"; do
  if [ -s "$nvm_path" ]; then
    # shellcheck source=/dev/null
    source "$nvm_path"
    break
  fi
done

if command -v nvm &>/dev/null; then
  nvm install 22 2>/dev/null || true
  nvm use 22 2>/dev/null || true
fi

# Task 4: Create startup script
cat << INNER_EOF > ~/monolith-to-microservices/startup-script.sh
#!/bin/bash
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &

apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc nodejs npm

mkdir -p /fancy-store
gcloud storage cp -r gs://fancy-store-${PROJECT_ID}/monolith-to-microservices/microservices/* /fancy-store/

cd /fancy-store/
npm install

id -u nodeapp &>/dev/null || useradd -m -d /home/nodeapp nodeapp
chown -R nodeapp:nodeapp /fancy-store

cat >/etc/supervisor/conf.d/node-app.conf << 'CONF_EOF'
[program:nodeapp]
directory=/fancy-store
command=npm start
autostart=true
autorestart=true
user=nodeapp
environment=HOME="/home/nodeapp",USER="nodeapp",NODE_ENV="production"
stdout_logfile=syslog
stderr_logfile=syslog
CONF_EOF

supervisorctl reread
supervisorctl update
INNER_EOF

# Upload startup script and initial code
gcloud storage cp ~/monolith-to-microservices/startup-script.sh "gs://fancy-store-$PROJECT_ID/startup-script.sh"

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$PROJECT_ID/"

# Deploy backend instance if not running
if gcloud compute instances describe backend --zone="$ZONE" &>/dev/null; then
  echo "Backend instance already exists in $ZONE."
  STATUS=$(gcloud compute instances describe backend --zone="$ZONE" --format='get(status)')
  if [ "$STATUS" != "RUNNING" ]; then
    echo "Starting existing backend instance..."
    gcloud compute instances start backend --zone="$ZONE"
  fi
else
  echo "Creating backend instance..."
  gcloud compute instances create backend \
    --zone="$ZONE" \
    --machine-type=e2-standard-2 \
    --tags=backend \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --metadata=startup-script-url="https://storage.googleapis.com/fancy-store-$PROJECT_ID/startup-script.sh"
fi

# Fetch backend external IP
BACKEND_ADDRESS=""
while [ -z "$BACKEND_ADDRESS" ]; do
  sleep 3
  BACKEND_ADDRESS=$(gcloud compute instances describe backend --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
done
echo "Backend IP: $BACKEND_ADDRESS"

# Update React frontend config with backend IP
cd ~/monolith-to-microservices/react-app
cat > .env << ENV_EOF
REACT_APP_ORDERS_URL=http://$BACKEND_ADDRESS:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$BACKEND_ADDRESS:8082/api/products
ENV_EOF

npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$PROJECT_ID/"

# Deploy frontend instance if not running
if gcloud compute instances describe frontend --zone="$ZONE" &>/dev/null; then
  echo "Frontend instance already exists in $ZONE."
  STATUS=$(gcloud compute instances describe frontend --zone="$ZONE" --format='get(status)')
  if [ "$STATUS" != "RUNNING" ]; then
    echo "Starting existing frontend instance..."
    gcloud compute instances start frontend --zone="$ZONE"
  fi
else
  echo "Creating frontend instance..."
  gcloud compute instances create frontend \
    --zone="$ZONE" \
    --machine-type=e2-standard-2 \
    --tags=frontend \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --metadata=startup-script-url="https://storage.googleapis.com/fancy-store-$PROJECT_ID/startup-script.sh"
fi

# Create firewall rules
gcloud compute firewall-rules create fw-fe --allow tcp:8080 --target-tags=frontend 2>/dev/null || true
gcloud compute firewall-rules create fw-be --allow tcp:8081-8082 --target-tags=backend 2>/dev/null || true

echo
echo "=========================================================="
echo "Current Instance Status:"
gcloud compute instances list --filter="name=(frontend OR backend)"
echo "=========================================================="
echo "Part 1 completed! Frontend and backend are both deployed."
echo "Click 'Check my progress' for Task 4 now."
echo "=========================================================="
