# Platform Configuration Guide

This document explains how to configure the app for development and production environments regarding HTTP/HTTPS traffic.

## Overview

The app supports both HTTP (for development) and HTTPS (for production) configurations. This is essential for:
- **Development**: Testing with local servers and development APIs
- **Production**: Secure communication with production servers

## Android Configuration

### Development Configuration (Current)
- **File**: `android/app/src/main/res/xml/network_security_config.xml`
- **Allows HTTP for**: localhost, development servers, local network
- **Enforces HTTPS for**: production domains

### Production Configuration
- **File**: `android/app/src/main/res/xml/network_security_config_production.xml`
- **Enforces HTTPS for**: all domains
- **No HTTP allowed**

### Switching to Production

1. **Replace the network security config**:
   ```bash
   cp android/app/src/main/res/xml/network_security_config_production.xml \
      android/app/src/main/res/xml/network_security_config.xml
   ```

2. **Update AndroidManifest.xml**:
   ```xml
   <application
       android:usesCleartextTraffic="false"
       android:networkSecurityConfig="@xml/network_security_config">
   ```

## iOS Configuration

### Development Configuration (Current)
- **File**: `ios/Runner/Info.plist`
- **NSAllowsArbitraryLoads**: `true`
- **Allows HTTP for**: development and testing

### Production Configuration
- **File**: `ios/Runner/Info.plist.production`
- **NSAllowsArbitraryLoads**: `false`
- **Enforces HTTPS for**: all domains

### Switching to Production

1. **Replace Info.plist**:
   ```bash
   cp ios/Runner/Info.plist.production ios/Runner/Info.plist
   ```

## Environment-Specific Build Scripts

### Development Build
```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug
```

### Production Build
```bash
# Switch to production configs first, then build
flutter build apk --release
flutter build ios --release
```

## Automated Build Scripts

### For Android (build_production.sh)
```bash
#!/bin/bash
# Switch to production config
cp android/app/src/main/res/xml/network_security_config_production.xml \
   android/app/src/main/res/xml/network_security_config.xml

# Update AndroidManifest.xml to disable cleartext
sed -i 's/android:usesCleartextTraffic="true"/android:usesCleartextTraffic="false"/' \
   android/app/src/main/AndroidManifest.xml

# Build production APK
flutter build apk --release
```

### For iOS (build_production_ios.sh)
```bash
#!/bin/bash
# Switch to production config
cp ios/Runner/Info.plist.production ios/Runner/Info.plist

# Build production iOS
flutter build ios --release
```

## Security Considerations

### Development
- ✅ HTTP allowed for localhost and development servers
- ✅ Local network access for testing
- ⚠️ Not suitable for production

### Production
- ✅ HTTPS enforced for all domains
- ✅ TLS 1.2+ required
- ✅ Forward secrecy enabled
- ✅ No cleartext traffic allowed

## Domain Configuration

### Development Domains (HTTP Allowed)
- `localhost`
- `10.0.2.2` (Android emulator)
- `127.0.0.1`
- `192.168.0.0/16` (local network)
- `10.0.0.0/8` (local network)
- `uat.ado-dad.com`
- `dev.ado-dad.com`
- `staging.ado-dad.com`

### Production Domains (HTTPS Only)
- `ado-dad.com`
- `www.ado-dad.com`
- `api.ado-dad.com`

## Troubleshooting

### Common Issues

1. **Network Security Policy Error (Android)**
   - Ensure `network_security_config.xml` is properly referenced in `AndroidManifest.xml`
   - Check that the file is in the correct location: `android/app/src/main/res/xml/`

2. **App Transport Security Error (iOS)**
   - Verify `NSAppTransportSecurity` is properly configured in `Info.plist`
   - Check that `NSAllowsArbitraryLoads` is set correctly for your environment

3. **Certificate Errors**
   - For development: Add development certificates to trusted anchors
   - For production: Ensure proper SSL certificates are installed on servers

### Testing Network Security

```bash
# Test HTTP connectivity (development only)
curl http://localhost:3000/api/test

# Test HTTPS connectivity (production)
curl https://ado-dad.com/api/test
```

## Best Practices

1. **Always use HTTPS in production**
2. **Test both configurations before release**
3. **Keep development and production configs separate**
4. **Document any domain-specific exceptions**
5. **Regularly update security configurations**

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Build Production APK
  run: |
    cp android/app/src/main/res/xml/network_security_config_production.xml \
       android/app/src/main/res/xml/network_security_config.xml
    flutter build apk --release
```

### Fastlane Example
```ruby
lane :build_production do
  # Switch to production configs
  sh "cp ios/Runner/Info.plist.production ios/Runner/Info.plist"
  
  # Build and upload
  build_ios_app(
    scheme: "Runner",
    export_method: "app-store"
  )
end
```
