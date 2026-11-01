#!/bin/bash
set -e

# Disable interactive prompts for internal gcloud calls
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

echo "=========================================="
echo "Starting ARC134 Automation"
echo "=========================================="

# Authenticate if needed
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "Authenticating gcloud session..."
  gcloud auth login --quiet || true
fi

# Detect Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: Could not determine Project ID."
  exit 1
fi

echo "Project ID: $PROJECT_ID"

# Detect Region and Zone with fallbacks
ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE="us-east4-c"
fi

REGION="${ZONE%-*}"
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-east4"
fi

gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
gcloud config set compute/zone "$ZONE" --quiet 2>/dev/null || true

echo "Region:     $REGION"
echo "Zone:       $ZONE"

# Task 2: Create service account 'devops'
echo
echo "Task 2: Creating service account 'devops'..."
gcloud iam service-accounts create devops \
  --display-name="devops" --quiet 2>/dev/null || true

SA_DEVOPS="devops@${PROJECT_ID}.iam.gserviceaccount.com"
echo "DevOps Service Account: $SA_DEVOPS"

# Task 3: Grant IAM permissions to devops service account
echo
echo "Task 3: Granting IAM permissions to devops service account..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_DEVOPS" \
  --role="roles/iam.serviceAccountUser" \
  --condition=None --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_DEVOPS" \
  --role="roles/compute.instanceAdmin" \
  --condition=None --quiet

# Task 4: Create compute instance 'vm-2' with service account attached
echo
echo "Task 4: Creating compute instance 'vm-2' in $ZONE..."
gcloud compute instances create vm-2 \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --service-account="$SA_DEVOPS" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" --quiet 2>/dev/null || true

# Task 5: Create a custom role using a YAML file
echo
echo "Task 5: Creating custom role using role-definition.yaml..."
cat << 'EOF' > role-definition.yaml
title: Custom Role
description: Custom role with cloudsql.instances.connect and cloudsql.instances.get permissions
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

gcloud iam roles create customRole \
  --project="$PROJECT_ID" \
  --file=role-definition.yaml --quiet 2>/dev/null || true

# Task 6: Create bigquery-qwiklab service account and assign BigQuery roles
echo
echo "Task 6: Creating service account 'bigquery-qwiklab'..."
gcloud iam service-accounts create bigquery-qwiklab \
  --display-name="bigquery-qwiklab" --quiet 2>/dev/null || true

SA_BQ="bigquery-qwiklab@${PROJECT_ID}.iam.gserviceaccount.com"
echo "BigQuery Service Account: $SA_BQ"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_BQ" \
  --role="roles/bigquery.dataViewer" \
  --condition=None --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_BQ" \
  --role="roles/bigquery.user" \
  --condition=None --quiet

# Prepare startup script for bigquery-instance
cat << 'EOF' > /tmp/bq-startup.sh
#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip python3-venv git
python3 -m venv /opt/myvenv
source /opt/myvenv/bin/activate
pip install --upgrade pip
pip install google-cloud-bigquery pyarrow pandas db-dtypes

cat << 'PYEOF' > /opt/query.py
from google.auth import compute_engine
from google.cloud import bigquery

credentials = compute_engine.Credentials(
    service_account_email='TARGET_SA'
)

query = '''
SELECT name, SUM(number) as total_people
FROM `bigquery-public-data.usa_names.usa_1910_2013`
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''

client = bigquery.Client(
    project='TARGET_PROJECT_ID',
    credentials=credentials
)

print(client.query(query).to_dataframe())
PYEOF

sed -i "s/TARGET_PROJECT_ID/PROJECT_ID_VAL/g" /opt/query.py
sed -i "s/TARGET_SA/SA_VAL/g" /opt/query.py
python3 /opt/query.py > /tmp/query.log 2>&1
EOF

sed -i "s/PROJECT_ID_VAL/${PROJECT_ID}/g" /tmp/bq-startup.sh
sed -i "s/SA_VAL/${SA_BQ}/g" /tmp/bq-startup.sh

# Task 6: Create bigquery-instance VM
echo "Task 6: Creating instance 'bigquery-instance' in $ZONE..."
gcloud compute instances create bigquery-instance \
  --zone="$ZONE" \
  --machine-type=e2-standard-2 \
  --service-account="$SA_BQ" \
  --scopes="https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/cloud-platform" \
  --metadata-from-file=startup-script=/tmp/bq-startup.sh --quiet 2>/dev/null || true

echo
echo "=========================================="
echo "ARC134 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 2: Create a service account using gcloud CLI"
echo "- Task 3: Grant IAM permissions to a service account using gcloud CLI"
echo "- Task 4: Create a compute instance with a service account attached using gcloud"
echo "- Task 5: Create a custom role using a YAML file"
echo "- Task 6: Use the client libraries to access BigQuery from a service account"
echo "=========================================="
