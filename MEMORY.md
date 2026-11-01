# Operational Memory & Known Failure Modes

This document captures historical errors, edge cases, and architectural learnings from implementing Google Cloud Skills Boost labs.

---

## 1. Case Study: GSP662 (Compute Engine Web App)

### Failure Mode 1: Premature Instance Deletion
- **Symptom**: Task 4 fails with `Frontend and backend instances not found! Please deploy frontend and backend instances.`
- **Root Cause**: The original community script bundled Task 5 into Part 1, deleting `backend` VM (`gcloud compute instances delete backend`) before the student checked Task 4.
- **Resolution**: Separated into `gsp662_1.sh` (creates and verifies VMs) and `gsp662_2.sh` (creates MIG templates, then safely deletes original VMs).

### Failure Mode 2: Non-Interactive `nvm: command not found`
- **Symptom**: Script halts at line 34 with `./part1.sh: line 34: nvm: command not found` under `set -e`.
- **Root Cause**: `nvm` is an interactive shell function sourced in `~/.bashrc`, which returns early in non-interactive subshells (`[ -z "$PS1" ] && return`).
- **Resolution**: Tested sourcing paths safely and wrapped all `nvm` calls with `command -v nvm &>/dev/null`.

### Failure Mode 3: Legacy Health Check Rejection
- **Symptom**: Load balancer backend services fail creation or validation check in Qwiklabs.
- **Root Cause**: Legacy commands (`gcloud compute http-health-checks`) are deprecated in modern Google Cloud regions and fail the automated rubric.
- **Resolution**: Standardized on modern `gcloud compute health-checks create http` and `--health-checks` flag.

### Failure Mode 4: Permission Bug in Startup Scripts
- **Symptom**: Microservices fail to start on Compute Engine instances; supervisor logs permission errors.
- **Root Cause**: Startup script created user `nodeapp` and chowned `/opt/app` while the application was installed in `/fancy-store`.
- **Resolution**: Updated startup script to `chown -R nodeapp:nodeapp /fancy-store`.

---

## 2. Reusable Lab Script Checklist

Before finalizing any lab script, verify:
- [ ] Are all checkpoint-dependent resources kept alive until verified?
- [ ] Are all `gcloud storage` commands modern (`gcloud storage cp` instead of `gsutil cp`)?
- [ ] Are project ID and zone handled with fallback chains if unset?
- [ ] Does the script run cleanly under `#!/bin/bash` with `set -e` without relying on interactive aliases?
- [ ] Are named ports, health checks, and firewall rules explicitly tagged?
- [ ] Is the lab indexed in root `README.md`?
