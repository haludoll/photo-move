#!/bin/bash

# Build script for MediaLibrary package
# This script formats code and then builds the package

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🚀 Building MediaLibrary package..."

# Format code first
echo "📝 Running SwiftFormat..."
"$SCRIPT_DIR/format.sh"

# Build the package
echo "🔨 Building package..."
cd "$PROJECT_ROOT"
swift build

echo "✅ Build completed successfully!"