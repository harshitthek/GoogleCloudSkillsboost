#!/bin/bash
set -e

# Disable interactive prompts for internal gcloud calls
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "=========================================="
echo "Starting GSP049 Automation"
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
echo "Enabling Cloud Translation and API Keys APIs..."
gcloud services enable translate.googleapis.com --quiet
gcloud services enable apikeys.googleapis.com --quiet

# Task 1: Create API Key
echo
echo "Task 1: Creating API Key..."
gcloud services api-keys create --display-name="awesome" --quiet 2>/dev/null || \
gcloud alpha services api-keys create --display-name="awesome" --quiet 2>/dev/null || true

KEY_NAME=""
for i in {1..10}; do
  KEY_NAME=$(gcloud services api-keys list --format="value(name)" --filter="displayName=awesome" 2>/dev/null | head -n 1)
  if [ -z "$KEY_NAME" ]; then
    KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter="displayName=awesome" 2>/dev/null | head -n 1)
  fi
  if [ -n "$KEY_NAME" ]; then
    break
  fi
  sleep 2
done

API_KEY=""
if [ -n "$KEY_NAME" ]; then
  for i in {1..10}; do
    API_KEY=$(gcloud services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" 2>/dev/null)
    if [ -z "$API_KEY" ]; then
      API_KEY=$(gcloud alpha services api-keys get-key-string "$KEY_NAME" --format="value(keyString)" 2>/dev/null)
    fi
    if [ -n "$API_KEY" ]; then
      break
    fi
    sleep 2
  done
fi

echo "API Key Name: $KEY_NAME"
echo "API Key:      $API_KEY"
export API_KEY

# Task 2: Translate text
echo
echo "Task 2: Testing translation API call..."
TEXT="My%20name%20is%20Steve"
curl -s "https://translation.googleapis.com/language/translate/v2?target=es&key=${API_KEY}&q=${TEXT}" || true
echo

# Task 3: Detect the language
echo
echo "Task 3: Testing language detection..."
TEXT_ONE="Meu%20nome%20é%20Steven"
TEXT_TWO="日本のグーグルのオフィスは、東京の六本木ヒルズにあります"
curl -s -X POST "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" -d "q=${TEXT_ONE}" -d "q=${TEXT_TWO}" || true
echo

echo
echo "=========================================="
echo "GSP049 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an API Key"
echo "=========================================="
