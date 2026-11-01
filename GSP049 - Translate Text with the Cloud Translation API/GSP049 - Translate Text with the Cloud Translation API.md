# Translate Text with the Cloud Translation API

**Lab Code**: `GSP049`  
**Difficulty**: Introductory  
**Time Limit**: 40 minutes  

---

## Overview

In this lab, you use the Google Cloud Translation API to translate texts and detect languages:
1. Enable the Cloud Translation API and API Keys API.
2. Generate an API Key via the Google Cloud CLI (`gcloud`).
3. Make REST API requests using `curl` to translate English text into Spanish.
4. Detect source languages of multi-language strings (Portuguese, Japanese).

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation script:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP049%20-%20Translate%20Text%20with%20the%20Cloud%20Translation%20API/gsp049.sh?ts=$(date +%s)" -o gsp049.sh && chmod +x gsp049.sh && ./gsp049.sh
```

---

### Step 2: Verify Checkpoints

Once the terminal outputs `GSP049 Automation Completed Successfully!`, click **Check my progress** on:
- **Task 1**: Create an API Key

The task will turn green for **100/100**!
