#!/bin/bash
set -e

echo "=========================================="
echo "Starting ARC131 Challenge Lab Automation"
echo "Speech-to-Text in Multiple Languages"
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

# Detect Region dynamically with fallback
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-west1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Enable required APIs (non-fatal if pre-activated or restricted)
echo
echo "Checking required APIs..."
gcloud services enable speech.googleapis.com --quiet 2>/dev/null || true
gcloud services enable apikeys.googleapis.com --quiet 2>/dev/null || true

# Get project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null || true)

# Task 1: Create API Key
echo
echo "Task 1: Creating API Key..."
gcloud alpha services api-keys create --display-name="speech-api-key" 2>/dev/null || \
gcloud beta services api-keys create --display-name="speech-api-key" 2>/dev/null || \
gcloud services api-keys create --display-name="speech-api-key" 2>/dev/null || true

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

# Locate Bucket
BUCKET_NAME="${PROJECT_ID}-speech"
echo
echo "Locating Cloud Storage bucket gs://${BUCKET_NAME}..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  echo "Creating bucket gs://${BUCKET_NAME}..."
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --quiet 2>/dev/null || true
fi

# Task 2: Transcribe speech to English text
echo
echo "Task 2: Creating English request payload (speech_request.json)..."
cat << 'EOF' > speech_request.json
{
  "config": {
    "encoding": "LINEAR16",
    "languageCode": "en-US",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://spls/arc131/question_en.wav"
  }
}
EOF
cat speech_request.json

echo
echo "Executing Speech-to-Text for English..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @speech_request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > response.json
fi

if [ ! -s response.json ] || grep -q '"error"' response.json 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @speech_request.json \
    "https://speech.googleapis.com/v1/speech:recognize" > response.json
fi

cat response.json
echo

echo "Uploading English artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp speech_request.json "gs://${BUCKET_NAME}/speech_request.json"
gcloud storage cp speech_request.json "gs://${BUCKET_NAME}/speech_request_en.json" 2>/dev/null || true
gcloud storage cp response.json "gs://${BUCKET_NAME}/response.json"

# Task 3: Transcribe speech to Spanish text
echo
echo "Task 3: Creating Spanish request payload (speech_request_sp.json)..."
cat << 'EOF' > speech_request_sp.json
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "es-ES"
  },
  "audio": {
    "uri": "gs://spls/arc131/multi_es.flac"
  }
}
EOF
cat speech_request_sp.json

echo
echo "Executing Speech-to-Text for Spanish..."
if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @speech_request_sp.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > speech_response_sp.json
fi

if [ ! -s speech_response_sp.json ] || grep -q '"error"' speech_response_sp.json 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @speech_request_sp.json \
    "https://speech.googleapis.com/v1/speech:recognize" > speech_response_sp.json
fi

cat speech_response_sp.json
echo

echo "Uploading Spanish artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp speech_request_sp.json "gs://${BUCKET_NAME}/speech_request_sp.json"
gcloud storage cp speech_response_sp.json "gs://${BUCKET_NAME}/speech_response_sp.json"

# Support legacy VM instances if present in older lab variants
VM_ZONE=$(gcloud compute instances list --filter="name=(lab-vm OR linux-instance)" --format="csv[no-heading](name,zone)" 2>/dev/null | head -n 1)
if [ -n "$VM_ZONE" ]; then
  VM_NAME=$(echo "$VM_ZONE" | cut -d',' -f1)
  ZONE=$(echo "$VM_ZONE" | cut -d',' -f2)
  echo "Syncing all lab artifacts to VM $VM_NAME in zone $ZONE..."
  gcloud compute scp speech_request.json response.json speech_request_sp.json speech_response_sp.json \
    "${VM_NAME}:~/" --zone="$ZONE" --quiet 2>/dev/null || true
fi

echo
echo "=========================================="
echo "ARC131 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an API key"
echo "- Task 2: Create API request for transcription in English language"
echo "- Task 3: Create API request for transcription in Spanish language"
echo "=========================================="
