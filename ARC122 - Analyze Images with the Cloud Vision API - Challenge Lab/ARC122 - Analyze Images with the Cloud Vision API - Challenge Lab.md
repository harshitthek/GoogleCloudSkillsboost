# Analyze Images with the Cloud Vision API: Challenge Lab

**Lab Code**: `ARC122`  
**Difficulty**: Introductory / Intermediate  
**Time Limit**: 45 minutes  

---

## Overview

In this challenge lab, you use the Google Cloud Vision API to analyze image data for optical character recognition (OCR) and landmark identification:
1. **Task 1**: Generate a Cloud API Key and ensure images inside the project's Cloud Storage bucket (`<PROJECT_ID>-bucket`) are publicly accessible (`allUsers`).
2. **Task 2**: Create a JSON request configuration pointing to the target image in Cloud Storage (`request.json`).
3. **Task 3**: Call the Cloud Vision API for `TEXT_DETECTION` (`text-response.json`) and `LANDMARK_DETECTION` (`landmark-response.json`), uploading all response files back to Cloud Storage for verification.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and run the following command:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC122%20-%20Analyze%20Images%20with%20the%20Cloud%20Vision%20API%20-%20Challenge%20Lab/arc122.sh?ts=$(date +%s)" -o arc122.sh && chmod +x arc122.sh && ./arc122.sh
```

---

### Step 2: Verify Checkpoints

Once the script completes, return to the lab page and click **Check my progress** on all tasks:
- [x] **Task 1**: Create an API key
- [x] **Task 3**: Analyze the image with the Cloud Vision API (Text Detection)
- [x] **Task 3**: Analyze the image with the Cloud Vision API (Landmark Detection)

All tasks will turn green for a complete score of **100/100**.
