# Configure Service Accounts and IAM Roles for Google Cloud: Challenge Lab

**Lab Code**: `ARC134`  
**Difficulty**: Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this challenge lab, you apply IAM security and Compute Engine administration practices:
1. Create a dedicated service account (`devops`) using `gcloud`.
2. Grant IAM roles (`roles/iam.serviceAccountUser`, `roles/compute.instanceAdmin`) using CLI policy bindings.
3. Launch a Compute Engine VM instance (`vm-2`) attached to the service account.
4. Define and deploy a custom IAM role at the project level using a YAML file with Cloud SQL permissions.
5. Create a BigQuery-dedicated service account (`bigquery-qwiklab`) with `roles/bigquery.dataViewer` and `roles/bigquery.user`, and query public BigQuery datasets using Python client libraries on a Compute Engine instance (`bigquery-instance`).

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation script:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC134%20-%20Configure%20Service%20Accounts%20and%20IAM%20Roles%20for%20Google%20Cloud%20-%20Challenge%20Lab/arc134.sh?ts=$(date +%s)" -o arc134.sh && chmod +x arc134.sh && ./arc134.sh
```

---

### Step 2: Verify Checkpoints

Once the terminal outputs `ARC134 Automation Completed Successfully!`, click **Check my progress** on all tasks:
- **Task 2**: Create a service account using gcloud CLI
- **Task 3**: Grant IAM permissions to a service account using gcloud CLI
- **Task 4**: Create a compute instance with a service account attached using gcloud
- **Task 5**: Create a custom role using a YAML file
- **Task 6**: Use the client libraries to access BigQuery from a service account
