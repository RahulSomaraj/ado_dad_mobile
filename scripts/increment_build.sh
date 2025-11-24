#!/bin/bash

# Script to automatically increment build number
# Usage: ./scripts/increment_build.sh

set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC_FILE"
    exit 1
fi

# Extract current version
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | tr -d ' ')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi

# Split version into version number and build number
VERSION_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${VERSION_NUMBER}+${NEW_BUILD_NUMBER}"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
else
    # Linux
    sed -i "s/^version:.*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
fi

echo "✅ Build number incremented:"
echo "   Previous: $CURRENT_VERSION"
echo "   New:      $NEW_VERSION"
echo ""
echo "📱 Version: $VERSION_NUMBER"
echo "🔢 Build:   $NEW_BUILD_NUMBER"

