# Google Cloud Skills Boost Automation Rules

All scripts and documentation in this repository must adhere to these invariants to guarantee 100/100 lab assessment scores without manual intervention.

### 1. Checkpoint & Resource Lifecycle Invariant
- **Never delete or stop resources prior to assessment checkpoints**: Qwiklabs assessment bots perform point-in-time API validation. If a lab deletes or modifies a resource (e.g., deleting a standalone VM after creating an instance template), this MUST be sequestered into a subsequent script phase (e.g. `gsp<id>_2.sh`).
- **Phase Splitting Standard**:
  - `gsp<id>_1.sh`: Executes up to the first set of assessment checkpoints. Must leave all validated resources active and healthy.
  - User verification pause: User validates green checks.
  - `gsp<id>_2.sh`: Executes downstream tasks (MIG creation, load balancing, resource cleanup, rolling updates).

### 2. Cloud Shell Non-Interactive Execution
- **Never call shell wrappers/functions without existence checks**: Tools like `nvm` are bash shell functions defined only in interactive sessions. Direct calls in non-interactive subshells (`#!/bin/bash`) trigger exit code 127 (`command not found`) and crash scripts under `set -e`.
- **Safe Tool Fallback Pattern**:
  ```bash
  for nvm_path in "$HOME/.nvm/nvm.sh" "/usr/local/nvm/nvm.sh" "/opt/nvm/nvm.sh"; do
    [ -s "$nvm_path" ] && source "$nvm_path" && break
  done
  command -v nvm &>/dev/null && nvm use 22 2>/dev/null || true
  ```
- Rely directly on system-installed tools (`node`, `npm`, `apt-get`) whenever available.

### 3. Fail-Safe Project & Zone Resolution
- Always resolve credentials and regions using multi-tiered fallbacks. Never assume `$ZONE` or `$DEVSHELL_PROJECT_ID` are exported:
  ```bash
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
  [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ] && PROJECT_ID="$DEVSHELL_PROJECT_ID"

  ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
  [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ] && ZONE="<lab-default-zone>"
  REGION="${ZONE%-*}"
  ```

### 4. Modern Google Cloud CLI Standards
- Use `gcloud storage` instead of deprecated `gsutil` (`gcloud storage buckets create`, `gcloud storage cp`).
- Use modern compute health checks: `gcloud compute health-checks create http ...` and `--health-checks=...` (avoid `http-health-checks`).
- Always pass exact image families when specified: `--image-family=debian-12 --image-project=debian-cloud`.

### 5. Repository File Standards
- Folder naming: `GSP<ID> - <Lab Title>/`
- Markdown doc: `GSP<ID> - <Lab Title>.md`
- Script naming: `gsp<id>_1.sh`, `gsp<id>_2.sh` (or `gsp<id>.sh` if single-phase)
- Trailing newline: Strict POSIX LF (`\n`) on all files.
- Indexing: Update root `README.md` catalog table with every new lab.

### 6. Command Precedence & Reference Protocol
- **User-Provided Steps are Mandatory (Primary Source)**: The exact commands, parameters, roles, and instructions provided directly by the user in the prompt take absolute precedence and MUST be followed as the primary source of truth.
- **Dr. Abhishek Repository (Fallback Only)**: Only check the `Itsabhishek7py/GoogleCloudSkillsboost` repository as a secondary reference when stuck, encountering an undocumented blocker, or when critical parameters are missing from the prompt. Never use it to replace or override the user's explicit instructions, and always account for its legacy/outdated CLI syntax.
- **Proactive Screenshot Request**: If command output is ambiguous, terminal execution halts unexpectedly, or the lab assessment fails, proactively ask the user for a screenshot of the Cloud Shell terminal or the lab assessment panel before guessing.
