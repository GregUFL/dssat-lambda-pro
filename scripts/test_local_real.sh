#!/bin/bash
set -euo pipefail

IMAGE_TAG=${1:-dssat-real:local}

echo "Building real DSSAT image ($IMAGE_TAG)..."
docker build -t "$IMAGE_TAG" -f infra/Dockerfile .

echo "Running container (Lambda runtime)..."
CID=$(docker run -d -p 9000:8080 "$IMAGE_TAG")
trap 'docker rm -f $CID >/dev/null 2>&1 || true' EXIT

echo "Waiting for startup..."; sleep 4

# Prepare sample event using local test zip
ZIP_PATH=tests/inputs/test-simulation.zip
if [ ! -f "$ZIP_PATH" ]; then
  echo "Missing $ZIP_PATH" >&2; exit 1
fi

cat > /tmp/local-event.json <<EOF
{
  "zip_b64": "$(base64 -w0 "$ZIP_PATH")",
  "return_zip_b64": true,
  "unzip_outputs": false
}
EOF

echo "Invoking..."
RESP=$(curl -s http://localhost:9000/2015-03-31/functions/function/invocations -d @/tmp/local-event.json)

echo "$RESP" | jq .status .mode .runs .exit_code .artifacts

# Extract Summary.OUT preview
ZIP_B64=$(echo "$RESP" | jq -r .results_zip_b64)
if [ "$ZIP_B64" != "null" ]; then
  echo "$ZIP_B64" | base64 -d > /tmp/results.zip
  unzip -p /tmp/results.zip Summary.OUT | head -n 60 || true
fi

echo "Done."
