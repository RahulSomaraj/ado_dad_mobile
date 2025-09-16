# Chat Socket Troubleshooting Guide

## Issue: Socket Connects Successfully Then Immediately Disconnects

### Symptoms
```
[log] ✅ Connected to chat server successfully!
[log] 📡 Socket ID: ZsRDJWYPJvPXNPLAAAIM
[log] 🌐 Connected to: https://uat.ado-dad.com/chat
[log] 🔔 Socket event [connect]: null
[log] Unhandled socket event: connect
[log] ❌ Disconnected from chat server: io server disconnect
[log] 🔔 Socket event [disconnect]: io server disconnect
[log] Unhandled socket event: disconnect
```

### Root Cause Analysis

The "io server disconnect" message indicates that the **server actively disconnected the client** after the initial connection was established. This typically happens due to:

## 🔍 **Most Common Causes:**

### 1. **JWT Token Issues** (Most Likely)
- **Token Expired**: JWT token has passed its expiration time
- **Invalid Token Format**: Token is malformed or corrupted
- **Wrong Token**: Using a token from a different environment
- **Missing Claims**: Token doesn't contain required claims for chat access

### 2. **Authentication/Authorization Issues**
- **User Not Authorized**: User doesn't have permission to access chat namespace
- **Invalid User Role**: User role doesn't allow chat functionality
- **Account Status**: User account is suspended or inactive

### 3. **Server-Side Issues**
- **Chat Service Down**: Chat namespace service is not running
- **Rate Limiting**: Too many connection attempts
- **Server Configuration**: Chat namespace not properly configured
- **Database Issues**: User data not accessible

### 4. **Network/Infrastructure Issues**
- **Load Balancer**: Load balancer dropping connections
- **Firewall**: Network firewall blocking persistent connections
- **Proxy Issues**: Reverse proxy not handling WebSocket properly

## 🛠️ **Debugging Steps**

### Step 1: Check JWT Token
The enhanced logging now shows detailed token information:

```
🔍 JWT Token Validation:
✅ JWT format is valid (3 parts)
📋 JWT Header: {"alg":"HS256","typ":"JWT"}
📄 JWT Payload: {"sub":"user123","exp":1234567890,"iss":"your-app"}
⏰ Token expires: 2024-01-15 10:30:00.000
🕐 Current time: 2024-01-15 11:00:00.000
❌ Token is EXPIRED!
```

**Check for:**
- Token expiration time
- Valid user ID in subject
- Correct issuer
- Required claims present

### Step 2: Verify Server Configuration
Ensure your Socket.IO server is properly configured:

```javascript
// Server-side chat namespace setup
io.of('/chat')
  .use((socket, next) => {
    // JWT authentication middleware
    const token = socket.handshake.auth.token;
    if (!token || !token.startsWith('Bearer ')) {
      return next(new Error('Authentication error'));
    }
    
    // Verify JWT token
    const jwt = token.replace('Bearer ', '');
    try {
      const decoded = jwt.verify(jwt, process.env.JWT_SECRET);
      socket.userId = decoded.sub;
      next();
    } catch (error) {
      next(new Error('Invalid token'));
    }
  })
  .on('connection', (socket) => {
    console.log(`User ${socket.userId} connected to chat`);
    // Handle chat events
  });
```

### Step 3: Test with Different Scenarios

1. **Fresh Token**: Get a new JWT token and test
2. **Different User**: Test with a different user account
3. **Direct Connection**: Test connecting to the main namespace first
4. **Network Test**: Test from different network

### Step 4: Server-Side Logging
Add server-side logging to see what's happening:

```javascript
io.of('/chat')
  .on('connection', (socket) => {
    console.log('✅ Chat connection established:', socket.id);
    console.log('👤 User ID:', socket.userId);
    
    socket.on('disconnect', (reason) => {
      console.log('❌ Chat disconnect:', socket.id, reason);
    });
  });
```

## 🔧 **Solutions**

### Solution 1: Fix JWT Token
```dart
// Get fresh token
final newToken = await refreshToken();
if (newToken != null) {
  await SharedPrefs().setString('token', newToken);
  // Reconnect with new token
  await socketService.reconnect();
}
```

### Solution 2: Add Token Refresh Logic
```dart
// In socket service
if (reason == 'io server disconnect') {
  // Check if token is expired
  if (TokenValidator.isTokenLikelyExpired(token)) {
    log('🔄 Token expired, attempting refresh...');
    await _refreshTokenAndReconnect();
  }
}
```

### Solution 3: Implement Retry with Backoff
```dart
// Add exponential backoff for reconnection
Future<void> _reconnectWithBackoff() async {
  for (int attempt = 1; attempt <= 5; attempt++) {
    await Future.delayed(Duration(seconds: attempt * 2));
    try {
      await connect();
      if (isConnected) break;
    } catch (e) {
      log('Reconnection attempt $attempt failed: $e');
    }
  }
}
```

### Solution 4: Server-Side Fix
Ensure your server properly handles the chat namespace:

```javascript
// Make sure chat namespace is enabled
const chatNamespace = io.of('/chat');

// Add proper error handling
chatNamespace.on('connection', (socket) => {
  // Don't disconnect immediately
  // Add proper authentication checks
  // Handle errors gracefully
});
```

## 🧪 **Testing Commands**

### Test Token Validity
```dart
// In your test page
TokenValidator.validateToken(await getToken());
```

### Test Connection with Debug Info
```dart
// Navigate to /chat-test route
// Check console for detailed logs
// Monitor connection attempts
```

### Test Different Endpoints
```dart
// Test main namespace first
final mainSocket = IO.io('${Env.baseUrl}');
// Then test chat namespace
final chatSocket = IO.io('${Env.baseUrl}/chat');
```

## 📊 **Monitoring**

### Key Metrics to Watch
- Connection success rate
- Disconnect reasons
- Token expiration times
- Reconnection attempts
- Server response times

### Log Patterns to Monitor
```
✅ Connected to chat server successfully!
❌ Disconnected from chat server: io server disconnect
🔄 Reconnection attempt #1
❌ All reconnection attempts failed
```

## 🚨 **Emergency Fixes**

### Quick Fix 1: Disable Auto-Reconnect
```dart
// Temporarily disable auto-reconnect to prevent loops
.setReconnectionAttempts(0)
```

### Quick Fix 2: Use Polling Only
```dart
// Force polling transport to avoid WebSocket issues
.setTransports(['polling'])
```

### Quick Fix 3: Increase Timeout
```dart
// Give more time for connection
.setTimeout(30000) // 30 seconds
```

## 📞 **Next Steps**

1. **Check the enhanced logs** for JWT token details
2. **Verify server-side chat namespace** is properly configured
3. **Test with a fresh JWT token**
4. **Check server logs** for authentication errors
5. **Verify user permissions** for chat access

The enhanced logging will now show you exactly what's wrong with the JWT token and help identify the root cause of the disconnection.
