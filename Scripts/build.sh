#!/bin/bash

# Build script for photo-move project
# This script formats code and then builds the project

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🚀 Building photo-move project..."

# Format code first
echo "📝 Running SwiftFormat..."
"$SCRIPT_DIR/format.sh"

# Build all packages
echo "🔨 Building packages..."

# Build MediaLibrary package
echo "📦 Building MediaLibrary..."
cd "$PROJECT_ROOT"
swift build --package-path MediaLibrary

# Add other packages here as they are created

echo "✅ Build completed successfully!"