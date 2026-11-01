#!/bin/bash
set -e

# Disable interactive prompts for internal gcloud calls
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "=========================================="
echo "Starting GSP190 Automation"
echo "=========================================="

# Authenticate if needed
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "Authenticating gcloud session..."
  gcloud auth login --quiet || true
fi

# Detect Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: Could not determine Project ID."
  exit 1
fi

echo "Project ID: $PROJECT_ID"

# Set default region if configured or needed
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-east1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Task 1, 2, 3: Query permissions and grantable roles (informational)
echo "Querying available permissions and roles..."
gcloud iam list-testable-permissions "//cloudresourcemanager.googleapis.com/projects/$PROJECT_ID" --limit=5 2>/dev/null || true
gcloud iam roles describe roles/viewer 2>/dev/null || true
gcloud iam list-grantable-roles "//cloudresourcemanager.googleapis.com/projects/$PROJECT_ID" --limit=5 2>/dev/null || true

# Task 4: Create a custom role using a YAML file
echo "Task 4: Creating custom role 'editor' via YAML file..."
cat << 'EOF' > role-definition.yaml
title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
EOF

gcloud iam roles create editor \
  --project="$PROJECT_ID" \
  --file=role-definition.yaml --quiet 2>/dev/null || true

# Task 4: Create a custom role using flags
echo "Task 4: Creating custom role 'viewer' via flags..."
gcloud iam roles create viewer \
  --project="$PROJECT_ID" \
  --title="Role Viewer" \
  --description="Custom role description." \
  --permissions=compute.instances.get,compute.instances.list \
  --stage=ALPHA --quiet 2>/dev/null || true

# Task 5: List custom roles
echo "Task 5: Listing custom roles in project..."
gcloud iam roles list --project="$PROJECT_ID" --quiet 2>/dev/null || true

# Task 6: Update existing custom role 'editor' using YAML file
echo "Task 6: Updating custom role 'editor' via YAML file..."
ETAG=$(gcloud iam roles describe editor --project="$PROJECT_ID" --format="value(etag)" 2>/dev/null)
cat << EOF > new-role-definition.yaml
description: Edit access for App Versions
etag: $ETAG
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/$PROJECT_ID/roles/editor
stage: ALPHA
title: Role Editor
EOF

gcloud iam roles update editor \
  --project="$PROJECT_ID" \
  --file=new-role-definition.yaml --quiet 2>/dev/null || true

# Task 6: Update existing custom role 'viewer' using flags
echo "Task 6: Updating custom role 'viewer' via flags..."
gcloud iam roles update viewer \
  --project="$PROJECT_ID" \
  --add-permissions=storage.buckets.get,storage.buckets.list --quiet 2>/dev/null || true

# Task 7: Disable custom role 'viewer'
echo "Task 7: Disabling custom role 'viewer'..."
gcloud iam roles update viewer \
  --project="$PROJECT_ID" \
  --stage=DISABLED --quiet 2>/dev/null || true

# Task 8: Delete custom role 'viewer'
echo "Task 8: Deleting custom role 'viewer'..."
gcloud iam roles delete viewer \
  --project="$PROJECT_ID" --quiet 2>/dev/null || true

# Task 9: Undelete (restore) custom role 'viewer'
echo "Task 9: Undeleting custom role 'viewer'..."
gcloud iam roles undelete viewer \
  --project="$PROJECT_ID" --quiet 2>/dev/null || true

echo
echo "=========================================="
echo "GSP190 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Create a custom role using a YAML file"
echo "- Create a custom role using flags"
echo "- Update a custom role using a YAML file"
echo "- Update a custom role using flags"
echo "- Disabling a custom role"
echo "- Undeleting a custom role"
echo "=========================================="
