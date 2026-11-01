# Google Cloud Skills Boost Lab Solutions

Automated, reliable solutions and scripts for Google Cloud Skills Boost (Qwiklabs) labs.

---

## Lab Directory

| Lab ID | Lab Name | Solution Guide | Quick Execution Command |
| :--- | :--- | :--- | :--- |
| **GSP662** | [Hosting a Web App on Google Cloud Using Compute Engine](./GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine.md) | [Guide](./GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine.md) | `curl -fsSL https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP662%20-%20Hosting%20a%20Web%20App%20on%20Google%20Cloud%20Using%20Compute%20Engine/gsp662_1.sh -o gsp662_1.sh && chmod +x gsp662_1.sh && ./gsp662_1.sh` |

---

## Repository Structure

Each lab is placed in its own dedicated directory named with its official Lab ID (`GSP###`) and Lab Title:

```text
GoogleCloudSkillsboost/
├── README.md                                                          <- Master catalog indexing all labs
└── GSP<ID> - <Lab Name>/
    ├── GSP<ID> - <Lab Name>.md                                        <- Detailed guide & checkpoints
    ├── gsp<id>_1.sh                                                   <- Phase 1 script (Pre-checkpoint)
    └── gsp<id>_2.sh                                                   <- Phase 2 script (Post-checkpoint)
```

## How to Run Labs

1. Open **Google Cloud Shell** in your active lab session.
2. Find your lab in the table above.
3. Run Phase 1, verify the required checkpoints in your lab console, then run Phase 2 to earn full points.
