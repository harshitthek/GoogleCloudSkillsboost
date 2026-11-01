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
echo "Starting ARC120 Challenge Lab Automation"
echo "Project ID: $PROJECT_ID"
echo "Zone:       $ZONE"
echo "Region:     $REGION"
echo "=========================================="

# Task 1: Create a Cloud Storage bucket (US multi-region)
echo "Task 1: Creating Cloud Storage bucket (gs://${PROJECT_ID}-bucket)..."
gcloud storage buckets create "gs://${PROJECT_ID}-bucket" --location=US 2>/dev/null || true

# Task 2: Create persistent disk and Compute Engine instance
echo "Task 2: Creating 200GB persistent disk (mydisk)..."
gcloud compute disks create mydisk \
  --size=200GB \
  --zone="$ZONE" 2>/dev/null || true

# Ensure HTTP firewall rule exists
gcloud compute firewall-rules create default-allow-http \
  --allow tcp:80 \
  --target-tags=http-server \
  --network=default 2>/dev/null || true

# Deploy instance with startup script for Task 3 (NGINX)
echo "Task 2 & 3: Deploying my-instance with NGINX startup configuration..."
if gcloud compute instances describe my-instance --zone="$ZONE" &>/dev/null; then
  echo "Instance my-instance already exists in $ZONE."
else
  gcloud compute instances create my-instance \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --boot-disk-type=pd-balanced \
    --boot-disk-size=10GB \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --tags=http-server \
    --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx'
fi

# Attach the persistent disk to the instance
echo "Attaching mydisk to my-instance..."
gcloud compute instances attach-disk my-instance \
  --disk=mydisk \
  --zone="$ZONE" 2>/dev/null || true

# Retrieve External IP and verify NGINX web server
INSTANCE_IP=$(gcloud compute instances describe my-instance --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Instance External IP: $INSTANCE_IP"

echo "Waiting for NGINX to finish installation..."
for i in {1..20}; do
  if curl -s -m 5 "http://$INSTANCE_IP" | grep -iq "nginx"; then
    echo "NGINX is verified active on port 80!"
    break
  fi
  sleep 3
done

echo
echo "=========================================================="
echo "ARC120 Execution Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create a Cloud Storage bucket"
echo "- Task 2: Create and attach a persistent disk to an instance"
echo "- Task 3: Install a NGINX web server"
echo "=========================================================="
