# Build Scripts

## iOS Setup

### Initial Setup

Before running the iOS app, ensure all dependencies are installed:

```bash
./scripts/setup_ios.sh
```

This script will:
- ✅ Check CocoaPods installation
- ✅ Install Flutter dependencies
- ✅ Install iOS CocoaPods

### Running iOS App

If you encounter "CocoaPods not installed" errors when running from your IDE, use:

```bash
./scripts/run_ios.sh
```

Or specify a device:
```bash
./scripts/run_ios.sh "iPhone 16"
```

**Note:** If running from your IDE (Cursor/VS Code), you may need to configure the IDE to include `/opt/homebrew/bin` in the PATH, or use the `run_ios.sh` script instead.

## Automatic Build Number Increment

These scripts automatically increment your build number before each build.

## Quick Start

### Option 1: Auto-increment + Build (Recommended)

```bash
./scripts/build_ios.sh
```

This will:

- ✅ Automatically increment build number
- ✅ Clean the project
- ✅ Get dependencies
- ✅ Install pods
- ✅ Build iOS app

### Option 2: Build without incrementing

```bash
./scripts/build_ios.sh --no-increment
```

### Option 3: Increment build number only

```bash
./scripts/increment_build.sh
```

## Examples

**Current version:** `1.0.2+5`

**After running build script:**

- Version becomes: `1.0.2+6`
- App is built with new build number

## Build Types

```bash
# Release build (default)
./scripts/build_ios.sh --release

# Debug build
./scripts/build_ios.sh --debug

# Build without incrementing
./scripts/build_ios.sh --no-increment --release
```

## Manual Version Update

If you need to update the version number (not just build number), edit `pubspec.yaml`:

```yaml
version: 1.0.3+1 # Version 1.0.3, Build 1
```

The build number will continue incrementing from there.

## Integration with Xcode

You can add this as a pre-build script in Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Build Phases
3. Click "+" → New Run Script Phase
4. Add this script:
   ```bash
   cd "${SRCROOT}/.."
   ./scripts/increment_build.sh
   ```
5. Move it before "Compile Sources"

Now every time you build in Xcode, the build number will auto-increment!
