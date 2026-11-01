# Google Cloud Skills Boost Lab Solutions

Automated, reliable solutions and scripts for Google Cloud Skills Boost (Qwiklabs) labs.

---

## Lab Directory

| Lab ID | Lab Name | Solution Guide | Quick Execution Command |
| :--- | :--- | :--- | :--- |
| **ARC120** | [The Basics of Google Cloud Compute: Challenge Lab](./ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab/ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab.md) | [Guide](./ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab/ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab.md) | `curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/ARC120%20-%20The%20Basics%20of%20Google%20Cloud%20Compute%20-%20Challenge%20Lab/arc120.sh -o arc120.sh && chmod +x arc120.sh && ./arc120.sh` |
| **GSP199** | [Service Accounts and Roles: Fundamentals](./GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals/GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals.md) | [Guide](./GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals/GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals.md) | `curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP199%20-%20Service%20Accounts%20and%20Roles%20-%20Fundamentals/gsp199.sh?ts=$(date +%s)" -o gsp199.sh && chmod +x gsp199.sh && ./gsp199.sh` |
| **GSP647** | [Configuring IAM Permissions with gcloud](./GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud/GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud.md) | [Guide](./GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud/GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud.md) | `curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP647%20-%20Configuring%20IAM%20Permissions%20with%20gcloud/gsp647.sh?ts=$(date +%s)" -o gsp647.sh && chmod +x gsp647.sh && ./gsp647.sh` |
| **GSP662** | [Hosting a Web App on Google Cloud Using Compute Engine](./GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine.md) | [Guide](./GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine.md) | `curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/gsp662_1.sh -o gsp662_1.sh && chmod +x gsp662_1.sh && ./gsp662_1.sh` |

---

## Repository Structure

Each lab is placed in its own dedicated directory named with its official Lab ID (`ARC###` or `GSP###`) and Lab Title:

```text
GoogleCloudSkillsboost/
├── README.md                                                          <- Master catalog indexing all labs
├── GEMINI.md                                                          <- Workspace automation rules
├── MEMORY.md                                                          <- Operational knowledge & case studies
└── <Lab-ID> - <Lab Name>/
    ├── <Lab-ID> - <Lab Name>.md                                       <- Detailed guide & checkpoints
    └── <script(s)>.sh                                                 <- One-click automation scripts
```

## How to Run Labs

1. Open **Google Cloud Shell** in your active lab session.
2. Find your lab in the table above and copy the quick execution command.
3. Observe required checkpoints to ensure 100/100 assessment score.
