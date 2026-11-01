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

# Task 1: Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Task 2: Create Cloud Storage Bucket
gcloud storage buckets create "gs://fancy-store-$DEVSHELL_PROJECT_ID" || true

# Task 3: Clone source repository and setup Node.js
cd ~
rm -rf monolith-to-microservices
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
nvm use 22

# Task 4: Create startup script
cat << INNER_EOF > ~/monolith-to-microservices/startup-script.sh
#!/bin/bash
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &

apt-get update
apt-get install -yq ca-certificates git build-essential supervisor psmisc nodejs npm

mkdir -p /fancy-store
gcloud storage cp -r gs://fancy-store-${DEVSHELL_PROJECT_ID}/monolith-to-microservices/microservices/* /fancy-store/

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
gcloud storage cp ~/monolith-to-microservices/startup-script.sh "gs://fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh"

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$DEVSHELL_PROJECT_ID/"

# Deploy backend instance
gcloud compute instances create backend \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --tags=backend \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script-url="https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh"

# Fetch backend external IP
BACKEND_ADDRESS=""
while [ -z "$BACKEND_ADDRESS" ]; do
  sleep 3
  BACKEND_ADDRESS=$(gcloud compute instances describe backend --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
done

# Update React frontend config with backend IP
cd ~/monolith-to-microservices/react-app
cat > .env << ENV_EOF
REACT_APP_ORDERS_URL=http://$BACKEND_ADDRESS:8081/api/orders
REACT_APP_PRODUCTS_URL=http://$BACKEND_ADDRESS:8082/api/products
ENV_EOF

npm install && npm run-script build

cd ~
rm -rf ~/monolith-to-microservices/*/node_modules
gcloud storage cp -r ~/monolith-to-microservices "gs://fancy-store-$DEVSHELL_PROJECT_ID/"

# Deploy frontend instance
gcloud compute instances create frontend \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --tags=frontend \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script-url="https://storage.googleapis.com/fancy-store-$DEVSHELL_PROJECT_ID/startup-script.sh"

# Create firewall rules
gcloud compute firewall-rules create fw-fe --allow tcp:8080 --target-tags=frontend || true
gcloud compute firewall-rules create fw-be --allow tcp:8081-8082 --target-tags=backend || true

echo "=========================================================="
echo "Part 1 finished. Frontend and Backend instances are active."
echo "Click 'Check my progress' for Task 2 and Task 4 now."
echo "After verifying Task 4, run part2.sh."
echo "=========================================================="
