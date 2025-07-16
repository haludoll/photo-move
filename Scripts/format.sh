#!/bin/bash

# Swift Format script for photo-move project
# This script formats all Swift files in the project

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🔧 Formatting Swift files in photo-move project..."

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    echo "❌ swift-format not found. Please install it with: brew install swift-format"
    exit 1
fi

# Format all Swift files in the project
find "$PROJECT_ROOT" -name "*.swift" -exec swift-format --configuration "$PROJECT_ROOT/.swift-format" --in-place {} \;

echo "✅ swift-format completed!"