#!/bin/bash

# Automatic iOS build script with version increment
# Usage: ./scripts/build_ios.sh [--no-increment] [--release|--debug]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INCREMENT_SCRIPT="$SCRIPT_DIR/increment_build.sh"

# Default values
INCREMENT=true
BUILD_TYPE="--release"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-increment)
            INCREMENT=false
            shift
            ;;
        --debug)
            BUILD_TYPE="--debug"
            shift
            ;;
        --release)
            BUILD_TYPE="--release"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--no-increment] [--release|--debug]"
            exit 1
            ;;
    esac
done

cd "$PROJECT_DIR"

# Set encoding
export LANG=en_US.UTF-8

# Increment build number if requested
if [ "$INCREMENT" = true ]; then
    echo "🔄 Auto-incrementing build number..."
    "$INCREMENT_SCRIPT"
    echo ""
fi

# Get current version
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo "📦 Building iOS app..."
echo "   Version: $CURRENT_VERSION"
echo "   Type: $BUILD_TYPE"
echo ""

# Clean and get dependencies
echo "🧹 Cleaning..."
flutter clean > /dev/null 2>&1

echo "📥 Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo "📦 Installing pods..."
cd ios
pod install > /dev/null 2>&1
cd ..

# Build
echo "🔨 Building iOS app..."
flutter build ios $BUILD_TYPE

echo ""
echo "✅ Build complete!"
echo "   Bundle ID: com.adodad.mobile"
echo "   Version: $CURRENT_VERSION"
echo ""
echo "📱 Next steps:"
echo "   1. Open Xcode: open ios/Runner.xcworkspace"
echo "   2. Product → Archive"
echo "   3. Distribute to App Store"

