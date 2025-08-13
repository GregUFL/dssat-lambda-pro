#!/usr/bin/env bash
set -euo pipefail

# AWS Deployment Script for DSSAT Lambda Pro
# Creates ECR repo (if missing), builds & pushes image, provisions S3 buckets, IAM role & Lambda function.
# Defaults are safe; override via flags.

usage() {
  cat <<EOF
Usage: $0 [options]
Options:
  -r, --region REGION          AWS region (default: us-east-1)
  -f, --function NAME          Lambda function name (default: dssat-crop-simulation)
  -p, --bucket-prefix PREFIX   S3 bucket prefix (default: dssatlambda)
  -m, --mock                   Use mock Dockerfile (infra/Dockerfile.mock) instead of full build
  -a, --arch ARCH              Lambda architecture (x86_64|arm64) (default: x86_64)
  -t, --tag TAG                Image tag (default: git short hash or 'latest')
  -d, --dry-run                Print actions only, don't execute AWS/Docker commands
  -h, --help                   Show this help
EOF
}

REGION="us-east-1"
LAMBDA_FUNCTION_NAME="dssat-crop-simulation"
BUCKET_PREFIX="dssatlambda"
USE_MOCK=false
ARCH="x86_64"
DRY_RUN=false
IMAGE_TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region) REGION="$2"; shift 2;;
    -f|--function) LAMBDA_FUNCTION_NAME="$2"; shift 2;;
    -p|--bucket-prefix) BUCKET_PREFIX="$2"; shift 2;;
    -m|--mock) USE_MOCK=true; shift;;
    -a|--arch) ARCH="$2"; shift 2;;
    -t|--tag) IMAGE_TAG="$2"; shift 2;;
    -d|--dry-run) DRY_RUN=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

if [[ -z "$IMAGE_TAG" ]]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    IMAGE_TAG="$(git rev-parse --short HEAD)"
  else
    IMAGE_TAG="latest"
  fi
fi

DATE_STAMP="$(date +%Y%m%d-%H%M%S)"
DSSATIN_BUCKET="${BUCKET_PREFIX}-in-${DATE_STAMP}-${RANDOM}"
DSSATOUT_BUCKET="${BUCKET_PREFIX}-out-${DATE_STAMP}-${RANDOM}"

DOCKERFILE="infra/Dockerfile"
[[ "$USE_MOCK" == true ]] && DOCKERFILE="infra/Dockerfile.mock"

echo "🚀 DSSAT Lambda Pro - AWS Deployment"
echo "==================================="
echo "Configuration:" >&2
echo "  Region             : $REGION" >&2
echo "  Function Name      : $LAMBDA_FUNCTION_NAME" >&2
echo "  Architecture       : $ARCH" >&2
echo "  Image Tag          : $IMAGE_TAG" >&2
echo "  Dockerfile         : $DOCKERFILE" >&2
echo "  Input Bucket       : $DSSATIN_BUCKET" >&2
echo "  Output Bucket      : $DSSATOUT_BUCKET" >&2
echo "  Dry Run            : $DRY_RUN" >&2
echo ""

run() { if $DRY_RUN; then echo "DRY-RUN -> $*"; else echo ">$ $*"; eval "$*"; fi }

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install and configure AWS CLI first."
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

echo "🪣 Creating S3 Buckets..."
run aws s3 mb s3://$DSSATIN_BUCKET --region "$REGION"
run aws s3 mb s3://$DSSATOUT_BUCKET --region "$REGION"

# Set S3 bucket policies (simplified approach - use IAM role instead)
echo "🔐 Setting S3 permissions via IAM (simpler approach)..."
# Note: We'll create comprehensive IAM policies instead of bucket policies

# Upload test data to DSSATIN bucket
echo "📤 Uploading test data..."
pushd tests/inputs >/dev/null
run zip -qr test-simulation.zip ./*
run aws s3 cp test-simulation.zip s3://$DSSATIN_BUCKET/inputs/test-simulation/inputs.zip
popd >/dev/null

# Build Docker image for Lambda
echo "🐳 Building Docker image for Lambda..."
echo "🐳 Building Docker image ($DOCKERFILE)..."
run docker build -t "$LAMBDA_FUNCTION_NAME:$IMAGE_TAG" -f "$DOCKERFILE" .
run docker tag "$LAMBDA_FUNCTION_NAME:$IMAGE_TAG" "$LAMBDA_FUNCTION_NAME:latest"

# Create ECR repository
echo "📦 Creating ECR repository..."
run aws ecr create-repository --repository-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" 2>/dev/null || true

# Get ECR login
ECR_URI=$(aws ecr describe-repositories --repository-names "$LAMBDA_FUNCTION_NAME" --region "$REGION" --query 'repositories[0].repositoryUri' --output text)
if ! $DRY_RUN; then
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URI"
else
  echo "DRY-RUN -> docker login (skipped)"
fi

# Tag and push image
echo "⬆️  Pushing image to ECR..."
run docker tag "$LAMBDA_FUNCTION_NAME:$IMAGE_TAG" "$ECR_URI:$IMAGE_TAG"
run docker tag "$LAMBDA_FUNCTION_NAME:$IMAGE_TAG" "$ECR_URI:latest"
run docker push "$ECR_URI:$IMAGE_TAG"
run docker push "$ECR_URI:latest"

# Create IAM role with comprehensive S3 permissions
echo "🔐 Creating IAM role and policies..."
IAM_ROLE_NAME="DSSATLambdaExecutionRole"

# Create trust policy for Lambda
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the IAM role
aws iam create-role \
  --role-name "$IAM_ROLE_NAME" \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --description "Execution role for DSSAT Lambda function with S3 access" \
  2>/dev/null || echo "Role already exists"

# Create comprehensive IAM policy for DSSAT Lambda
cat > /tmp/dssat-lambda-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::${DSSATIN_BUCKET}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${DSSATOUT_BUCKET}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${DSSATIN_BUCKET}",
        "arn:aws:s3:::${DSSATOUT_BUCKET}"
      ]
    }
  ]
}
EOF

# Attach policy to role
POLICY_NAME="DSSATLambdaS3Policy"
run aws iam put-role-policy \
  --role-name "$IAM_ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file:///tmp/dssat-lambda-policy.json

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.Arn' --output text)

# Wait for role to be ready
echo "⏳ Waiting for IAM role to be ready..."
sleep 10

# Create Lambda function
echo "λ Creating Lambda function..."
if ! aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "λ Creating Lambda function..."
  run aws lambda create-function \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --role "$ROLE_ARN" \
    --code ImageUri=$ECR_URI:$IMAGE_TAG \
    --package-type Image \
    --timeout 900 \
    --memory-size 1024 \
    --architectures "$ARCH" \
    --environment Variables="{DSSATIN_BUCKET=$DSSATIN_BUCKET,DSSATOUT_BUCKET=$DSSATOUT_BUCKET}" \
    --region "$REGION"
else
  echo "λ Updating Lambda function code..."
  run aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --image-uri $ECR_URI:$IMAGE_TAG \
    --region "$REGION"
fi

echo "λ Publishing new version (optional step)..."
run aws lambda publish-version --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" >/dev/null || true

# Test the function
echo "🧪 Testing Lambda function..."
cat > /tmp/test-event.json << EOF
{
    "s3_input_bucket": "$DSSATIN_BUCKET",
    "s3_input_key": "inputs/test-simulation/inputs.zip",
    "s3_output_bucket": "$DSSATOUT_BUCKET",
    "s3_output_prefix": "outputs/test-simulation",
    "unzip_outputs": true,
    "return_zip_b64": false
}
EOF

if ! $DRY_RUN; then
  aws lambda invoke \
      --function-name "$LAMBDA_FUNCTION_NAME" \
      --payload fileb:///tmp/test-event.json \
      --region "$REGION" \
      /tmp/response.json >/dev/null
fi

echo "📊 Lambda Response:"
if ! $DRY_RUN; then
  cat /tmp/response.json | jq .
else
  echo "(dry-run skipped invoke)"
fi

# Check outputs in S3
echo "📁 Checking outputs in S3..."
run aws s3 ls s3://$DSSATOUT_BUCKET/outputs/test-simulation/ --recursive

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🎯 Resources Created:"
echo "  📦 Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "  🪣 Input Bucket: s3://$DSSATIN_BUCKET" 
echo "  🪣 Output Bucket: s3://$DSSATOUT_BUCKET"
echo "  🐳 ECR Repository: $ECR_URI"
echo "  🔑 IAM Role: $IAM_ROLE_NAME"
echo ""
echo "🚀 Usage:"
echo "  1. Upload input ZIP files to: s3://$DSSATIN_BUCKET/inputs/"
echo "  2. Invoke Lambda with S3 paths"
echo "  3. Download results from: s3://$DSSATOUT_BUCKET/outputs/"
echo ""
echo "📝 Save these values for future use:"
echo "  DSSATIN_BUCKET=$DSSATIN_BUCKET"
echo "  DSSATOUT_BUCKET=$DSSATOUT_BUCKET"
echo "  LAMBDA_FUNCTION_NAME=$LAMBDA_FUNCTION_NAME"
echo "  IMAGE_URI=$ECR_URI:$IMAGE_TAG"
echo ""
echo "Next manual invoke example:"
echo "aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload '{\"s3_input_bucket\":\"$DSSATIN_BUCKET\",\"s3_input_key\":\"inputs/test-simulation/inputs.zip\",\"s3_output_bucket\":\"$DSSATOUT_BUCKET\",\"s3_output_prefix\":\"outputs/run1\",\"unzip_outputs\":true,\"return_zip_b64\":false}' response.json --region $REGION && cat response.json | jq ."

# Clean up temporary files
# Clean up temporary files
rm -f /tmp/trust-policy.json /tmp/dssat-lambda-policy.json /tmp/test-event.json || true
echo "Done." >&2
