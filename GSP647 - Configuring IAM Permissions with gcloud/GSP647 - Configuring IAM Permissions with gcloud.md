# Configuring IAM Permissions with gcloud

**Lab Code**: `GSP647`  
**Difficulty**: Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this lab, you configure IAM permissions and environment settings across multiple projects and user accounts using the `gcloud` CLI:
1. Configure and update `gcloud` compute region and zone defaults.
2. Initialize and configure multiple named configurations (`user2`).
3. Create and assign standard and custom IAM roles (`roles/viewer`, `roles/iam.serviceAccountUser`, custom `devops` role).
4. Create and manage service accounts, attach them to Compute Engine VM instances, and verify least-privilege access.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Execute the all-in-one automation script directly in **Cloud Shell** as Username 1:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud/gsp647.sh?ts=$(date +%s)" -o gsp647.sh && chmod +x gsp647.sh && ./gsp647.sh
```

---

### Step 2: Verify Checkpoints

Once the terminal outputs `GSP647 Execution Completed Successfully!`, click **Check my progress** on all tasks:
- **Task 1**: Create an instance with name as lab-1 in Project 1
- **Task 1**: Update the default zone
- **Task 2**: Check gcloud user2 configuration was created
- **Task 3**: Restricting Username 2 to roles/viewer in Project 2
- **Task 4**: Create a new role with permissions for the devops team
- **Task 4**: Check user2 is bound to project2 and role iam.serviceAccountUser
- **Task 4**: Bound Username 2 to devops role
- **Task 4**: Create an instance with name as lab-2 in Project 2
- **Task 5**: Check the created devops service account
- **Task 5**: Check devops service account is bound to iam.serviceAccountUser
- **Task 6**: Check devops service account is bound to compute.instanceAdmin
- **Task 6**: Check lab-3 has the service account attached
