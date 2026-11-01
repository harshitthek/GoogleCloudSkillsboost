# It Speaks! Create Synthetic Speech Using Text-to-Speech

**Lab Code**: `GSP222`  
**Difficulty**: Introductory  
**Time Limit**: 60 minutes  

---

## Overview

In this lab, you configure and explore the Google Cloud Text-to-Speech API:
1. Enable the Cloud Text-to-Speech API.
2. Create and configure a dedicated service account (`tts-qwiklab`).
3. Query and inspect available voices and language codes.
4. Synthesize speech from standard plain text and decode base64 audio into an MP3 file.
5. Synthesize speech using Speech Synthesis Markup Language (SSML) to customize pitch, rate, pauses, and pronunciation.
6. Customize audio outputs with advanced profiles (`effectsProfileId`, `speakingRate`, `pitch`, `OGG_OPUS`).

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation script:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP222%20-%20It%20Speaks%21%20Create%20Synthetic%20Speech%20Using%20Text-to-Speech/gsp222.sh?ts=$(date +%s)" -o gsp222.sh && chmod +x gsp222.sh && ./gsp222.sh
```

---

### Step 2: Verify Checkpoints

Once the terminal outputs `GSP222 Automation Completed Successfully!`, click **Check my progress** on all tasks:
- **Task 1**: Enable the Text-to-Speech API
- **Task 3**: Create a service account
