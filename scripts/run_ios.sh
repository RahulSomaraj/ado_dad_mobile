#!/bin/bash

# Script to run Flutter iOS app with correct PATH for CocoaPods
# Usage: ./scripts/run_ios.sh [device-id]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Add Homebrew to PATH (required for CocoaPods)
export PATH="/opt/homebrew/bin:$PATH"

cd "$PROJECT_DIR"

# Check if CocoaPods is available
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods not found. Please run: ./scripts/setup_ios.sh"
    exit 1
fi

# Get device ID from argument or use default
DEVICE_ID="${1:-iPhone 16}"

echo "🚀 Running Flutter app on $DEVICE_ID..."
echo ""

# Run Flutter with the correct PATH
flutter run -d "$DEVICE_ID"

