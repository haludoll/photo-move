#!/bin/bash

# SwiftFormat script for photo-move project
# This script formats all Swift files in the project

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🔧 Formatting Swift files in photo-move project..."

# Format all Swift files in the project
swiftformat "$PROJECT_ROOT" --config "$PROJECT_ROOT/.swiftformat"

echo "✅ SwiftFormat completed!"