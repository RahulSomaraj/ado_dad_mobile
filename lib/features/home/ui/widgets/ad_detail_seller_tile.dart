import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/seller_stats.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_card_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdDetailSellerTile extends StatefulWidget {
  final AddModel ad;

  const AdDetailSellerTile({super.key, required this.ad});

  @override
  State<AdDetailSellerTile> createState() => _AdDetailSellerTileState();
}

class _AdDetailSellerTileState extends State<AdDetailSellerTile> {
  final AddRepository _repo = AddRepository();
  SellerStats? _stats;

  AddModel get ad => widget.ad;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final sellerId = ad.user?.id;
    if (sellerId == null || sellerId.isEmpty) return;
    final stats = await _repo.fetchSellerStats(sellerId);
    if (mounted && stats != null) {
      setState(() => _stats = stats);
    }
  }

  String _maskPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    final visible = digitsOnly.length >= 3
        ? digitsOnly.substring(digitsOnly.length - 3)
        : digitsOnly;
    return '+ **  *******$visible';
  }

  /// Compact trust-signals line: ⭐ rating · replies in ~5m · N ads · member-since.
  /// Each piece is omitted when its data isn't available yet.
  Widget? _trustRow(BuildContext context) {
    final s = _stats;
    if (s == null) return null;

    final fontSize = GetResponsiveSize.getResponsiveFontSize(context,
        mobile: 13, tablet: 19, largeTablet: 23, desktop: 27);
    final iconSize = GetResponsiveSize.getResponsiveSize(context,
        mobile: 14, tablet: 18, largeTablet: 22, desktop: 26);
    final color = Colors.grey.shade700;

    final parts = <Widget>[];

    if (s.rating != null && s.rating! > 0) {
      parts.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: iconSize, color: const Color(0xFFF5A623)),
          const SizedBox(width: 2),
          Text(s.rating!.toStringAsFixed(1),
              style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600)),
        ],
      ));
    }

    final reply = s.replyLabel;
    if (reply != null) {
      parts.add(Text(reply,
          style: TextStyle(fontSize: fontSize, color: color)));
    }

    if (s.adCount > 0) {
      parts.add(Text('${s.adCount} ${s.adCount == 1 ? 'ad' : 'ads'}',
          style: TextStyle(fontSize: fontSize, color: color)));
    }

    final member = s.memberSinceLabel;
    if (member != null) {
      parts.add(Text(member,
          style: TextStyle(fontSize: fontSize, color: color)));
    }

    if (parts.isEmpty) return null;

    // Interleave with " · " separators.
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(Text('  ·  ',
            style: TextStyle(fontSize: fontSize, color: color)));
      }
      children.add(parts[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trust = _trustRow(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        0,
      ),
      child: AdDetailCardShell(
       