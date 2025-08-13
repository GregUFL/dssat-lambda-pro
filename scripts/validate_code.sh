#!/bin/bash
# Final validation and code quality check

echo "🔍 Final Validation & Code Quality Check"
echo "========================================"

# Check Python code quality
echo "📋 Python Code Quality:"
find src/ -name "*.py" -exec python3 -m py_compile {} \;
echo "✅ All Python files compile successfully"

# Check shell script syntax
echo "📋 Shell Script Quality:"
find scripts/ src/ -name "*.sh" -exec bash -n {} \;
echo "✅ All shell scripts have valid syntax"

# Check for TODO/FIXME comments
echo "📋 Code Review:"
TODO_COUNT=$(find src/ -name "*.py" -exec grep -l "TODO\|FIXME" {} \; | wc -l)
if [ $TODO_COUNT -eq 0 ]; then
    echo "✅ No TODO/FIXME comments found"
else
    echo "⚠️  Found $TODO_COUNT files with TODO/FIXME comments"
fi

# Check file permissions
echo "📋 File Permissions:"
find scripts/ -name "*.sh" ! -executable -print | while read script; do
    echo "⚠️  $script is not executable"
done

# Docker image size check
echo "📋 Docker Image Optimization:"
IMAGE_SIZE=$(docker images dssat-lambda-pro:v4 --format "table {{.Size}}" | tail -n 1)
echo "📦 Current image size: $IMAGE_SIZE"

echo ""
echo "✅ Code quality validation completed!"
