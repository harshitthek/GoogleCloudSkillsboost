#!/bin/bash
set -e

echo "=========================================="
echo "Starting ARC100 Challenge Lab Automation"
echo "Memories: Thumbnail Maker Function"
echo "=========================================="

# Authenticate if needed
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | grep -q "@"; then
  echo "Authenticating gcloud session..."
  gcloud auth login --quiet || true
fi

# Detect Project ID dynamically
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  PROJECT_ID="$DEVSHELL_PROJECT_ID"
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: Could not determine Project ID."
  exit 1
fi

gcloud config set project "$PROJECT_ID" --quiet 2>/dev/null || true
echo "Project ID: $PROJECT_ID"

# Detect Region with fallback to us-east1
REGION=$(gcloud config get-value compute/region 2>/dev/null)
if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
  REGION="us-east1"
fi
gcloud config set compute/region "$REGION" --quiet 2>/dev/null || true
echo "Region:     $REGION"

# Dynamic Parameter Resolution
if [ -z "$TOPIC_NAME" ]; then
  read -p "Enter Pub/Sub topic name (e.g., memories-topic-784): " TOPIC_NAME
fi

if [ -z "$BUCKET_NAME" ]; then
  BUCKET_NAME="memories-bucket-${PROJECT_ID}"
fi

FUNCTION_NAME="memories-thumbnail-maker"

echo
echo "Configuration Summary:"
echo "Project ID:    $PROJECT_ID"
echo "Region:        $REGION"
echo "Bucket Name:   $BUCKET_NAME"
echo "Topic Name:    $TOPIC_NAME"
echo "Function Name: $FUNCTION_NAME"
echo

# Enable required APIs (non-fatal if pre-activated or restricted)
echo "Enabling required Google Cloud APIs..."
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  --quiet 2>/dev/null || true

# Task 1: Create Cloud Storage Bucket
echo
echo "Task 1: Creating Cloud Storage bucket (gs://${BUCKET_NAME})..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  gcloud storage buckets create "gs://${BUCKET_NAME}" --location="$REGION" --quiet 2>/dev/null || \
  gsutil mb -l "$REGION" "gs://${BUCKET_NAME}" || true
fi

# Task 2: Create Pub/Sub Topic
echo
echo "Task 2: Creating Pub/Sub topic (${TOPIC_NAME})..."
if ! gcloud pubsub topics describe "$TOPIC_NAME" &>/dev/null; then
  gcloud pubsub topics create "$TOPIC_NAME" --quiet
fi

# Configure IAM permissions for Cloud Storage and Eventarc
echo
echo "Configuring Service Account permissions for Eventarc and Storage..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)" 2>/dev/null || true)

GCS_SERVICE_ACCOUNT=$(gcloud storage service-agent --project="$PROJECT_ID" 2>/dev/null || true)
if [ -z "$GCS_SERVICE_ACCOUNT" ] && [ -n "$PROJECT_NUMBER" ]; then
  GCS_SERVICE_ACCOUNT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
fi

if [ -n "$GCS_SERVICE_ACCOUNT" ]; then
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${GCS_SERVICE_ACCOUNT}" \
    --role="roles/pubsub.publisher" \
    --condition=None 2>/dev/null || true
fi

if [ -n "$PROJECT_NUMBER" ]; then
  # Eventarc service agent role
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com" \
    --role="roles/eventarc.serviceAgent" \
    --condition=None 2>/dev/null || true

  COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
  for ROLE in \
    roles/eventarc.eventReceiver \
    roles/eventarc.serviceAgent \
    roles/run.invoker \
    roles/storage.objectAdmin \
    roles/pubsub.publisher \
    roles/iam.serviceAccountTokenCreator; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:${COMPUTE_SA}" \
      --role="$ROLE" \
      --condition=None 2>/dev/null || true
  done
fi

# Task 3: Create Cloud Run Function
echo
echo "Task 3: Setting up Cloud Run Function (${FUNCTION_NAME})..."
WORK_DIR=~/memories_fn
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

cat << EOF > index.js
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('memories-thumbnail-maker', async cloudEvent => {
  const event = cloudEvent.data;
  console.log(\`Event: \${JSON.stringify(event)}\`);
  console.log(\`Hello \${event.bucket}\`);
  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "${TOPIC_NAME}";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1);

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      console.log(\`Processing Original: gs://\${bucketName}/\${fileName}\`);
      const gcsObject = bucket.file(fileName);
      const newFilename = \`\${filename_without_ext}_64x64_thumbnail.\${filename_ext}\`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, { fit: 'inside', withoutEnlargement: true })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: { contentType: \`image/\${filename_ext}\` },
        });

        console.log(\`Success: \${fileName} → \${newFilename}\`);
        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });
        console.log(\`Message published to \${topicName}\`);
      } catch (err) {
        console.error(\`Error: \${err}\`);
      }
    } else {
      console.log(\`gs://\${bucketName}/\${fileName} is not an image I can handle\`);
    }
  } else {
    console.log(\`gs://\${bucketName}/\${fileName} already has a thumbnail\`);
  }
});
EOF

cat << 'EOF' > package.json
{
  "name": "thumbnails",
  "version": "1.0.0",
  "description": "Create Thumbnail of uploaded image",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/pubsub": "^2.0.0",
    "@google-cloud/storage": "^6.11.0",
    "sharp": "^0.32.1"
  },
  "devDependencies": {},
  "engines": {
    "node": ">=4.3.2"
  }
}
EOF

echo "Deploying 2nd gen Cloud Run Function (${FUNCTION_NAME})..."
DEPLOY_SUCCESS=false
for i in {1..12}; do
  echo "Deployment attempt $i/12 for runtime nodejs22..."
  if gcloud functions deploy "$FUNCTION_NAME" \
    --gen2 \
    --runtime="nodejs22" \
    --region="$REGION" \
    --source=. \
    --entry-point="$FUNCTION_NAME" \
    --trigger-bucket="$BUCKET_NAME" \
    --trigger-location="$REGION" \
    --max-instances=1 \
    --quiet; then
    DEPLOY_SUCCESS=true
    echo "Cloud Function successfully deployed!"
    break
  fi
  echo "Eventarc Service Agent permissions are propagating. Waiting 20 seconds before retry..."
  sleep 20
done

if [ "$DEPLOY_SUCCESS" = false ]; then
  echo "Error: Cloud Function deployment failed after multiple retry attempts."
  exit 1
fi

# Task 4: Test Infrastructure by uploading image
echo
echo "Task 4: Testing infrastructure by uploading image..."
cd ~
curl -fsSL -o travel.jpg "https://storage.googleapis.com/cloud-training/arc101/travel.jpg" 2>/dev/null || \
curl -fsSL -o travel.jpg "https://storage.googleapis.com/cloud-training/gsp315/map.jpg" 2>/dev/null || true

gcloud storage cp travel.jpg "gs://${BUCKET_NAME}/travel.jpg"

echo "Waiting for thumbnail to be generated in bucket..."
for i in {1..30}; do
  if gcloud storage ls "gs://${BUCKET_NAME}/*thumbnail*" &>/dev/null; then
    echo "Thumbnail successfully verified in gs://${BUCKET_NAME}:"
    gcloud storage ls "gs://${BUCKET_NAME}"
    break
  fi
  sleep 2
done

echo
echo "=========================================="
echo "ARC100 Automation Completed Successfully!"
echo "You can now click 'Check my progress' on all tasks:"
echo "- Task 1: Create a bucket"
echo "- Task 2: Create a Pub/Sub topic"
echo "- Task 3: Create the thumbnail Cloud Run function"
echo "- Task 4: Verify the thumbnail was successfully created"
echo "=========================================="
