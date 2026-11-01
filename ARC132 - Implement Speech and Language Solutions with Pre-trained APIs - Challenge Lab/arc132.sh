#!/bin/bash
set -e

echo "=========================================="
echo "Starting ARC132 Challenge Lab Automation"
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

# Detect Region dynamically
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-west1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Enable required APIs (non-fatal if pre-activated or restricted)
echo
echo "Checking required APIs..."
gcloud services enable texttospeech.googleapis.com --quiet 2>/dev/null || true
gcloud services enable speech.googleapis.com --quiet 2>/dev/null || true
gcloud services enable translate.googleapis.com --quiet 2>/dev/null || true
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

# Ensure destination Cloud Storage bucket exists
BUCKET_NAME="${PROJECT_ID}-speech"
echo
echo "Verifying Cloud Storage bucket gs://${BUCKET_NAME}..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  echo "Creating bucket gs://${BUCKET_NAME}..."
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --quiet 2>/dev/null || true
fi

# Task 2: Create synthetic speech from text using Text-to-Speech API
echo
echo "Task 2: Synthesizing speech with Text-to-Speech API..."
cat << 'EOF' > synthesize-text.json
{
  "input": {
    "text": "Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16 (the encoding used in WAV files)."
  },
  "voice": {
    "languageCode": "en-gb",
    "name": "en-GB-Standard-A",
    "ssmlGender": "FEMALE"
  },
  "audioConfig": {
    "audioEncoding": "MP3"
  }
}
EOF

if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "X-Goog-Api-Key: ${API_KEY}" \
    -H "Content-Type: application/json; charset=utf-8" \
    --data @synthesize-text.json \
    "https://texttospeech.googleapis.com/v1/text:synthesize" > synthesize-text.txt
fi

if [ ! -s synthesize-text.txt ] || grep -q '"error"' synthesize-text.txt 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data @synthesize-text.json \
    "https://texttospeech.googleapis.com/v1/text:synthesize" > synthesize-text.txt
fi

cat << 'EOF' > tts_decode.py
import argparse
from base64 import decodebytes
import json

def decode_tts_output(input_file, output_file):
    with open(input_file) as input_f:
        response = json.load(input_f)
    audio_data = response['audioContent']
    with open(output_file, "wb") as new_file:
        new_file.write(decodebytes(audio_data.encode('utf-8')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Decode output from Cloud Text-to-Speech")
    parser.add_argument('--input', help='The response from the Text-to-Speech API.', required=True)
    parser.add_argument('--output', help='The name of the audio file to create', required=True)
    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF

python3 tts_decode.py --input "synthesize-text.txt" --output "synthesize-text-audio.mp3"

echo "Uploading Task 2 artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp synthesize-text.txt "gs://${BUCKET_NAME}/"
gcloud storage cp synthesize-text-audio.mp3 "gs://${BUCKET_NAME}/"

# Task 3: Speech-to-Text transcription with Cloud Speech API
echo
echo "Task 3: Performing speech-to-text transcription in French..."
cat << 'EOF' > speech_request.json
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF

if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @speech_request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
    -o speech_response_fr.json
fi

if [ ! -s speech_response_fr.json ] || grep -q '"error"' speech_response_fr.json 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @speech_request.json \
    "https://speech.googleapis.com/v1/speech:recognize" \
    -o speech_response_fr.json
fi

echo "Uploading Task 3 artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp speech_request.json "gs://${BUCKET_NAME}/"
gcloud storage cp speech_response_fr.json "gs://${BUCKET_NAME}/"

# Task 4: Translate text with Cloud Translation API
echo
echo "Task 4: Translating Japanese text into English..."
cat << 'EOF' > translation_request.json
{
  "q": "これは日本語です。",
  "target": "en"
}
EOF

if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @translation_request.json \
    "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" \
    -o translation_response.txt
fi

if [ ! -s translation_response.txt ] || grep -q '"error"' translation_response.txt 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @translation_request.json \
    "https://translation.googleapis.com/language/translate/v2" \
    -o translation_response.txt
fi

echo "Uploading Task 4 artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp translation_response.txt "gs://${BUCKET_NAME}/"

# Task 5: Detect language with Cloud Translation API
echo
echo "Task 5: Detecting language..."
cat << 'EOF' > detect_request.json
{
  "q": "Este%é%japonês."
}
EOF

if [ -n "$API_KEY" ]; then
  curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @detect_request.json \
    "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
    -o detection_response.txt
fi

if [ ! -s detection_response.txt ] || grep -q '"error"' detection_response.txt 2>/dev/null; then
  curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -H "X-Goog-User-Project: ${PROJECT_ID}" \
    --data-binary @detect_request.json \
    "https://translation.googleapis.com/language/translate/v2/detect" \
    -o detection_response.txt
fi

echo "Uploading Task 5 artifacts to gs://${BUCKET_NAME}/..."
gcloud storage cp detection_response.txt "gs://${BUCKET_NAME}/"

# Sync artifacts to legacy VM if present
VM_ZONE=$(gcloud compute instances list --filter="name=(lab-vm OR linux-instance)" --format="csv[no-heading](name,zone)" 2>/dev/null | head -n 1)
if [ -n "$VM_ZONE" ]; then
  VM_NAME=$(echo "$VM_ZONE" | cut -d',' -f1)
  ZONE=$(echo "$VM_ZONE" | cut -d',' -f2)
  echo "Syncing all lab artifacts to VM $VM_NAME in zone $ZONE..."
  gcloud compute scp synthesize-text.json synthesize-text.txt synthesize-text-audio.mp3 \
    speech_request.json speech_response_fr.json \
    translation_request.json translation_response.txt \
    detect_request.json detection_response.txt \
    "${VM_NAME}:~/" --zone="$ZONE" --quiet 2>/dev/null || true
fi

echo
echo "=========================================="
echo "ARC132 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create an API key"
echo "- Task 2: Create synthetic speech from text using Text-to-Speech API"
echo "- Task 3: Create the API request for transcription in French language"
echo "- Task 4: Translate text with the Cloud Translation API"
echo "- Task 5: Detect a language with the Cloud Translation API"
echo "=========================================="
