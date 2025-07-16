#!/bin/bash

# Test script for MediaLibrary package
# This script formats code and then runs tests

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🧪 Testing MediaLibrary package..."

# Format code first
echo "📝 Running SwiftFormat..."
"$SCRIPT_DIR/format.sh"

# Run tests
echo "🔬 Running tests..."
cd "$PROJECT_ROOT"
swift test

echo "✅ Tests completed successfully!"