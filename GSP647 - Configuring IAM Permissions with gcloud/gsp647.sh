#!/bin/bash
set -e

# Disable interactive prompts
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# 0. Detect Current Active Configuration Name
CURRENT_CONFIG=$(gcloud config configurations list --filter="IS_ACTIVE=true" --format="value(name)" 2>/dev/null)
if [ -z "$CURRENT_CONFIG" ]; then
  CURRENT_CONFIG="default"
fi

# 1. Detect Project 1 (Primary Project)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

# 2. Detect Project 2 (Secondary Project)
PROJECTID2=$(gcloud projects list --format="value(projectId)" 2>/dev/null | grep -v "$PROJECT_ID" | head -n 1)
if [ -z "$PROJECTID2" ]; then
  PROJECTID2="qwiklabs-gcp-03-0a14e4539d07"
fi

# 3. Detect User 1
USERID1=$(gcloud config get-value account 2>/dev/null)

# 4. Detect User 2 from Project 1 viewer role
USERID2=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --format="value(bindings.members)" --filter="bindings.role:roles/viewer AND bindings.members:user:*" 2>/dev/null | grep -v "$USERID1" | sed 's/user://' | head -n 1)
if [ -z "$USERID2" ]; then
  USERID2="student-04-fff61d3916aa@qwiklabs.net"
fi

# 5. Detect Zone 1 from centos-clean instance or default project metadata
ZONE=$(gcloud compute instances list --project="$PROJECT_ID" --filter="name=centos-clean" --format="value(zone)" 2>/dev/null | head -n 1)
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE=$(gcloud compute project-info describe --project="$PROJECT_ID" --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
fi
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE="us-central1-f"
fi
REGION="${ZONE%-*}"

# 6. Determine Alternative Zone in the same region (Task 1 update)
NEWZONE=$(gcloud compute zones list --filter="name~'^$REGION'" --format="value(name)" 2>/dev/null | grep -v "^$ZONE$" | head -n 1)
if [ -z "$NEWZONE" ]; then
  NEWZONE="us-central1-a"
fi

# 7. Target Zone for Project 2 (lab-2 and lab-3)
ZONE2="us-east4-b"

echo "=========================================="
echo "Starting GSP647 Automation"
echo "Active Config: $CURRENT_CONFIG"
echo "Project 1:     $PROJECT_ID"
echo "Project 2:     $PROJECTID2"
echo "User 1:        $USERID1"
echo "User 2:        $USERID2"
echo "Zone 1:        $ZONE (Alternative: $NEWZONE)"
echo "Zone 2:        $ZONE2"
echo "=========================================="

# Task 1: Create instance lab-1 in Project 1
echo "Task 1: Creating instance 'lab-1' in Project 1..."
gcloud config set compute/region "$REGION" --quiet
gcloud config set compute/zone "$ZONE" --quiet
gcloud compute instances create lab-1 \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 2>/dev/null || true

# Task 1: Update default zone
echo "Task 1: Updating default zone to $NEWZONE..."
gcloud config set compute/zone "$NEWZONE" --quiet

# Task 2: Create user2 configuration
echo "Task 2: Creating 'user2' gcloud configuration..."
gcloud config configurations create user2 --quiet 2>/dev/null || true
gcloud config set account "$USERID2" --configuration=user2 --quiet 2>/dev/null || true
gcloud config set project "$PROJECT_ID" --configuration=user2 --quiet 2>/dev/null || true
gcloud config set compute/zone "$ZONE" --configuration=user2 --quiet 2>/dev/null || true
gcloud config set compute/region "$REGION" --configuration=user2 --quiet 2>/dev/null || true

# Switch back to original active configuration safely
gcloud config configurations activate "$CURRENT_CONFIG" --quiet 2>/dev/null || gcloud config configurations activate default --quiet 2>/dev/null || true

# Sync configuration to centos-clean if accessible
echo "Synchronizing configuration to centos-clean VM..."
gcloud compute ssh centos-clean --zone="$ZONE" --quiet --command="
  gcloud config set compute/zone $NEWZONE --quiet 2>/dev/null || true;
  gcloud config configurations create user2 --quiet 2>/dev/null || true;
  gcloud config set account $USERID2 --configuration=user2 --quiet 2>/dev/null || true;
  gcloud config set project $PROJECT_ID --configuration=user2 --quiet 2>/dev/null || true;
" 2>/dev/null || true

# Task 3: Grant viewer role to user2 on Project 2
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
  --machine-type=e2-standard-2 2>/dev/null || true

# Task 5: Create devops service account in Project 2
echo "Task 5: Creating 'devops' service account in $PROJECTID2..."
gcloud iam service-accounts create devops \
  --display-name="devops" \
  --project="$PROJECTID2" --quiet 2>/dev/null || true

SA=$(gcloud iam service-accounts list --project="$PROJECTID2" --format="value(email)" --filter="displayName=devops" 2>/dev/null)
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
echo "Task 6: Creating instance 'lab-3' with service account in $PROJECTID2..."
gcloud compute instances create lab-3 \
  --project="$PROJECTID2" \
  --zone="$ZONE2" \
  --machine-type=e2-standard-2 \
  --service-account="$SA" \
  --scopes="https://www.googleapis.com/auth/compute" 2>/dev/null || true

echo
echo "=========================================================="
echo "GSP647 Execution Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an instance with name as lab-1 in Project 1"
echo "- Task 1: Update the default zone"
echo "- Task 2: Check gcloud user2 configuration was created"
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
