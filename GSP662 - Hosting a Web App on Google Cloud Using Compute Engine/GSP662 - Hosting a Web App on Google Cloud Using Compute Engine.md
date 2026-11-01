# Hosting a Web App on Google Cloud Using Compute Engine

**Lab Code**: `GSP662`  
**Difficulty**: Intermediate  
**Time Limit**: 90 minutes  

---

## Overview

In this lab, you deploy and scale the "Fancy Store" e-commerce website on Google Cloud Compute Engine using:
- Standalone Compute Engine instances for frontend and backend microservices
- Cloud Storage bucket for code and startup script distribution
- Instance templates from live source instances
- Managed Instance Groups (MIGs) with autohealing policies
- Global HTTP(S) Load Balancing with path-based URL routing
- Autoscaling based on load balancer utilization
- Cloud CDN caching for static frontend assets
- Zero-downtime rolling replacements and instance template updates

---

## Instructions

### Step 1: Set Default Zone & Region

In Google Cloud Shell, set your assigned lab zone (replace `us-east1-c` if your lab specified another zone):

```bash
export ZONE="us-east1-c"
```

---

### Step 2: Run Phase 1 (Tasks 1 to 4)

Executes API enablement, bucket creation, code setup, startup script generation, backend & frontend VM deployment, and firewall configurations:

```bash
curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/gsp662_1.sh -o gsp662_1.sh && chmod +x gsp662_1.sh && ./gsp662_1.sh
```

> [!IMPORTANT]
> **Checkpoints for Phase 1**:
> Once the script outputs `Part 1 completed! Frontend and backend are both deployed.`, click **Check my progress** on:
> - **Task 2**: Create a Cloud Storage bucket
> - **Task 4**: Deploy instances and configure the network

---

### Step 3: Run Phase 2 (Tasks 5 to 8)

After verifying Task 4, run Phase 2 to create instance templates, MIGs, Load Balancer, Autoscaling, Cloud CDN, and rolling code updates:

```bash
curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/gsp662_2.sh -o gsp662_2.sh && chmod +x gsp662_2.sh && ./gsp662_2.sh
```

> [!TIP]
> **Checkpoints for Phase 2**:
> Once the script prints `Part 2 completed`, click **Check my progress** on:
> - **Task 5**: Create managed instance groups
> - **Task 6**: Create HTTP(S) load balancers
> - **Task 6**: Update the frontend instances
> - **Task 7**: Scale Compute Engine
> - **Task 8**: Update the website
