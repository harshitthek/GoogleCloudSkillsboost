#!/bin/bash
set -e

# Disable interactive prompts for internal gcloud calls
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "=========================================="
echo "Starting GSP222 Automation"
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

export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
echo "Project ID: $PROJECT_ID"

# Detect Region with fallback
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-east4"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Task 1: Enable the Text-to-Speech API
echo
echo "Task 1: Enabling Text-to-Speech API..."
gcloud services enable texttospeech.googleapis.com --quiet

# Task 2: Create virtual environment (and ensure python3 dependencies exist)
echo
echo "Task 2: Setting up Python environment..."
sudo apt-get update -y 2>/dev/null || true
sudo apt-get install -y python3-venv virtualenv 2>/dev/null || true
python3 -m venv venv 2>/dev/null || virtualenv -p python3 venv 2>/dev/null || true
[ -f "venv/bin/activate" ] && source venv/bin/activate || true

# Task 3: Create service account tts-qwiklab
echo
echo "Task 3: Creating service account 'tts-qwiklab'..."
gcloud iam service-accounts create tts-qwiklab \
  --display-name="tts-qwiklab" --quiet 2>/dev/null || true

# Task 4: Get list of available voices
echo
echo "Task 4: Querying available voices..."
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json; charset=utf-8" \
  "https://texttospeech.googleapis.com/v1/voices?language_code=en" > /dev/null || true

# Create decode helper script
cat << 'EOF' > tts_decode.py
import argparse
from base64 import decodebytes
import json

def decode_tts_output(input_file, output_file):
    with open(input_file) as input:
        response = json.load(input)
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

# Task 5: Create synthetic speech from text
echo
echo "Task 5: Synthesizing speech from text..."
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

curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > synthesize-text.txt

python3 tts_decode.py --input "synthesize-text.txt" --output "synthesize-text-audio.mp3"

# Task 6: Create synthetic speech from SSML
echo
echo "Task 6: Synthesizing speech from SSML..."
cat << 'EOF' > synthesize-ssml.json
{
  "input": {
    "ssml": "<speak><s><emphasis level=\"moderate\">Cloud Text-to-Speech API</emphasis> allows developers to include natural-sounding <break strength=\"x-weak\"/> synthetic human speech as playable audio in their applications.</s><s>The Text-to-Speech API converts text or <prosody rate=\"slow\">Speech Synthesis Markup Language</prosody> <say-as interpret-as=\"characters\">SSML</say-as> input into audio data like <say-as interpret-as=\"characters\">MP3</say-as> or <sub alias=\"linear sixteen\">LINEAR16</sub> <break strength=\"weak\"/> (the encoding used in <sub alias=\"wave\">WAV</sub> files).</s></speak>"
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

curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-ssml.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
  > synthesize-ssml.txt

python3 tts_decode.py --input "synthesize-ssml.txt" --output "synthesize-ssml-audio.mp3"

# Task 7: Configure audio output and device profiles
echo
echo "Task 7: Synthesizing speech with advanced audioConfig & profiles..."
cat << 'EOF' > synthesize-with-settings.json
{
  "input": {
    "text": "The Text-to-Speech API is ideal for any application that plays audio of human speech to users. It allows you to convert arbitrary strings, words, and sentences into the sound of a person speaking the same things."
  },
  "voice": {
    "languageCode": "en-us",
    "name": "en-GB-Standard-A",
    "ssmlGender": "FEMALE"
  },
  "audioConfig": {
    "speakingRate": 1.15,
    "pitch": -2,
    "audioEncoding": "OGG_OPUS",
    "effectsProfileId": ["headphone-class-device"]
  }
}
EOF

curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d @synthesize-with-settings.json "https://texttospeech.googleapis.com/v1beta1/text:synthesize" \
  > synthesize-with-settings.txt

python3 tts_decode.py --input "synthesize-with-settings.txt" --output "synthesize-with-settings-audio.mp3"

echo
echo "=========================================="
echo "GSP222 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Enable the Text-to-Speech API"
echo "- Task 3: Create a service account"
echo "=========================================="
