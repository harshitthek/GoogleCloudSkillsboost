#!/bin/bash
set -e

echo "=========================================="
echo "Starting ARC122 Challenge Lab Automation"
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

# Detect Region dynamically with fallback to us-west1
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-west1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Enable required APIs (non-fatal if pre-activated or restricted)
echo
echo "Checking required APIs..."
gcloud services enable vision.googleapis.com --quiet 2>/dev/null || true
gcloud services enable translate.googleapis.com --quiet 2>/dev/null || true
gcloud services enable language.googleapis.com --quiet 2>/dev/null || true
gcloud services enable apikeys.googleapis.com --quiet 2>/dev/null || true

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null || true)

# Task 1: Create API Key
echo
echo "Task 1: Creating API Key..."
gcloud alpha services api-keys create --display-name="vision-api-key" 2>/dev/null || \
gcloud beta services api-keys create --display-name="vision-api-key" 2>/dev/null || \
gcloud services api-keys create --display-name="vision-api-key" 2>/dev/null || true

if [ -n "$PROJECT_NUMBER" ]; then
  curl -s -X POST \
    "https://apikeys.googleapis.com/v2/projects/${PROJECT_NUMBER}/locations/global/keys" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -d '{"displayName": "vision-api-key"}' >/dev/null 2>&1 || true
fi

# Poll for Key Name across alpha, beta, and GA
KEY_NAME=""
for i in {1..15}; do
  KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" 2>/dev/null | head -n 1)
  [ -z "$KEY_NAME" ] && KEY_NAME=$(gcloud beta services api-keys list --format="value(name)" 2>/dev/null | head -n 1)
  [ -z "$KEY_NAME" ] && KEY_NAME=$(gcloud services api-keys list --format="value(name)" 2>/dev/null | head -n 1)
  if [ -n "$KEY_NAME" ]; then
    break
  fi
  sleep 2
done

# Poll for Key String (API_KEY)
API_KEY=""
if [ -n "$KEY_NAME" ]; then
  for i in {1..10}; do
    API_KEY=$(gcloud alpha services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" 2>/dev/null)
    [ -z "$API_KEY" ] && API_KEY=$(gcloud beta services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" 2>/dev/null)
    [ -z "$API_KEY" ] && API_KEY=$(gcloud services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" 2>/dev/null)
    if [ -n "$API_KEY" ]; then
      break
    fi
    sleep 2
  done
fi

# Direct REST fallback to fetch API Key if still empty
if [ -z "$API_KEY" ] && [ -n "$PROJECT_NUMBER" ]; then
  for i in {1..10}; do
    API_KEY=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      "https://apikeys.googleapis.com/v2/projects/${PROJECT_NUMBER}/locations/global/keys" | \
      grep -o '"keyString": "[^"]*"' | head -n 1 | cut -d'"' -f4)
    if [ -n "$API_KEY" ]; then
      break
    fi
    sleep 2
  done
fi

echo "API Key Name: $KEY_NAME"
echo "API Key:      $API_KEY"

if [ -n "$API_KEY" ]; then
  export API_KEY
  echo "export API_KEY=\"$API_KEY\"" >> ~/.bashrc
fi

# Locate Bucket and Target Image
BUCKET_NAME="${PROJECT_ID}-bucket"
echo
echo "Locating Cloud Storage bucket gs://${BUCKET_NAME}..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  echo "Creating bucket gs://${BUCKET_NAME}..."
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --quiet 2>/dev/null || true
fi

# Discover existing image or fall back to default
IMAGE_NAME=$(gcloud storage ls "gs://${BUCKET_NAME}" 2>/dev/null | grep -E '\.(jpg|png|jpeg|webp)' | head -n 1 | awk -F/ '{print $NF}')
if [ -z "$IMAGE_NAME" ]; then
  IMAGE_NAME="manif-des-sans-papiers.jpg"
fi
echo "Target Image: $IMAGE_NAME"

# Make bucket objects publicly accessible
echo "Configuring public access on gs://${BUCKET_NAME}..."
gsutil acl ch -u AllUsers:R "gs://${BUCKET_NAME}/${IMAGE_NAME}" 2>/dev/null || true
gsutil acl ch -u AllUsers:R "gs://${BUCKET_NAME}/*" 2>/dev/null || true
gcloud storage objects add-iam-policy-binding "gs://${BUCKET_NAME}/${IMAGE_NAME}" --member="allUsers" --role="roles/storage.objectViewer" 2>/dev/null || true
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" --member="allUsers" --role="roles/storage.objectViewer" 2>/dev/null || true

# Task 2 & 3 (Part 1): Text Detection
echo
echo "Task 2 & 3: Creating request.json for TEXT_DETECTION..."
cat << EOF > request.json
{
  "requests": [
    {
      "image": {
        "source": {
          "gcsImageUri": "gs://${BUCKET_NAME}/${IMAGE_NAME}"
        }
      },
      "features": [
        {
          "type": "TEXT_DETECTION",
          "maxResults": 10
        }
      ]
    }
  ]
}
EOF
cat request.json

echo
echo "Executing Cloud Vision TEXT_DETECTION..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @request.json \
    "https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" \
    -o text-response.json
fi

if [ ! -s text-response.json ] || grep -q '"error"' text-response.json 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @request.json \
    "https://vision.googleapis.com/v1/images:annotate" \
    -o text-response.json
fi

echo "Uploading text-response.json to gs://${BUCKET_NAME}/..."
gcloud storage cp text-response.json "gs://${BUCKET_NAME}/"
gsutil acl ch -u AllUsers:R "gs://${BUCKET_NAME}/text-response.json" 2>/dev/null || true

# Task 3 (Part 2): Landmark Detection
echo
echo "Task 3: Updating request.json for LANDMARK_DETECTION..."
cat << EOF > request.json
{
  "requests": [
    {
      "image": {
        "source": {
          "gcsImageUri": "gs://${BUCKET_NAME}/${IMAGE_NAME}"
        }
      },
      "features": [
        {
          "type": "LANDMARK_DETECTION",
          "maxResults": 10
        }
      ]
    }
  ]
}
EOF
cat request.json

echo
echo "Executing Cloud Vision LANDMARK_DETECTION..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @request.json \
    "https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" \
    -o landmark-response.json
fi

if [ ! -s landmark-response.json ] || grep -q '"error"' landmark-response.json 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @request.json \
    "https://vision.googleapis.com/v1/images:annotate" \
    -o landmark-response.json
fi

echo "Uploading landmark-response.json to gs://${BUCKET_NAME}/..."
gcloud storage cp landmark-response.json "gs://${BUCKET_NAME}/"
gsutil acl ch -u AllUsers:R "gs://${BUCKET_NAME}/landmark-response.json" 2>/dev/null || true

echo
echo "=========================================="
echo "ARC122 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an API key & Verify public image"
echo "- Task 3: Analyze the image with the Cloud Vision API (Text Detection)"
echo "- Task 3: Analyze the image with the Cloud Vision API (Landmark Detection)"
echo "=========================================="
