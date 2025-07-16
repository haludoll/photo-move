#!/bin/bash

# SwiftFormat script for MediaLibrary package
# This script formats all Swift files in the package

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🔧 Formatting Swift files in MediaLibrary package..."

# Format all Swift files in Sources and Tests directories
swiftformat "$PROJECT_ROOT/Sources" "$PROJECT_ROOT/Tests" --config "$PROJECT_ROOT/.swiftformat"

echo "✅ SwiftFormat completed!"