import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

/// Help & Support (wireframe: docs/ado_dad_wireframes_missing_pages.html
/// → "Help & Support"): searchable accordion topics instead of a wall of text,
/// with a contact card at the bottom.
class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpTopic {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  const _HelpTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

class _HelpState extends State<Help> {
  // TODO: set the real support address before release.
  static const String _supportEmail = '';

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_HelpTopic> _topics = [
    _HelpTopic(
      icon: Icons.rocket_launch_outlined,
      title: 'Getting started',
      subtitle: 'Account, login, OTP & password reset',
      body: 'Creating an account\n'
          '• Tap Sign Up and enter your details (name, phone number, email, password).\n'
          '• Optionally upload a profile picture.\n\n'
          'Logging in\n'
          '• Use your registered phone number or email with password.\n'
          '• You can also use OTP Login.\n'
          '• Forgot your password? Tap Forgot Password to reset.',
    ),
    _HelpTopic(
      icon: Icons.sell_outlined,
      title: 'Posting an ad',
      subtitle: 'Categories, photos & videos, pricing',
      body: '1. Tap the Sell button in the bottom navigation bar.\n'
          '2. Choose a category (Two-Wheeler, Private, Commercial, Property).\n'
          '3. Fill in price, year, description and add photos or short videos — '
          'clear images help your ad sell faster.\n'
          '4. Tap Create Advertisement.\n\n'
          'Adding a location helps buyers nearby find your ad faster.',
    ),
    _HelpTopic(
      icon: Icons.search_outlined,
      title: 'Browsing & searching',
      subtitle: 'Categories, filters, keyword search',
      body: '• Explore categories on Home.\n'
          '• Use filters (price, year, brand, fuel type, etc.).\n'
          '• Search using text keywords like "Honda City 2020" or "2BHK Kochi".\n'
          '• Check the Showrooms section to browse verified dealers and their inventory.',
    ),
    _HelpTopic(
      icon: Icons.favorite_border,
      title: 'Favorites & chat',
      subtitle: 'Wishlist, offers, messaging sellers',
      body: 'Favorites (Wishlist)\n'
          '• Tap the heart on any ad to save it; view saved ads under Wishlist; '
          'tap again to remove.\n\n'
          'Chat & offers\n'
          '• Tap Chat or Make an Offer on an ad details page.\n'
          '• All chats appear under Messages when you tap the chat icon in the '
          'bottom navigation bar.\n'
          '• Tap a seller\'s name on an ad to see their profile, other listings '
          'and contact options.',
    ),
    _HelpTopic(
      icon: Icons.flag_outlined,
      title: 'Safety & reporting',
      subtitle: 'Report ads, privacy, secure uploads',
      body: 'Reporting an advertisement\n'
          '• Tap Report Ad on any ad → select a reason → submit. Our team '
          'reviews reported ads.\n\n'
          'Security & privacy\n'
          '• All communication is HTTPS-encrypted.\n'
          '• File uploads use secure presigned URLs.',
    ),
    _HelpTopic(
      icon: Icons.settings_outlined,
      title: 'Account & settings',
      subtitle: 'Profile, password, My Ads, appearance',
      body: 'Profile\n'
          '• View or edit your profile from the Profile screen — update name, '
          'phone or profile picture anytime.\n'
          '• Change password or delete your account from Profile.\n\n'
          'My Ads\n'
          '• View, edit or delete your ads; sort and filter your listings easily.\n\n'
          'Troubleshooting\n'
          '• Check your internet connection — the app detects when you\'re '
          'offline and refreshes automatically when you reconnect.\n'
          '• Restart or reinstall the app if needed.',
    ),
  ];

  List<_HelpTopic> get _filteredTopics {
    if (_query.trim().isEmpty) return _topics;
    final q = _query.toLowerCase();
    return _topics
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.subtitle.toLowerCase().contains(q) ||
            t.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _contactSupport() async {
    if (_supportEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Support contact will be available soon.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = GetResponsiveSize.getResponsivePadding(
      context,
      mobile: 16,
      tablet: 20,
      largeTablet: 24,
      desktop: 28,
    );
    final topics = _filteredTopics;

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
      body: ListView(
        padding: EdgeInsets.all(pad),
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: GoogleFonts.poppins(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 13.5,
                tablet: 16,
                largeTablet: 18,
                desktop: 20,
              ),
              color: AppColors.blackColor,
            ),
            decoration: InputDecoration(
              hintText: 'Search help topics…',
              hintStyle: GoogleFonts.poppins(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 13.5,
                  tablet: 16,
                  largeTablet: 18,
                  desktop: 20,
                ),
                color: AppColors.greyColor,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.greyColor),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: AppColors.greyColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide:
                    BorderSide(color: AppColors.greyColor.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                    color: AppColors.primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (topics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 34, color: AppColors.greyColor),
                  const SizedBox(height: 8),
                  Text(
                    'No topics match "$_query"',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.blackColor1,
                    ),
                  ),
                ],
              ),
            )
          else
            ...topics.map(
              (topic) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  border:
                      Border.all(color: AppColors.greyColor.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(topic.icon, color: AppColors.primaryColor),
                    title: Text(
                      topic.title,
                      style: GoogleFonts.poppins(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 13.5,
                          tablet: 16,
                          largeTablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackColor,
                      ),
                    ),
                    subtitle: Text(
                      topic.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 11,
                          tablet: 13,
                          largeTablet: 14,
                          desktop: 15,
                        ),
                        color: AppColors.greyColor,
                      ),
                    ),
                    iconColor: AppColors.greyColor,
                    collapsedIconColor: AppColors.greyColor,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          topic.body,
                          style: GoogleFonts.poppins(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              largeTablet: 15,
                              desktop: 16,
                            ),
                            height: 1.6,
                            color: AppColors.blackColor1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 4),
          // Contact support
          OutlinedButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.mail_outline,
                size: 17, color: AppColors.primaryColor),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.greyColor.withOpacity(0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            label: Text(
              'Contact support',
              style: GoogleFonts.poppins(
                color: AppColors.blackColor,
                fontWeight: FontWeight.w500,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 13.5,
                  tablet: 16,
                  largeTablet: 18,
                  desktop: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
