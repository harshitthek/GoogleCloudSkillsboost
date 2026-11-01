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

## 2. Case Study: GSP199 (Service Accounts and Roles)

### Failure Mode 5: Comma Splitting in Inline `--metadata`
- **Symptom**: `ERROR: (gcloud.compute.instances.create) Invalid value for field 'resource.metadata.items[0].key'`
- **Root Cause**: Inline `--metadata=startup-script="..."` treats commas as key-value separators (`KEY=VAL,KEY2=VAL2`). Python/SQL code containing commas (e.g., in function arguments or queries) causes `gcloud` to parse subsequent tokens as malformed metadata keys.
- **Resolution**: Always write the script to a file and pass it with `--metadata-from-file=startup-script=/path/to/script.sh`.

### Failure Mode 6: GitHub Raw CDN 5-Minute Cache Delay
- **Symptom**: Re-running `curl -fsSL https://raw.githubusercontent.com/...` immediately after pushing a fix re-executes the old script.
- **Root Cause**: `raw.githubusercontent.com` uses Fastly CDN caching with `Cache-Control: max-age=300` (5 minutes).
- **Resolution**: Append a dynamic cache-buster query parameter (e.g., `?ts=$(date +%s)`) or pass `-H "Cache-Control: no-cache"` to guarantee fetching the newest commit.

---

## 3. Reusable Lab Script Checklist

Before finalizing any lab script, verify:
- [ ] Are all checkpoint-dependent resources kept alive until verified?
- [ ] Are all `gcloud storage` commands modern (`gcloud storage cp` instead of `gsutil cp`)?
- [ ] Are project ID and zone handled with fallback chains if unset?
- [ ] Are multiline startup scripts passed via `--metadata-from-file` instead of inline `--metadata`?
- [ ] Does the script run cleanly under `#!/bin/bash` with `set -e` without relying on interactive aliases?
- [ ] Are named ports, health checks, and firewall rules explicitly tagged?
- [ ] Is the lab indexed in root `README.md`?

---

## 4. Reference Handling & Diagnostic Guidelines
- **User-Provided Ground Truth**: Always build scripts strictly according to the user's provided commands and lab text first.
- **External Legacy Repositories (Fallback Only)**: The Dr. Abhishek repo is strictly a fallback for troubleshooting when stuck. Never prioritize it over prompt-supplied steps.
- **Diagnostic Visuals**: Requesting an immediate screenshot of Cloud Shell terminal output when a failure occurs eliminates guesswork, exposing hidden subshell errors and regional quota limits instantly.
