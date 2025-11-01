import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:google_fonts/google_fonts.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    const helpText = '''
ADO-DAD User App — Help & Support

Welcome to ADO-DAD, your trusted marketplace for buying and selling vehicles and properties.

1. Getting Started

Creating an Account
- Tap Sign Up and enter your details (name, phone number, email, password).
- Optionally upload a profile picture.

Logging In
- Use your registered phone number or email with password.
- You can also use OTP Login.
- Forgot your password? Tap Forgot Password to reset.

2. Managing Your Profile
- View or edit your profile from the Profile screen.
- Update name, phone, or profile picture anytime.
- Change password in Profile.
- Delete account from Profile  → Delete Account.

3. Posting an Advertisement
1. Tap "Sell" button in bottom navigation bar.
2. Choose category (Two-Wheeler, Private, Commercial, Property).
3. Fill in price, year, description, photos/videos etc.
4. Tap "Create Advertisement".

4. Browsing & Searching
- Explore categories on Home.
- Use filters (price, year, brand, fuel type, etc.).
- Search using text keywords like "Honda City 2020" or "2BHK Kochi".

5. Favorites (Wishlist)
- Tap ❤️ on any ad to save it.
- View all saved ads under Wishlist.
- Tap again to remove.

6. Chat with Sellers
- Tap "Chat/Make an Offer" on an ad details page.
- Real-time messaging powered by Socket.IO.
- All chats appear under "Messages / Chat Rooms" when tap "chat" icon in bottom navigation bar.

7. Viewing Seller Profiles
- Tap seller name on an ad details page.
- See their profile, other listings, and contact options.

8. Showroom Listings
- Browse verified dealers in the Showrooms section.
- View their inventory or start a chat.

9. Reporting an Advertisement
- Tap "Report Ad" on any ad → Select reason → Submit.
- Our team reviews reported ads.

10. Uploading Photos & Videos
- Upload clear images and short videos.
- Files are securely stored on cloud.

11. Location & Maps
- Buyers nearby can find your ad faster.

12. My Ads Management
- View, edit, or delete your ads.
- Sort or filter your listings easily.

13. Home Screen Banners
- See new offers and promotions.

14. App Settings
- Change password,logout,delete account etc.

15. Security & Privacy
- All communication is HTTPS-encrypted.
- File uploads use secure presigned URLs.


16. Internet Connectivity
- The app detects when you're offline.
- Listings refresh automatically when you reconnect.

17. Troubleshooting
- Check your internet connection.
- Ensure photos/videos are uploaded properly.
- Restart or reinstall the app if needed.


''';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            color: Colors.white,
          ),
          iconSize: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 28,
            tablet: 32,
            largeTablet: 36,
            desktop: 40,
          ),
        ),
        title: Text(
          'Help & Support',
          textAlign: TextAlign.left,
          style: GoogleFonts.poppins(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 24,
              largeTablet: 26,
              desktop: 28,
            ),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 16,
            tablet: 20,
            largeTablet: 24,
            desktop: 28,
          ),
        ),
        child: SelectableText(
          helpText,
          style: GoogleFonts.poppins(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              largeTablet: 15,
              desktop: 16,
            ),
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
