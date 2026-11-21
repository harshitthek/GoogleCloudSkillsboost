# Store, Process, and Manage Data on Google Cloud: Challenge Lab

**Lab Code**: `ARC100`  
**Difficulty**: Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this challenge lab, you build an automated serverless thumbnail generation pipeline using Google Cloud Storage, Cloud Pub/Sub, and Cloud Run Functions (2nd generation):
1. **Task 1**: Create a Cloud Storage bucket in `us-east1` to store high-resolution images (`memories-bucket-<PROJECT_ID>`).
2. **Task 2**: Create a Pub/Sub topic (`memories-topic-<SUFFIX>`) to receive post-processing notifications.
3. **Task 3**: Create and deploy a 2nd generation Cloud Run function (`memories-thumbnail-maker`) using Node.js and `sharp` triggered by Cloud Storage object finalization events.
4. **Task 4**: Upload an image to the bucket to trigger the function, generating a resized 64x64 thumbnail and publishing a notification to Pub/Sub.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and run the following command:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC100%20-%20Store%2C%20Process%2C%20and%20Manage%20Data%20on%20Google%20Cloud%20-%20Challenge%20Lab/arc100.sh?ts=$(date +%s)" -o arc100.sh && chmod +x arc100.sh && ./arc100.sh
```

When prompted, enter your assigned Pub/Sub topic name from the lab instructions (e.g. `memories-topic-784`).

*(Alternatively, you can pre-export `TOPIC_NAME="memories-topic-784"` before running).*

---

### Step 2: Verify Checkpoints

Once the script completes and outputs `ARC100 Automation Completed Successfully!`, return to the lab page and click **Check my progress** on all tasks:
- [x] **Task 1**: Create a bucket
- [x] **Task 2**: Create a Pub/Sub topic
- [x] **Task 3**: Create the thumbnail Cloud Run function
- [x] **Task 4**: Verify the thumbnail was successfully created by the Cloud Run function

All checkpoints will turn green for a complete score of **100/100**.
