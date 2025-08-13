#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Build container
docker build -t dssat-lambda-pro:dev "$ROOT" -f "$ROOT/infra/Dockerfile"

# Run Lambda Runtime API locally
docker run --rm -p 9000:8080 dssat-lambda-pro:dev
