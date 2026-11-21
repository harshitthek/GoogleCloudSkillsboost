#!/bin/bash
set -e

echo "=========================================="
echo "Starting GSP515 Challenge Lab Automation"
echo "Explore Generative AI with the Gemini API"
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

LOCATION="global"
API_ENDPOINT="aiplatform.googleapis.com"
MODEL_ID="gemini-3.8-flash"

echo "Configuration Summary:"
echo "Project ID:   $PROJECT_ID"
echo "Location:     $LOCATION"
echo "API Endpoint: $API_ENDPOINT"
echo "Model ID:     $MODEL_ID"
echo

# Task 1: Enable API and invoke Gemini via curl
echo "Enabling aiplatform.googleapis.com API..."
gcloud services enable aiplatform.googleapis.com --quiet 2>/dev/null || true

echo "Sending curl request to gemini model..."
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:streamGenerateContent" \
  -d '{
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": "Why is the sky blue?"
          }
        ]
      }
    ]
  }'

echo
echo "=========================================="
echo "Task 1 completed successfully!"
echo "Check your progress on Task 1 in the lab page."
echo "=========================================="
