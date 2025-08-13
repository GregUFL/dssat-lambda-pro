# DSSAT Lambda Pro - Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed and running
- ECR repository access
- S3 buckets for input/output

## 🏗️ Infrastructure Setup

### 1. Create S3 Buckets
```bash
# Input bucket for experiment files
aws s3 mb s3://your-dssat-inputs

# Output bucket for results
aws s3 mb s3://your-dssat-outputs
```

### 2. Create ECR Repository
```bash
aws ecr create-repository --repository-name dssat-lambda-pro --region us-east-1
```

### 3. IAM Role and Policies

Create IAM role `dssat-lambda-pro-role` with:

**Trust Policy:**
```json
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
```

**Permission Policy:**
```json
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
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::your-dssat-inputs/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-dssat-outputs/*"
      ]
    }
  ]
}
```

## 🚀 Deployment Process

### 1. Build and Push Docker Image
```bash
# Build the image
docker build -t dssat-lambda-pro -f infra/Dockerfile .

# Tag for ECR
docker tag dssat-lambda-pro:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:latest

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:latest
```

### 2. Create Lambda Function
```bash
aws lambda create-function \
  --function-name dssat-lambda-pro \
  --package-type Image \
  --code ImageUri=<account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:latest \
  --role arn:aws:iam::<account-id>:role/dssat-lambda-pro-role \
  --timeout 900 \
  --memory-size 2048 \
  --environment Variables='{
    "DSSATDIR":"/DSSAT48",
    "DSSATPATH":"/DSSAT48",
    "LD_LIBRARY_PATH":"/var/task/lib",
    "PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/task/bin"
  }'
```

### 3. Test Deployment
```bash
# Create test payload
cat > test-payload.json << 'EOF'
{
  "s3_input_bucket": "your-dssat-inputs",
  "s3_input_key": "test/experiment.zip",
  "s3_output_bucket": "your-dssat-outputs",
  "s3_output_prefix": "test-results"
}
EOF

# Invoke function
aws lambda invoke \
  --function-name dssat-lambda-pro \
  --cli-binary-format raw-in-base64-out \
  --payload file://test-payload.json \
  response.json

# Check response
cat response.json
```

## 🔄 Updates and Versioning

### Update Function Code
```bash
# Build new version
docker build -t dssat-lambda-pro:v2 -f infra/Dockerfile .
docker tag dssat-lambda-pro:v2 <account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:v2
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:v2

# Update Lambda function
aws lambda update-function-code \
  --function-name dssat-lambda-pro \
  --image-uri <account-id>.dkr.ecr.us-east-1.amazonaws.com/dssat-lambda-pro:v2
```

## 🛠️ Configuration

### Environment Variables
| Variable | Value | Purpose |
|----------|-------|---------|
| `DSSATDIR` | `/DSSAT48` | DSSAT root directory |
| `DSSATPATH` | `/DSSAT48` | DSSAT path reference |
| `LD_LIBRARY_PATH` | `/var/task/lib` | Fortran libraries |
| `PATH` | `(full path)` | Executable search path |

### Lambda Settings
- **Timeout**: 900 seconds (15 minutes)
- **Memory**: 2048 MB
- **Architecture**: x86_64
- **Package Type**: Image

## 🔍 Monitoring

### CloudWatch Logs
- Log Group: `/aws/lambda/dssat-lambda-pro`
- Check for initialization and execution logs

### Common Issues
1. **Timeout**: Increase timeout for complex simulations
2. **Memory**: Increase memory for large datasets
3. **Permissions**: Verify S3 bucket access

## 📊 Performance Optimization

### Provisioned Concurrency
For consistent performance:
```bash
aws lambda put-provisioned-concurrency-config \
  --function-name dssat-lambda-pro \
  --qualifier '$LATEST' \
  --provisioned-concurrency-amount 1
```

### Reserved Concurrency
To control costs:
```bash
aws lambda put-reserved-concurrency \
  --function-name dssat-lambda-pro \
  --reserved-concurrency-amount 10
```
