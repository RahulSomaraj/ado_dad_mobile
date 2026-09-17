import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../data/sell_repository.dart';
import 'widgets/sell_ui.dart';
import 'package:ado_dad_user/services/review_prompt_service.dart';

/// What the success page shows before (or without) a network round trip.
class SubmittedInfo {
  final String price;
  final String title;
  final String? subtitle;
  final String? localPath;
  final String? coverUrl;
  final String status;
  final String categorySlug;

  const SubmittedInfo({
    required this.price,
    required this.title,
    this.subtitle,
    this.localPath,
    this.coverUrl,
    this.status = 'pending',
    this.categorySlug = '',
  });
}

/// W10 — `/sell/submitted/:adId`.
class SubmittedPage extends StatefulWidget {
  const SubmittedPage({super.key, required this.adId, this.info});
  final String adId;
  final SubmittedInfo? info;

  @override
  State<SubmittedPage> createState() => _SubmittedPageState();
}

class _SubmittedPageState extends State<SubmittedPage> with SingleTickerProviderStateMixin {
  late final AnimationController _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (widget.info?.status == 'approved') {
      unawaited(ReviewPromptService.instance.maybeAsk(ReviewTrigger.adLive));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SellTokens.reduceMotion(context)) {
      _check.value = 1;
    } else if (!_check.isAnimating && _check.value == 0) {
      _check.forward();
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  Future<void> _viewAd() async {
    setState(() => _opening = true);
    try {
      final ad = await SellRepository().fetchAd(widget.adId);
      if (!mounted) return;
      final router = GoRouter.of(context);
      router.go('/home');
      WidgetsBinding.instance.addPostFrameCallback((_) => router.push('/add-detail-page', extra: ad));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t open the ad yet. Find it in My ads.'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _share() async {
    final info = widget.info;
    final text = StringBuffer()
      ..writeln(info == null ? 'My ad on Adodad' : '${info.title} — ${info.price}')
      ..writeln('See it on Adodad: https://adodad.com/');
    await SharePlus.instance.share(ShareParams(text: text.toString(), subject: info?.title ?? 'My ad on Adodad'));
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final live = info?.status == 'approved';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: SellTokens.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.go('/home'),
                    style: IconButton.styleFrom(backgroundColor: SellTokens.surface, side: BorderSide(color: SellTokens.line)),
                    icon: Icon(Icons.close_rounded, color: SellTokens.ink, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 8, SellTokens.gutter, 24),
                  children: [
                    Center(
                      child: ScaleTransition(
                        scale: CurvedAnimation(parent: _check, curve: Curves.easeOutBack),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: SellTokens.okBg, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: SellTokens.okFg, size: 38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(live ? 'Your ad is live' : 'Sent for review', textAlign: TextAlign.center, style: SellTokens.display),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      live
                          ? 'Buyers can see it now. Share it to get calls faster.'
                          : 'We check new ads to keep AdoDad safe. You’ll get a notification when yours is live, usually within a few hours.',
                      textAlign: TextAlign.center,
                      style: SellTokens.body.copyWith(color: SellTokens.ink2, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    if (info != null)
                      SellPreviewCard(
                        price: info.price,
                        title: info.title,
                        subtitle: info.subtitle,
                        localPath: info.localPath,
                        url: info.coverUrl,
                        pill: live ? null : 'In review',
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 8, SellTokens.gutter, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SellButton(label: 'View my ad', busy: _opening, onPressed: _viewAd),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: SellButton(label: 'Share', kind: SellButtonKind.tonal, icon: Icons.ios_share_rounded, onPressed: _share)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SellButton(
                            label: 'Post another',
                            kind: SellButtonKind.tonal,
                            onPressed: () {
                              final router = GoRouter.of(context);
                              router.go('/home');
                              WidgetsBinding.instance.addPostFrameCallback((_) => router.push('/sell'));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
