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
        child: ListTile(
          leading: Builder(
            builder: (context) {
              final pic = (ad.user?.profilePic ?? '').trim();
              final hasPic = pic.startsWith('http');
              final radius = GetResponsiveSize.getResponsiveSize(context,
                  mobile: 24, tablet: 32, largeTablet: 38, desktop: 44);
              final initial = (ad.user?.name?.trim().isNotEmpty == true)
                  ? ad.user!.name!.trim()[0].toUpperCase()
                  : '?';
              return CircleAvatar(
                radius: radius,
                backgroundColor: const Color(0xFFEDEBFF),
                backgroundImage: hasPic ? NetworkImage(pic) : null,
                child: hasPic
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          color: const Color(0xFF4F48EC),
                          fontWeight: FontWeight.w700,
                          fontSize: radius * 0.8,
                        ),
                      ),
              );
            },
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  ad.user?.name?.trim().isNotEmpty == true
                      ? ad.user!.name!
                      : 'Seller',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ad.user?.isVerified == true) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.verified,
                  color: const Color(0xFF4F48EC),
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trust signals lead — what decides whether to message.
              if (trust != null) trust,
              // Member-since · city on its own line (matches the design).
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _stats?.memberSinceLabel != null
                      ? '${_stats!.memberSinceLabel} · ${ad.location}'
                      : ad.location,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: GetResponsiveSize.getResponsiveSize(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          ),
          onTap: () {
            final sellerId = ad.user?.id;
            if (sellerId != null && sellerId.isNotEmpty && ad.user != null) {
              context.push('/seller-profile/$sellerId', extra: ad.user);
            }
          },
        ),
      ),
    );
  }
}
