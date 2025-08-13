#!/bin/bash
set -e

echo "Building Docker image..."
docker build -t dssat-lambda-pro:dev . -f infra/Dockerfile.mock

echo "Starting Lambda container in background..."
docker run --rm -p 9000:8080 dssat-lambda-pro:dev &
DOCKER_PID=$!

echo "Waiting for container to start..."
sleep 5

echo "Testing Lambda function..."
curl -s http://localhost:9000/2015-03-31/functions/function/invocations \
  -H 'Content-Type: application/json' \
  -d @tests/sample_event.json | jq .

echo "Stopping container..."
kill $DOCKER_PID 2>/dev/null || true
wait $DOCKER_PID 2>/dev/null || true

echo "Test completed!"
