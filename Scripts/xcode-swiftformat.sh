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

# Get the project root directory
# If called from Xcode, SRCROOT is set to the App directory
# If called manually, use the script location
if [ -n "$SRCROOT" ]; then
    # When called from Xcode, the .swiftformat file is in the SRCROOT (App directory)
    CONFIG_DIR="${SRCROOT}"
    PROJECT_ROOT="${SRCROOT}/.."
else
    # Get the directory of this script and go up one level
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_ROOT="$SCRIPT_DIR/.."
    CONFIG_DIR="$PROJECT_ROOT/App"
fi

# Check if .swiftformat config exists and is readable
if [ ! -r "$CONFIG_DIR/.swiftformat" ]; then
    echo "warning: .swiftformat configuration file not found or not readable at $CONFIG_DIR"
    echo "Running SwiftFormat with default configuration..."
    
    # Create a temporary directory and run SwiftFormat from there to avoid config file auto-detection
    TEMP_DIR=$(mktemp -d)
    if [ -n "$SRCROOT" ]; then
        cd "$TEMP_DIR" && swiftformat "${SRCROOT}" --cache ignore --disable fileHeader
    else
        cd "$TEMP_DIR" && swiftformat "$PROJECT_ROOT" --cache ignore --disable fileHeader
    fi
    rm -rf "$TEMP_DIR"
    
    echo "SwiftFormat completed with default configuration"
    exit 0
fi

# Only format files that have been modified
# This makes the build faster by not formatting everything every time
echo "Running SwiftFormat..."

# Format all Swift files in the project
# If called from Xcode, format the SRCROOT directory
# If called manually, format the entire project
if [ -n "$SRCROOT" ]; then
    # When called from Xcode, use the config file directly in the same directory
    swiftformat "${SRCROOT}" --config "$CONFIG_DIR/.swiftformat" --cache ignore
else
    swiftformat "$PROJECT_ROOT" --config "$CONFIG_DIR/.swiftformat" --cache ignore
fi

echo "SwiftFormat completed"
