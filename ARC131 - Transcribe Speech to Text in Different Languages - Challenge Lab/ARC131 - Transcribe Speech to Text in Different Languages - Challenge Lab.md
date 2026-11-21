# Transcribe Speech to Text in Different Languages: Challenge Lab

**Lab Code**: `ARC131`  
**Difficulty**: Introductory / Intermediate  
**Time Limit**: 45 minutes  

---

## Overview

In this challenge lab, you use the Google Cloud Speech-to-Text API to perform audio transcription across multiple languages and encoding formats:
1. **Task 1**: Generate a Cloud API Key to authenticate REST API requests.
2. **Task 2**: Transcribe multi-channel English stereo WAV audio (`question_en.wav`) using `LINEAR16` encoding (`audioChannelCount: 2`) and upload `speech_request.json` & `response.json` to Cloud Storage.
3. **Task 3**: Transcribe Spanish audio (`multi_es.flac`) using `FLAC` encoding (`es-ES`) and upload `speech_request_sp.json` & `speech_response_sp.json` to Cloud Storage.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and run the following command:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC131%20-%20Transcribe%20Speech%20to%20Text%20in%20Different%20Languages%20-%20Challenge%20Lab/arc131.sh?ts=$(date +%s)" -o arc131.sh && chmod +x arc131.sh && ./arc131.sh
```

---

### Step 2: Verify Checkpoints

Once the script completes, return to the lab page and click **Check my progress** on all tasks:
- [x] **Task 1**: Create an API key
- [x] **Task 2**: Create API request for transcription in English language
- [x] **Task 3**: Create API request for transcription in Spanish language

All checkpoints will turn green for a complete score of **100/100**.
