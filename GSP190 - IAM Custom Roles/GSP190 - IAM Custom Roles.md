# IAM Custom Roles

**Lab Code**: `GSP190`  
**Difficulty**: Introductory  
**Time Limit**: 45 minutes  

---

## Overview

In this lab, you configure, manage, and audit custom IAM roles using the Google Cloud CLI (`gcloud`):
1. Query available testable permissions and grantable roles on resources.
2. Create custom roles using both YAML configuration definitions and command-line flags.
3. Update custom roles by adding and modifying permissions.
4. Disable, delete, and undelete (restore) custom IAM roles enforcing least privilege.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation script:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP190%20-%20IAM%20Custom%20Roles/gsp190.sh?ts=$(date +%s)" -o gsp190.sh && chmod +x gsp190.sh && ./gsp190.sh
```

---

### Step 2: Verify Checkpoints

Once the script outputs `GSP190 Automation Completed Successfully!`, click **Check my progress** on all tasks:
- **Task 4**: Create a custom role using a YAML file
- **Task 4**: Create a custom role using flags
- **Task 6**: Update a custom role using a YAML file
- **Task 6**: Update a custom role using flags
- **Task 7**: Disabling a custom role
- **Task 9**: Undeleting a custom role
