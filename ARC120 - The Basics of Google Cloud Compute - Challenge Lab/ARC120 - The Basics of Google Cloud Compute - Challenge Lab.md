# The Basics of Google Cloud Compute: Challenge Lab

**Lab Code**: `ARC120`  
**Difficulty**: Introductory / Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this challenge lab, you build core infrastructure for a web application:
1. Provision a Cloud Storage bucket in the US multi-region.
2. Create and attach a 200GB persistent disk to an `e2-medium` Compute Engine VM instance.
3. Deploy and verify an NGINX web server serving on port 80.

---

## Instructions

### Step 1: Set Default Zone & Region

In Google Cloud Shell, set your assigned lab zone (replace `us-east1-c` if your lab specified another zone):

```bash
export ZONE="us-east1-c"
```

---

### Step 2: Run the Automation Script

Execute the all-in-one automation script:

```bash
curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab/arc120.sh -o arc120.sh && chmod +x arc120.sh && ./arc120.sh
```

---

### Step 3: Verify Checkpoints

Once the script outputs `ARC120 Execution Completed Successfully!`, click **Check my progress** on all tasks:
- **Task 1**: Create a Cloud Storage bucket
- **Task 2**: Create and attach a persistent disk to an instance
- **Task 3**: Install a NGINX web server
