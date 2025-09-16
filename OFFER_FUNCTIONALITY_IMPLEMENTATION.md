# Make an Offer Functionality Implementation

## Overview

This document describes the complete implementation of the "Make an Offer" functionality that allows users to send offer messages through chat rooms. The implementation includes a popup interface, socket-based chat room management, and seamless integration with the existing UI.

## 🎯 **Features Implemented**

### ✅ **Core Components**

1. **Offer Popup** (`OfferPopup`)
   - Amount input with validation
   - Real-time message preview
   - Professional UI with loading states
   - Error handling and user feedback

2. **Socket Service Extensions** (`ChatSocketService`)
   - `checkExistingChatRoom()` - Check if chat room exists for an ad
   - `createChatRoom()` - Create new chat room for an ad
   - `joinChatRoom()` - Join a specific chat room
   - `sendMessageToRoom()` - Send message to a chat room
   - `sendOfferMessage()` - Complete offer flow

3. **Chat Bloc Integration** (`ChatBloc`)
   - `SendOffer` event handling
   - Offer state management
   - Error handling and success feedback

4. **Offer Service** (`OfferService`)
   - High-level API for offer functionality
   - Popup management and flow control
   - Success/error dialog handling

5. **UI Components** (`MakeOfferButton`)
   - Reusable offer buttons in different styles
   - Loading states and error handling
   - Easy integration into any page

## 🔄 **Complete Offer Flow**

### **Step 1: User Clicks "Make an Offer"**
```dart
// In any page (e.g., AdDetailPage)
OfferService.showOfferPopup(
  context: context,
  adId: 'ad_123',
  adTitle: '2019 Toyota Corolla',
  adPosterName: 'John Doe',
);
```

### **Step 2: Offer Popup Display**
- User enters offer amount
- Real-time preview: "I will make an offer for an amount ₹15000"
- Validation ensures valid amount input

### **Step 3: Socket Operations (Automatic)**
```dart
// 1. Check for existing chat room
socket.emit('checkExistingChatRoom', { adId: 'ad_123' }, (response) => {
  if (response.exists) {
    // Use existing room
    roomId = response.room.roomId;
  } else {
    // Create new room
    socket.emit('createChatRoom', { adId: 'ad_123' }, (response) => {
      roomId = response.chatRoom.roomId;
    });
  }
});

// 2. Join the room
socket.emit('joinChatRoom', { roomId: roomId }, (response) => {
  // Ready to send messages
});

// 3. Send offer message
socket.emit('sendMessage', {
  roomId: roomId,
  content: 'I will make an offer for an amount ₹15000',
  type: 'offer',
  metadata: {
    amount: '15000',
    adId: 'ad_123',
    adTitle: '2019 Toyota Corolla',
    adPosterName: 'John Doe',
    isNewRoom: false
  }
}, (response) => {
  // Message sent successfully
});
```

### **Step 4: Success/Error Handling**
- Success: "Offer sent successfully!" dialog
- Error: Detailed error message with retry option
- Loading states throughout the process

## 📱 **UI Integration Examples**

### **1. Ad Detail Page Integration**
```dart
// Already integrated in AdDetailPage
void _handleMakeOffer(BuildContext context) {
  final state = context.read<AdDetailBloc>().state;
  state.when(
    loaded: (ad) {
      OfferService.showOfferPopup(
        context: context,
        adId: ad.id,
        adTitle: ad.description,
        adPosterName: ad.user?.name ?? 'Unknown Seller',
      );
    },
    // ... other states
  );
}
```

### **2. Custom Offer Button**
```dart
// Full-width button
MakeOfferButton(
  adId: 'ad_123',
  adTitle: '2019 Toyota Corolla',
  adPosterName: 'John Doe',
  onOfferSent: () {
    // Handle success
  },
)

// Compact button
MakeOfferButtonCompact(
  adId: 'ad_123',
  adTitle: '2019 Toyota Corolla',
  adPosterName: 'John Doe',
)

// Floating action button
MakeOfferFAB(
  adId: 'ad_123',
  adTitle: '2019 Toyota Corolla',
  adPosterName: 'John Doe',
)
```

### **3. Direct Service Usage**
```dart
// Quick offer without popup (for testing)
OfferService.sendQuickOffer(
  context: context,
  adId: 'ad_123',
  amount: '15000',
  adTitle: '2019 Toyota Corolla',
  adPosterName: 'John Doe',
);
```

## 🔧 **Socket Events**

### **Client → Server Events**
```javascript
// Check existing chat room
socket.emit('checkExistingChatRoom', { adId: 'ad_123' }, (response) => {
  // Response: { success: true, exists: true, room: {...} }
});

// Create new chat room
socket.emit('createChatRoom', { adId: 'ad_123' }, (response) => {
  // Response: { success: true, chatRoom: {...} }
});

// Join chat room
socket.emit('joinChatRoom', { roomId: 'room_123' }, (response) => {
  // Response: { success: true, userRole: 'participant' }
});

// Send message
socket.emit('sendMessage', {
  roomId: 'room_123',
  content: 'I will make an offer for an amount ₹15000',
  type: 'offer',
  metadata: { amount: '15000', adId: 'ad_123' }
}, (response) => {
  // Response: { success: true, message: {...} }
});
```

### **Server Response Formats**
```json
// Check existing room response
{
  "success": true,
  "exists": true,
  "room": {
    "roomId": "chat_user123_ad456",
    "initiatorId": "user123",
    "adId": "ad456",
    "adPosterId": "user789",
    "participants": ["user123", "user789"],
    "status": "active",
    "lastMessageAt": "2024-01-15T10:30:00.000Z",
    "messageCount": 5,
    "createdAt": "2024-01-15T09:00:00.000Z"
  }
}

// Create room response
{
  "success": true,
  "chatRoom": {
    "roomId": "chat_user123_ad456",
    "initiatorId": "user123",
    "adId": "ad456",
    "adPosterId": "user789",
    "participants": ["user123", "user789"],
    "status": "active",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}

// Send message response
{
  "success": true,
  "message": {
    "id": "msg_123",
    "roomId": "chat_user123_ad456",
    "senderId": "user123",
    "content": "I will make an offer for an amount ₹15000",
    "type": "offer",
    "metadata": {
      "amount": "15000",
      "adId": "ad456",
      "adTitle": "2019 Toyota Corolla",
      "adPosterName": "John Doe",
      "isNewRoom": false
    },
    "timestamp": "2024-01-15T10:30:00.000Z",
    "isRead": false,
    "isDelivered": true
  }
}
```

## 🎨 **UI Components**

### **Offer Popup Features**
- **Amount Input**: Numeric input with validation
- **Real-time Preview**: Shows exact message that will be sent
- **Loading States**: Disabled input during submission
- **Error Handling**: Clear error messages
- **Professional Design**: Consistent with app theme

### **Button Variants**
- **Full Button**: `MakeOfferButton` - Full-width primary button
- **Compact Button**: `MakeOfferButtonCompact` - Smaller outlined button
- **FAB**: `MakeOfferFAB` - Floating action button style

### **State Management**
- **Loading States**: Visual feedback during operations
- **Error States**: Clear error messages and retry options
- **Success States**: Confirmation dialogs and navigation

## 🔍 **Debugging & Logging**

### **Console Logs**
```
🎯 Starting offer flow for ad: ad_123 with amount: 15000
🔍 Checking for existing chat room for ad: ad_123
📨 Received checkExistingChatRoom response: {success: true, exists: false}
🏗️ Creating new chat room for ad: ad_123
📨 Received createChatRoom response: {success: true, chatRoom: {...}}
✅ Created new room: chat_user123_ad456
🚪 Joining chat room: chat_user123_ad456
📨 Received joinChatRoom response: {success: true, userRole: participant}
✅ Joined room: chat_user123_ad456
📤 Sending message to room chat_user123_ad456: I will make an offer for an amount ₹15000
📨 Received sendMessage response: {success: true, message: {...}}
✅ Offer message sent successfully
```

### **Error Handling**
- **Connection Errors**: Automatic retry with exponential backoff
- **Authentication Errors**: Clear error messages with token refresh
- **Validation Errors**: Input validation with helpful messages
- **Server Errors**: Detailed error information from server

## 🚀 **Usage Examples**

### **1. Basic Integration**
```dart
// Add to any page
ElevatedButton(
  onPressed: () {
    OfferService.showOfferPopup(
      context: context,
      adId: 'ad_123',
      adTitle: '2019 Toyota Corolla',
      adPosterName: 'John Doe',
    );
  },
  child: Text('Make an Offer'),
)
```

### **2. With Custom Styling**
```dart
MakeOfferButton(
  adId: ad.id,
  adTitle: ad.description,
  adPosterName: ad.user?.name ?? 'Unknown',
  isLoading: chatBloc.state.isSendingOffer,
)
```

### **3. Error Handling**
```dart
BlocListener<ChatBloc, ChatState>(
  listener: (context, state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    }
    if (state.lastOfferRoomId != null) {
      // Navigate to chat room
      context.push('/chat/${state.lastOfferRoomId}');
    }
  },
  child: MakeOfferButton(...),
)
```

## 🔧 **Configuration**

### **Socket Configuration**
- **Timeout**: 10 seconds for all socket operations
- **Retry**: 3 attempts with 2-second delay
- **Transport**: WebSocket with polling fallback

### **UI Configuration**
- **Validation**: Positive numeric amounts only
- **Loading States**: Disabled inputs during operations
- **Error Display**: Toast messages and dialog boxes

## 📊 **Performance Considerations**

- **Efficient State Management**: Minimal state updates
- **Connection Pooling**: Reuse existing socket connections
- **Memory Management**: Proper cleanup of resources
- **Error Recovery**: Automatic retry mechanisms

## 🧪 **Testing**

### **Test Scenarios**
1. **New Chat Room**: First offer for an ad
2. **Existing Chat Room**: Subsequent offers for the same ad
3. **Network Errors**: Connection failures and timeouts
4. **Invalid Input**: Empty amounts, negative values
5. **Authentication**: Expired tokens and invalid credentials

### **Test Commands**
```dart
// Test with debug logs
OfferService.sendQuickOffer(
  context: context,
  adId: 'test_ad_123',
  amount: '10000',
  adTitle: 'Test Ad',
  adPosterName: 'Test User',
);
```

## 🔮 **Future Enhancements**

1. **Offer History**: Track all offers made by user
2. **Counter Offers**: Allow sellers to respond with counter offers
3. **Offer Expiry**: Time-limited offers
4. **Bulk Offers**: Make offers on multiple ads
5. **Offer Analytics**: Track offer success rates
6. **Push Notifications**: Notify when offers are received/responded to
7. **Offer Templates**: Pre-defined offer messages
8. **Negotiation Flow**: Structured negotiation process

## 📞 **Support**

For issues or questions:
1. Check console logs for detailed error information
2. Verify socket connection status
3. Ensure JWT token is valid
4. Check server-side chat namespace configuration

The implementation provides a complete, production-ready offer system with comprehensive error handling, user feedback, and seamless integration with the existing chat infrastructure.
