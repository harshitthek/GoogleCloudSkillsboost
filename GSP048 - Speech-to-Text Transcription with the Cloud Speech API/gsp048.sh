#!/bin/bash
set -e

echo "=========================================="
echo "Starting GSP048 Automation"
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

gcloud config set project "$PROJECT_ID" --quiet 2>/dev/null || true
echo "Project ID: $PROJECT_ID"

# Detect Region with fallback
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-west1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Enable required APIs
echo
echo "Enabling Speech-to-Text and API Keys APIs..."
gcloud services enable speech.googleapis.com --quiet
gcloud services enable apikeys.googleapis.com --quiet

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null)

# Task 1: Create API Key
echo
echo "Task 1: Creating API Key..."
gcloud alpha services api-keys create --display-name="speech-api-key" 2>/dev/null || \
gcloud beta services api-keys create --display-name="speech-api-key" 2>/dev/null || \
gcloud services api-keys create --display-name="speech-api-key" 2>/dev/null || true

# Direct REST creation fallback
if [ -n "$PROJECT_NUMBER" ]; then
  curl -s -X POST \
    "https://apikeys.googleapis.com/v2/projects/${PROJECT_NUMBER}/locations/global/keys" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -d '{"displayName": "speech-api-key"}' >/dev/null 2>&1 || true
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

# Task 2: Create API request (English)
echo
echo "Task 2: Creating English API request file (request.json)..."
cat << 'EOF' > request.json
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "en-US"
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/brooklyn_bridge.flac"
  }
}
EOF
cat request.json

# Ensure destination Cloud Storage bucket exists
BUCKET_NAME="${PROJECT_ID}-speech"
echo
echo "Verifying Cloud Storage bucket gs://${BUCKET_NAME}..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  echo "Creating bucket gs://${BUCKET_NAME}..."
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --quiet 2>/dev/null || true
fi

# Task 3: Call Speech-to-Text API for English
echo
echo "Task 3: Calling Speech-to-Text API for English..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
else
  curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @request.json "https://speech.googleapis.com/v1/speech:recognize" > result.json
fi

cat result.json
echo

echo "Uploading result.json to gs://${BUCKET_NAME}/result_en.json..."
gcloud storage cp result.json "gs://${BUCKET_NAME}/result_en.json"

# Task 4: Speech-to-Text transcription in French
echo
echo "Task 4: Updating request.json for French audio..."
cat << 'EOF' > request.json
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "fr"
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF
cat request.json

echo
echo "Calling Speech-to-Text API for French..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
else
  curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @request.json "https://speech.googleapis.com/v1/speech:recognize" > result.json
fi

cat result.json
echo

echo "Uploading result.json to gs://${BUCKET_NAME}/result_fr.json..."
gcloud storage cp result.json "gs://${BUCKET_NAME}/result_fr.json"

# Support legacy VM instances if present in older lab environments
ZONE=$(gcloud compute instances list --filter="name=linux-instance" --format="value(zone)" 2>/dev/null | head -n 1)
if [ -n "$ZONE" ]; then
  echo "Syncing artifacts to linux-instance in zone $ZONE..."
  gcloud compute scp request.json result.json "linux-instance:~/" --zone="$ZONE" --quiet 2>/dev/null || true
fi

echo
echo "=========================================="
echo "GSP048 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an API Key"
echo "- Task 2: Create your Speech API request"
echo "- Task 3: Call the Speech API for English language"
echo "- Task 4: Call the Speech API for French language"
echo "=========================================="
