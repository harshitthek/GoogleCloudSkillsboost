# Hosting a Web App on Google Cloud Using Compute Engine

Automated execution scripts for Google Cloud Skills Boost lab: **Hosting a Web App on Google Cloud Using Compute Engine**.

## Usage Instructions

### 1. Set Assigned Zone

Run the following in Google Cloud Shell (replace `us-east1-c` with your assigned zone if different):

```bash
export ZONE="us-east1-c"
```

### 2. Run Part 1 (Tasks 1 to 4)

```bash
curl -LO https://raw.githubusercontent.com/harshitthek/fancy-store-gcp/main/part1.sh
chmod +x part1.sh
./part1.sh
```

> **Important**: Once `part1.sh` completes:
> - Click **Check my progress** on **Task 2** (Create a Cloud Storage bucket).
> - Click **Check my progress** on **Task 4** (Deploy instances and configure the network).

### 3. Run Part 2 (Tasks 5 to 8)

After receiving green checks for Task 2 and Task 4, run:

```bash
curl -LO https://raw.githubusercontent.com/harshitthek/fancy-store-gcp/main/part2.sh
chmod +x part2.sh
./part2.sh
```

> **Finish**: Click **Check my progress** on all remaining tasks (Tasks 5, 6, 7, and 8).
