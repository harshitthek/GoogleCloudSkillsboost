# Speech-to-Text Transcription with the Cloud Speech API

**Lab Code**: `GSP048`  
**Difficulty**: Introductory  
**Time Limit**: 40 minutes  

---

## Overview

In this lab, you use the Google Cloud Speech-to-Text API to transcribe speech audio files into text across multiple languages:
1. Enable the Cloud Speech-to-Text and API Keys APIs.
2. Generate an API Key to authenticate REST API requests.
3. Construct request configurations with encoding and language parameters (`FLAC`, `en-US`, `fr`).
4. Execute transcription requests against Google Cloud Storage hosted audio files using `curl`.
5. Store transcription results in Google Cloud Storage (`result_en.json`, `result_fr.json`).

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and run the following command:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP048%20-%20Speech-to-Text%20Transcription%20with%20the%20Cloud%20Speech%20API/gsp048.sh?ts=$(date +%s)" -o gsp048.sh && chmod +x gsp048.sh && ./gsp048.sh
```

---

### Step 2: Verify Checkpoints

Once the script completes, click **Check my progress** on all lab objectives:
- [x] **Task 1**: Create an API Key
- [x] **Task 2**: Create your Speech API request
- [x] **Task 3**: Call the Speech API for English language
- [x] **Task 4**: Call the Speech API for French language

You will receive full credit (**100/100**).
