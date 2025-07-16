#!/bin/bash

# Swift Format Build Phase Script for Xcode
# This script is called by Xcode during the build process

# Exit immediately if any command fails
set -e

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    echo "warning: swift-format not installed. Install with 'brew install swift-format'"
    exit 0
fi

# Get the project root directory
# If called from Xcode, SRCROOT is set to the App directory
# If called manually, use the script location
if [ -n "$SRCROOT" ]; then
    # When called from Xcode, the .swiftformat file is in the project root (one level up from App)
    PROJECT_ROOT="${SRCROOT}/.."
    CONFIG_DIR="${PROJECT_ROOT}"
else
    # Get the directory of this script and go up one level
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    PROJECT_ROOT="$SCRIPT_DIR/.."
    CONFIG_DIR="$PROJECT_ROOT"
fi

# Check if .swift-format config exists and is readable
if [ ! -r "$CONFIG_DIR/.swift-format" ]; then
    echo "warning: .swift-format configuration file not found or not readable at $CONFIG_DIR"
    echo "Running swift-format with default configuration..."
    
    # Use swift-format with default configuration
    if [ -n "$SRCROOT" ]; then
        find "${SRCROOT}" -name "*.swift" -exec swift-format --in-place {} \;
    else
        find "$PROJECT_ROOT" -name "*.swift" -exec swift-format --in-place {} \;
    fi
    
    echo "swift-format completed with default configuration"
    exit 0
fi

# Only format files that have been modified
# This makes the build faster by not formatting everything every time
echo "Running swift-format..."

# Format all Swift files in the project
# If called from Xcode, format the SRCROOT directory
# If called manually, format the entire project
if [ -n "$SRCROOT" ]; then
    # When called from Xcode, use the config file directly in the same directory
    find "${SRCROOT}" -name "*.swift" -exec swift-format --configuration "$CONFIG_DIR/.swift-format" --in-place {} \;
else
    find "$PROJECT_ROOT" -name "*.swift" -exec swift-format --configuration "$CONFIG_DIR/.swift-format" --in-place {} \;
fi

echo "swift-format completed"
