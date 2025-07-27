#!/bin/bash

# Test script for photo-move project
# This script formats code and then runs tests

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🧪 Testing photo-move project..."

# Format code first
echo "📝 Running SwiftFormat..."
"$SCRIPT_DIR/format.sh"

# Run tests for all packages
echo "🔬 Running tests..."

# Test MediaLibrary package
echo "📦 Testing MediaLibrary..."
cd "$PROJECT_ROOT"
swift test --package-path MediaLibrary

# Add other packages here as they are created

echo "✅ Tests completed successfully!"