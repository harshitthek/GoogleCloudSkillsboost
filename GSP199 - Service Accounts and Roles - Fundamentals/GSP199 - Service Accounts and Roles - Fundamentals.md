# Service Accounts and Roles: Fundamentals

**Lab Code**: `GSP199`  
**Difficulty**: Introductory  
**Time Limit**: 60 minutes  

---

## Overview

In this lab, you configure Identity and Access Management (IAM) service accounts and roles:
1. Create a custom service account (`my-sa-123`) and assign the `roles/storage.admin` role.
2. Create a programmatic service account (`bigquery-qwiklab`) and assign `roles/bigquery.dataViewer` and `roles/bigquery.user`.
3. Provision an `e2-medium` Compute Engine instance associated with `bigquery-qwiklab`.
4. Execute Python BigQuery client library queries on public datasets authenticated via the service account identity.

---

## Instructions

### Step 1: Set Default Region & Zone

In Google Cloud Shell, set your assigned region and zone (replace if your lab assigned another region):

```bash
gcloud config set compute/region us-east4
gcloud config set compute/zone us-east4-b
```

---

### Step 2: Run the Automation Script

Execute the all-in-one automation script:

```bash
curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals/gsp199.sh -o gsp199.sh && chmod +x gsp199.sh && ./gsp199.sh
```

---

### Step 3: Verify Checkpoints

Once the script outputs `GSP199 Execution Completed Successfully!`, click **Check my progress** on both tasks:
- **Task 1**: Create and Manage Service Accounts
- **Task 2**: Access BigQuery using a Service Account
