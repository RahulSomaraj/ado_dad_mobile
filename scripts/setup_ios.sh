#!/bin/bash

# Script to ensure iOS dependencies are properly set up
# This ensures CocoaPods is accessible and pods are installed

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Add Homebrew to PATH if not already there
export PATH="/opt/homebrew/bin:$PATH"

cd "$PROJECT_DIR"

echo "🔍 Checking CocoaPods installation..."
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods not found in PATH"
    echo "   Please install CocoaPods: sudo gem install cocoapods"
    exit 1
fi

echo "✅ CocoaPods found: $(pod --version)"

echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get

echo ""
echo "🍎 Installing iOS pods..."
cd ios
pod install
cd ..

echo ""
echo "✅ iOS setup complete!"
echo ""
echo "You can now run: flutter run -d <device-id>"

