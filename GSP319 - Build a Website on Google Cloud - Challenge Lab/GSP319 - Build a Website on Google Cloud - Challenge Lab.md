# Build a Website on Google Cloud: Challenge Lab

**Lab Code**: `GSP319`  
**Difficulty**: Intermediate  
**Time Limit**: 90 minutes  

---

## Overview

In this challenge lab, you modernize a monolithic e-commerce application (*FancyStore, Inc.*) by containerizing its components and migrating to decoupled microservices running on Google Kubernetes Engine (GKE):
1. **Task 1**: Download the monolithic codebase, run setup, and build the `fancy-monolith` container using Cloud Build.
2. **Task 2**: Provision a 3-node GKE cluster (`e2-medium`), deploy the monolith, and expose it via a LoadBalancer on port 80.
3. **Task 3**: Build and push container images for the extracted **Orders** and **Products** microservices.
4. **Task 4**: Deploy and expose the **Orders** (port 8081 -> 80) and **Products** (port 8082 -> 80) microservices on GKE.
5. **Task 5**: Reconfigure the React frontend `.env` to point to the live LoadBalancer external IPs of Orders and Products, and rebuild the app.
6. **Task 6 & 7**: Containerize the **Frontend** microservice with Cloud Build, deploy it to GKE, and expose it publicly on port 80.

---

## Instructions

### Step 1: Run the Automation Script in Google Cloud Shell

Open **Cloud Shell** and execute the single-command automation:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP319%20-%20Build%20a%20Website%20on%20Google%20Cloud%20-%20Challenge%20Lab/gsp319.sh?ts=$(date +%s)" -o gsp319.sh && chmod +x gsp319.sh && ./gsp319.sh
```

When prompted, enter your assigned lab values (found on your lab page instructions):
- **Zone**: e.g. `us-west1-a`
- **Cluster Name**: e.g. `fancy-prod-368`
- **Monolith Container Name**: e.g. `fancy-monolith-565`
- **Orders Container Name**: e.g. `fancy-orders-111`
- **Products Container Name**: e.g. `fancy-products-358`
- **Frontend Container Name**: e.g. `fancy-frontend-775`

*(Alternatively, you can pre-export the variables to run non-interactively).*

---

### Step 2: Verify Checkpoints

Once the script finishes, return to the lab page and click **Check my progress** on all tasks:
- [x] **Task 1**: Download the monolith code and build your container
- [x] **Task 2**: Create a kubernetes cluster and deploy the application
- [x] **Task 3**: Create a containerized version of orders and product Microservices
- [x] **Task 4**: Deploy the new microservices
- [x] **Task 6**: Create a containerized version of the Frontend microservice
- [x] **Task 7**: Deploy the Frontend microservice

All checkpoints will turn green for a complete score of **100/100**.
