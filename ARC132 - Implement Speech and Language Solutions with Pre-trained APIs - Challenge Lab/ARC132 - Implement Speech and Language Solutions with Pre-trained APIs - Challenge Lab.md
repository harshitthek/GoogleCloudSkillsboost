# Implement Speech and Language Solutions with Pre-trained APIs: Challenge Lab

**Lab Code**: `ARC132`  
**Difficulty**: Introductory / Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this challenge lab, you use Google Cloud's pre-trained machine learning APIs to process speech and language:
1. **Task 1**: Generate a Cloud API Key to authenticate API endpoints.
2. **Task 2**: Synthesize speech from text using the **Cloud Text-to-Speech API**, decode base64 audio with Python into an MP3 file (`synthesize-text-audio.mp3`), and upload response files to Cloud Storage.
3. **Task 3**: Perform speech-to-text audio transcription in French using the **Cloud Speech-to-Text API** (`speech_response_fr.json`) and upload files to Cloud Storage.
4. **Task 4**: Translate Japanese text into English using the **Cloud Translation API** (`translation_response.txt`) and upload to Cloud Storage.
5. **Task 5**: Detect the language of a target string using the **Cloud Translation API** (`detection_response.txt`) and upload to Cloud Storage.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC132%20-%20Implement%20Speech%20and%20Language%20Solutions%20with%20Pre-trained%20APIs%20-%20Challenge%20Lab/arc132.sh?ts=$(date +%s)" -o arc132.sh && chmod +x arc132.sh && ./arc132.sh
```

---

### Step 2: Verify Checkpoints

Once the automation finishes and prints `ARC132 Automation Completed Successfully!`, click **Check my progress** on all tasks:
- [x] **Task 1**: Create an API key
- [x] **Task 2**: Create synthetic speech from text using the Text-to-Speech API
- [x] **Task 3**: Create the API request for transcription in French language
- [x] **Task 4**: Translate text with the Cloud Translation API
- [x] **Task 5**: Detect a language with the Cloud Translation API

All checkpoints will turn green for **100/100**.
