import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/profile/MyAds/ui/my_ads_page.dart';
import 'package:ado_dad_user/features/profile/wishlist/wishlist_page.dart';
import 'package:flutter/material.dart';

/// "My Activity" hub — a segmented view over the user's own listings (My Ads)
/// and saved listings (Wishlist). Drafts are intentionally omitted for now.
/// Hosts the existing pages in their embedded form (no inner app bars).
class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  int _tab = 0; // 0 = My Ads, 1 = Wishlist

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'My Activity',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.blackColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFEDEAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _segment('My Ads', 0),
                  _segment('Wishlist', 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                MyAdsPage(embedded: true),
                WishlistPage(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.greyColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
