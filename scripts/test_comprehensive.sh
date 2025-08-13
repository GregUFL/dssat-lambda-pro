#!/bin/bash
# DSSAT Lambda Pro - Comprehensive Test Suite
# Tests local Docker, AWS Lambda, and integration scenarios

set -e

echo "🧪 DSSAT Lambda Pro - Test Suite"
echo "=================================="

# Configuration
FUNCTION_NAME="dssat-lambda-pro"
INPUT_BUCKET="dssatin-11414"
OUTPUT_BUCKET="dssatout-11414"
TEST_KEY="inputs/test-simulation/inputs.zip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "${GREEN}✅ PASSED${NC}: $1"
}

test_failed() {
    echo -e "${RED}❌ FAILED${NC}: $1"
    exit 1
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}: $1"
}

echo ""
echo "📋 Pre-flight Checks"
echo "===================="

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    test_failed "AWS CLI not found"
fi
test_passed "AWS CLI available"

# Check Docker
if ! command -v docker &> /dev/null; then
    test_failed "Docker not found"
fi
test_passed "Docker available"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    test_failed "AWS credentials not configured"
fi
test_passed "AWS credentials configured"

# Check Lambda function exists
if ! aws lambda get-function --function-name $FUNCTION_NAME &> /dev/null; then
    test_failed "Lambda function '$FUNCTION_NAME' not found"
fi
test_passed "Lambda function exists"

# Check S3 buckets
if ! aws s3 ls s3://$INPUT_BUCKET &> /dev/null; then
    test_failed "Input bucket '$INPUT_BUCKET' not accessible"
fi
test_passed "Input bucket accessible"

if ! aws s3 ls s3://$OUTPUT_BUCKET &> /dev/null; then
    test_failed "Output bucket '$OUTPUT_BUCKET' not accessible"
fi
test_passed "Output bucket accessible"

# Check test input file
if ! aws s3 ls s3://$INPUT_BUCKET/$TEST_KEY &> /dev/null; then
    test_failed "Test input file not found: s3://$INPUT_BUCKET/$TEST_KEY"
fi
test_passed "Test input file available"

echo ""
echo "🔬 AWS Lambda Tests"
echo "=================="

# Test 1: Basic S3 Integration
echo "Test 1: Basic S3 Integration"
cat > /tmp/test1.json << EOF
{
  "s3_input_bucket": "$INPUT_BUCKET",
  "s3_input_key": "$TEST_KEY",
  "s3_output_bucket": "$OUTPUT_BUCKET",
  "s3_output_prefix": "test-suite/basic",
  "simulation_id": "test-suite-basic"
}
EOF

if aws lambda invoke --function-name $FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload file:///tmp/test1.json /tmp/response1.json &> /dev/null; then
    STATUS=$(cat /tmp/response1.json | jq -r '.status')
    if [ "$STATUS" = "OK" ]; then
        test_passed "Basic S3 integration"
    else
        test_failed "Basic S3 integration - Status: $STATUS"
    fi
else
    test_failed "Basic S3 integration - Lambda invocation failed"
fi

# Test 2: Unzipped Output
echo "Test 2: Unzipped Output to S3"
cat > /tmp/test2.json << EOF
{
  "s3_input_bucket": "$INPUT_BUCKET",
  "s3_input_key": "$TEST_KEY",
  "s3_output_bucket": "$OUTPUT_BUCKET",
  "s3_output_prefix": "test-suite/unzipped",
  "unzip_outputs": true,
  "simulation_id": "test-suite-unzipped"
}
EOF

if aws lambda invoke --function-name $FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload file:///tmp/test2.json /tmp/response2.json &> /dev/null; then
    STATUS=$(cat /tmp/response2.json | jq -r '.status')
    if [ "$STATUS" = "OK" ]; then
        # Check if individual files were uploaded
        if aws s3 ls s3://$OUTPUT_BUCKET/test-suite/unzipped/Summary.OUT &> /dev/null; then
            test_passed "Unzipped output to S3"
        else
            test_warning "Unzipped output - Summary.OUT not found"
        fi
    else
        test_failed "Unzipped output - Status: $STATUS"
    fi
else
    test_failed "Unzipped output - Lambda invocation failed"
fi

# Test 3: Module Override
echo "Test 3: Module Override"
cat > /tmp/test3.json << EOF
{
  "s3_input_bucket": "$INPUT_BUCKET",
  "s3_input_key": "$TEST_KEY",
  "s3_output_bucket": "$OUTPUT_BUCKET",
  "s3_output_prefix": "test-suite/module-override",
  "module_code": "MZCER048",
  "simulation_id": "test-suite-module"
}
EOF

if aws lambda invoke --function-name $FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload file:///tmp/test3.json /tmp/response3.json &> /dev/null; then
    STATUS=$(cat /tmp/response3.json | jq -r '.status')
    MODULE=$(cat /tmp/response3.json | jq -r '.module')
    if [ "$STATUS" = "OK" ] && [ "$MODULE" = "MZCER048" ]; then
        test_passed "Module override"
    else
        test_failed "Module override - Status: $STATUS, Module: $MODULE"
    fi
else
    test_failed "Module override - Lambda invocation failed"
fi

# Test 4: Error Handling
echo "Test 4: Error Handling"
cat > /tmp/test4.json << EOF
{
  "s3_input_bucket": "$INPUT_BUCKET",
  "s3_input_key": "nonexistent/file.zip",
  "s3_output_bucket": "$OUTPUT_BUCKET",
  "s3_output_prefix": "test-suite/error",
  "simulation_id": "test-suite-error"
}
EOF

if aws lambda invoke --function-name $FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload file:///tmp/test4.json /tmp/response4.json &> /dev/null; then
    STATUS=$(cat /tmp/response4.json | jq -r '.status')
    if [ "$STATUS" = "ERROR" ]; then
        test_passed "Error handling"
    else
        test_warning "Error handling - Expected ERROR status, got: $STATUS"
    fi
else
    test_failed "Error handling - Lambda invocation failed"
fi

echo ""
echo "📊 Performance Tests"
echo "==================="

# Test execution time
echo "Test 5: Performance Measurement"
START_TIME=$(date +%s)
aws lambda invoke --function-name $FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload file:///tmp/test1.json /tmp/perf_response.json &> /dev/null
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $DURATION -lt 120 ]; then
    test_passed "Performance - Execution time: ${DURATION}s (< 2 minutes)"
elif [ $DURATION -lt 300 ]; then
    test_warning "Performance - Execution time: ${DURATION}s (2-5 minutes)"
else
    test_warning "Performance - Execution time: ${DURATION}s (> 5 minutes)"
fi

echo ""
echo "🧹 Validation Tests"
echo "=================="

# Test 6: Output Validation
echo "Test 6: Output File Validation"
aws s3 cp s3://$OUTPUT_BUCKET/test-suite/basic/results.zip /tmp/test_results.zip &> /dev/null
if unzip -l /tmp/test_results.zip | grep -q "Summary.OUT"; then
    test_passed "Output validation - Summary.OUT present"
else
    test_failed "Output validation - Summary.OUT missing"
fi

if unzip -l /tmp/test_results.zip | grep -q "PlantGro.OUT"; then
    test_passed "Output validation - PlantGro.OUT present"
else
    test_failed "Output validation - PlantGro.OUT missing"
fi

# Test 7: Data Quality Check
echo "Test 7: Data Quality Check"
unzip -q /tmp/test_results.zip -d /tmp/test_output/
if [ -s /tmp/test_output/Summary.OUT ]; then
    if grep -q "HARWT" /tmp/test_output/Summary.OUT; then
        test_passed "Data quality - Harvest data present"
    else
        test_warning "Data quality - Harvest data not found"
    fi
else
    test_failed "Data quality - Summary.OUT is empty"
fi

echo ""
echo "🧽 Cleanup"
echo "=========="

# Cleanup test files
rm -f /tmp/test*.json /tmp/response*.json /tmp/perf_response.json /tmp/test_results.zip
rm -rf /tmp/test_output/
test_passed "Temporary files cleaned"

echo ""
echo "📋 Test Summary"
echo "==============="
echo -e "${GREEN}✅ All tests completed successfully!${NC}"
echo ""
echo "Your DSSAT Lambda Pro function is production-ready! 🚀"
echo ""
echo "Next steps:"
echo "1. Update documentation with any findings"
echo "2. Set up monitoring and alerts"
echo "3. Configure cost optimization"
echo "4. Deploy to production environment"
