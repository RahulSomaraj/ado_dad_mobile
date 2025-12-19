# Fix CocoaPods PATH Issue

## Problem
Flutter can't find CocoaPods when running from the IDE because `/opt/homebrew/bin` is not in the IDE's PATH.

## Solutions

### Solution 1: Use the Run Script (Easiest)
Run the app using the provided script:
```bash
./scripts/run_ios.sh
```

### Solution 2: Restart IDE After Configuration
I've created `.vscode/settings.json` and `.vscode/launch.json` files that should configure the PATH. 

**After creating these files:**
1. **Restart Cursor/VS Code completely** (quit and reopen)
2. Try running the app again from the IDE

### Solution 3: Create System-Wide Symlink (Requires Sudo)
Run this command in your terminal (you'll be prompted for your password):
```bash
sudo ln -sf /opt/homebrew/bin/pod /usr/local/bin/pod
```

This makes CocoaPods available in a standard location that Flutter can find.

### Solution 4: Run from Terminal
Instead of running from the IDE, use a terminal:
```bash
cd /Users/aryaarjun/Desktop/ado_dad_user
flutter run -d "iPhone 16"
```

### Solution 5: Configure IDE Environment Manually
If the above don't work, you can manually configure your IDE:

1. Open Cursor/VS Code settings
2. Search for "dart.env" or "environment"
3. Add: `PATH` = `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`

## Verification
To verify CocoaPods is accessible:
```bash
which pod
# Should output: /opt/homebrew/bin/pod

pod --version
# Should output: 1.16.2
```

## Current Status
✅ CocoaPods is installed at: `/opt/homebrew/bin/pod`
✅ Pods are already installed in `ios/Pods/`
✅ Podfile.lock exists

The issue is only that Flutter can't find the `pod` command when running from the IDE.

