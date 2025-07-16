#!/bin/bash

# SwiftFormat Build Phase Script for Xcode
# This script is called by Xcode during the build process

# Exit immediately if any command fails
set -e

# Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "warning: SwiftFormat not installed. Install with 'brew install swiftformat'"
    exit 0
fi

# Get the project root directory (two levels up from the script)
PROJECT_ROOT="${SRCROOT}/.."

# Check if .swiftformat config exists
if [ ! -f "$PROJECT_ROOT/.swiftformat" ]; then
    echo "warning: .swiftformat configuration file not found at $PROJECT_ROOT"
    exit 0
fi

# Only format files that have been modified
# This makes the build faster by not formatting everything every time
echo "Running SwiftFormat..."

# Format all Swift files in the current target
swiftformat "${SRCROOT}" --config "$PROJECT_ROOT/.swiftformat" --cache ignore

echo "SwiftFormat completed"