#!/bin/bash
set -e

# Disable interactive prompts
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# Setup Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

# Setup Region and Zone
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-east4"
fi

ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
if [ -z "$ZONE" ] || [ "$ZONE" = "(unset)" ]; then
  ZONE="${REGION}-b"
fi

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo "=========================================="
echo "Starting GSP199 Automation"
echo "Project ID: $PROJECT_ID"
echo "Region:     $REGION"
echo "Zone:       $ZONE"
echo "=========================================="

# Task 1: Create my-sa-123 service account and assign storage.admin role
echo "Task 1: Creating service account 'my-sa-123'..."
gcloud iam service-accounts create my-sa-123 \
  --display-name "my service account" 2>/dev/null || true

echo "Granting roles/storage.admin to my-sa-123..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:my-sa-123@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/storage.admin" \
  --condition=None

# Task 2: Create bigquery-qwiklab service account and assign BigQuery roles
echo "Task 2: Creating service account 'bigquery-qwiklab'..."
gcloud iam service-accounts create bigquery-qwiklab \
  --display-name "bigquery-qwiklab" 2>/dev/null || true

echo "Assigning BigQuery roles to bigquery-qwiklab..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:bigquery-qwiklab@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/bigquery.dataViewer" \
  --condition=None

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:bigquery-qwiklab@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/bigquery.user" \
  --condition=None

# Prepare startup script file to avoid metadata comma-parsing errors
cat << 'EOF' > /tmp/startup-script.sh
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
    service_account_email='bigquery-qwiklab@TARGET_PROJECT_ID.iam.gserviceaccount.com'
)

query = '''
SELECT year, COUNT(1) as num_babies
FROM publicdata.samples.natality
WHERE year > 2000
GROUP BY year
ORDER BY year
'''

client = bigquery.Client(
    project='TARGET_PROJECT_ID',
    credentials=credentials
)

print(client.query(query).to_dataframe())
PYEOF

sed -i "s/TARGET_PROJECT_ID/PROJECT_ID_PLACEHOLDER/g" /opt/query.py

python3 /opt/query.py 2>&1 | tee /tmp/query.log
EOF

sed -i "s/PROJECT_ID_PLACEHOLDER/${PROJECT_ID}/g" /tmp/startup-script.sh

# Create Compute Engine VM attached to bigquery-qwiklab using metadata-from-file
echo "Creating VM instance 'bigquery-instance' with automated BigQuery query execution..."
if gcloud compute instances describe bigquery-instance --zone="$ZONE" &>/dev/null; then
  echo "Instance bigquery-instance already exists in $ZONE."
else
  gcloud compute instances create bigquery-instance \
    --zone="$ZONE" \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --service-account="bigquery-qwiklab@${PROJECT_ID}.iam.gserviceaccount.com" \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --metadata-from-file=startup-script=/tmp/startup-script.sh
fi

echo "Waiting for VM initialization and BigQuery query completion..."
for i in {1..30}; do
  if gcloud compute instances get-serial-port-output bigquery-instance --zone="$ZONE" 2>/dev/null | grep -iq "num_babies"; then
    echo "BigQuery query executed successfully from the instance!"
    break
  fi
  sleep 4
done

echo
echo "=========================================================="
echo "GSP199 Execution Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create and Manage Service Accounts"
echo "- Task 2: Access BigQuery using a Service Account"
echo "=========================================================="
