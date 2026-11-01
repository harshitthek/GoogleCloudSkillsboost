#!/bin/bash
set -e

# Disable interactive prompts for internal gcloud calls
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "=========================================="
echo "Starting GSP647 Automation"
echo "=========================================="

# Authenticate if needed
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "Authenticating gcloud session..."
  gcloud auth login --quiet || true
fi

# Detect Project 1 and User 1
PROJECTID1=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECTID1" ] || [ "$PROJECTID1" = "(unset)" ]; then
  PROJECTID1=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google" 2>/dev/null)
fi
USERID1=$(gcloud config get-value account 2>/dev/null)

echo "Detected Environment:"
echo "Project ID 1: ${PROJECTID1:-[Not detected]}"
echo "Username 1:   ${USERID1:-[Not detected]}"
echo

# Interactive Prompts for Lab Credentials (NO HARDCODING)
echo "=========================================================="
echo "Please enter details from your Lab Details panel (right side):"
echo "=========================================================="
read -p "Enter Project ID 2 (PROJECTID2): " PROJECTID2
read -p "Enter Username 2 (USERID2): " USERID2
read -p "Enter Zone for Project 2 [default: us-east4-b]: " ZONE2

while [ -z "$PROJECTID2" ]; do
  read -p "Project ID 2 cannot be empty. Enter Project ID 2: " PROJECTID2
done
while [ -z "$USERID2" ]; do
  read -p "Username 2 cannot be empty. Enter Username 2: " USERID2
done
if [ -z "$ZONE2" ]; then
  ZONE2="us-east4-b"
fi

echo
echo "Using Configuration:"
echo "Project 1:  $PROJECTID1"
echo "Project 2:  $PROJECTID2"
echo "Username 1: $USERID1"
echo "Username 2: $USERID2"
echo "Zone 2:     $ZONE2"
echo "=========================================================="
echo

# Determine active configuration
CURRENT_CONFIG=$(gcloud config configurations list --filter="IS_ACTIVE=true" --format="value(name)" 2>/dev/null | head -n 1)
if [ -z "$CURRENT_CONFIG" ]; then
  CURRENT_CONFIG="cloudshell"
fi

# Determine default zone and region for Project 1
ZONE=$(gcloud compute instances list --filter="name=centos-clean" --format="value(zone)" --limit=1 2>/dev/null)
if [ -z "$ZONE" ]; then
  ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
fi
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
fi
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE="us-central1-f"
fi

REGION="${ZONE%-*}"
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
gcloud config set compute/zone "$ZONE" --quiet 2>/dev/null || true

echo "Project 1 Zone:   $ZONE"
echo "Project 1 Region: $REGION"

# Task 1: Create instance lab-1 in Project 1
echo
echo "Task 1: Creating instance 'lab-1' in Project 1..."
gcloud compute instances create lab-1 \
  --project="$PROJECTID1" \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 2>/dev/null || true

# Task 1: Determine alternative zone and update default zone
NEWZONE=$(gcloud compute zones list --filter="name~'^$REGION'" --format="value(name)" 2>/dev/null | grep -v "^$ZONE$" | head -n 1)
if [ -z "$NEWZONE" ]; then
  NEWZONE="us-central1-a"
fi

echo "Task 1: Updating default zone to $NEWZONE..."
gcloud config set compute/zone "$NEWZONE" --quiet

# Check if running on centos-clean or in Cloud Shell
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == *"centos-clean"* ]]; then
  echo "Running directly on centos-clean VM."
  # Task 2: Create user2 configuration
  echo "Task 2: Creating 'user2' gcloud configuration..."
  gcloud config configurations create user2 --quiet 2>/dev/null || true
  gcloud config set project "$PROJECTID1" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config set compute/zone "$ZONE" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config set compute/region "$REGION" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config configurations activate default --quiet 2>/dev/null || true
else
  # Running in Cloud Shell: Configure centos-clean VM via SSH so Task 1 & 2 pass evaluation
  echo "Syncing configurations to centos-clean VM via SSH..."
  for attempt in {1..5}; do
    if gcloud compute ssh centos-clean --zone="$ZONE" --project="$PROJECTID1" --quiet --command="
      gcloud config set compute/zone $NEWZONE --quiet
      gcloud config set compute/region $REGION --quiet
      gcloud config configurations create user2 --quiet 2>/dev/null || true
      gcloud config set project $PROJECTID1 --configuration=user2 --quiet 2>/dev/null || true
      gcloud config set compute/zone $ZONE --configuration=user2 --quiet 2>/dev/null || true
      gcloud config set compute/region $REGION --configuration=user2 --quiet 2>/dev/null || true
      gcloud config configurations activate default --quiet 2>/dev/null || true
    "; then
      echo "Successfully synced configuration to centos-clean!"
      break
    else
      echo "Waiting for SSH keys to propagate to centos-clean (attempt $attempt/5)..."
      sleep 5
    fi
  done

  # Also create user2 configuration locally
  gcloud config configurations create user2 --quiet 2>/dev/null || true
  gcloud config set project "$PROJECTID1" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config set compute/zone "$ZONE" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config set compute/region "$REGION" --configuration=user2 --quiet 2>/dev/null || true
  gcloud config configurations activate "$CURRENT_CONFIG" --quiet 2>/dev/null || true
fi

echo
echo "=========================================================="
echo ">>> CHECKPOINT: Tasks 1 & 2 Configured <<<"
echo "Please click 'Check my progress' on the lab page for:"
echo "  - Task 1: Create an instance with name as lab-1 in Project 1"
echo "  - Task 1: Update the default zone"
echo "  - Task 2: Check gcloud user2 configuration was created"
echo "=========================================================="
read -p "Press [Enter] to continue with Tasks 3 through 6..."

# Task 3: Grant viewer role to user2 on Project 2
echo
echo "Task 3: Granting roles/viewer to $USERID2 on $PROJECTID2..."
gcloud projects add-iam-policy-binding "$PROJECTID2" \
  --member="user:$USERID2" \
  --role="roles/viewer" --quiet

# Task 4: Create custom role 'devops' in Project 2
echo "Task 4: Creating custom 'devops' role in $PROJECTID2..."
gcloud iam roles create devops \
  --project="$PROJECTID2" \
  --permissions="compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount" --quiet 2>/dev/null || true

# Task 4: Bind roles/iam.serviceAccountUser and devops role to user2 on Project 2
echo "Task 4: Assigning roles/iam.serviceAccountUser and devops role to $USERID2..."
gcloud projects add-iam-policy-binding "$PROJECTID2" \
  --member="user:$USERID2" \
  --role="roles/iam.serviceAccountUser" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" \
  --member="user:$USERID2" \
  --role="projects/$PROJECTID2/roles/devops" --quiet

# Task 4: Create instance lab-2 in Project 2
echo "Task 4: Creating instance 'lab-2' in $PROJECTID2 ($ZONE2)..."
gcloud compute instances create lab-2 \
  --project="$PROJECTID2" \
  --zone="$ZONE2" \
  --machine-type=e2-standard-2 --quiet 2>/dev/null || true

# Task 5: Create devops service account in Project 2
echo "Task 5: Creating 'devops' service account in $PROJECTID2..."
gcloud iam service-accounts create devops \
  --display-name="devops" \
  --project="$PROJECTID2" --quiet 2>/dev/null || true

SA=$(gcloud iam service-accounts list --project="$PROJECTID2" --format="value(email)" --filter="displayName=devops" 2>/dev/null)
if [ -z "$SA" ]; then
  SA="devops@${PROJECTID2}.iam.gserviceaccount.com"
fi
echo "Service Account Email: $SA"

# Task 5 & 6: Bind roles to devops service account
echo "Task 5 & 6: Granting roles to service account..."
gcloud projects add-iam-policy-binding "$PROJECTID2" \
  --member="serviceAccount:$SA" \
  --role="roles/iam.serviceAccountUser" --quiet

gcloud projects add-iam-policy-binding "$PROJECTID2" \
  --member="serviceAccount:$SA" \
  --role="roles/compute.instanceAdmin" --quiet

# Task 6: Create instance lab-3 with service account attached in Project 2
echo "Task 6: Creating instance 'lab-3' with service account in $PROJECTID2 ($ZONE2)..."
gcloud compute instances create lab-3 \
  --project="$PROJECTID2" \
  --zone="$ZONE2" \
  --machine-type=e2-standard-2 \
  --service-account="$SA" \
  --scopes="https://www.googleapis.com/auth/compute" --quiet 2>/dev/null || true

echo
echo "=========================================================="
echo "GSP647 Execution Completed Successfully!"
echo "You can now click 'Check my progress' on all remaining tasks:"
echo "- Task 3: Restricting Username 2 to roles/viewer in Project 2"
echo "- Task 4: Create a new role with permissions for the devops team"
echo "- Task 4: Check user2 is bound to project2 and role iam.serviceAccountUser"
echo "- Task 4: Bound Username 2 to devops role"
echo "- Task 4: Create an instance with name as lab-2 in Project 2"
echo "- Task 5: Check the created devops service account"
echo "- Task 5: Check devops service account is bound to iam.serviceAccountUser"
echo "- Task 6: Check devops service account is bound to compute.instanceAdmin"
echo "- Task 6: Check lab-3 has the service account attached"
echo "=========================================================="
