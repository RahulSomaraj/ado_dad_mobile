import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/sell_draft_store.dart';
import '../domain/sell_category.dart';
import '../domain/sell_format.dart';
import '../domain/sell_models.dart';
import 'widgets/sell_ui.dart';

/// Entry point used by the nav bar "Sell" button: login check, then W01 sheet.
Future<void> openSell(BuildContext context) async {
  final authed = await AuthGuard.isAuthenticated();
  if (!context.mounted) return;
  if (!authed) {
    DialogUtil.showLoginPromptDialog(context, message: 'Please login to post an ad.', redirectPath: '/sell');
    return;
  }
  await showSellSheet<void>(context, (ctx) => const SingleChildScrollView(child: SellStartContent(inSheet: true)));
}

/// Route `/sell` (deep links, "Post another", old `/seller`). Same content as
/// the sheet on a page.
class SellStartPage extends StatelessWidget {
  const SellStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SellTokens.surface,
      appBar: AppBar(
        backgroundColor: SellTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: Icon(Icons.close_rounded, color: SellTokens.ink),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(child: SellStartContent(inSheet: false)),
        ),
      ),
    );
  }
}

/// W01 — "What are you selling?": drafts first, then four categories.
class SellStartContent extends StatefulWidget {
  const SellStartContent({super.key, required this.inSheet});
  final bool inSheet;

  @override
  State<SellStartContent> createState() => _SellStartContentState();
}

class _SellStartContentState extends State<SellStartContent> {
  List<SellDraft>? _drafts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drafts = await SellDraftStore.instance.all();
    if (mounted) setState(() => _drafts = drafts);
  }

  void _go(String location) {
    final router = GoRouter.of(context);
    if (widget.inSheet) Navigator.of(context).pop();
    if (widget.inSheet) {
      router.push(location);
    } else {
      router.pushReplacement(location);
    }
  }

  Future<void> _discard(SellDraft d) async {
    await SellDraftStore.instance.delete(d.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = _drafts ?? const <SellDraft>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What are you selling?', style: SellTokens.heading),
        const SizedBox(height: 14),
        for (final d in drafts.take(2)) ...[
          _DraftTile(draft: d, onTap: () => _go('/sell/${d.category.slug}?draft=${d.id}'), onDiscard: () => _discard(d)),
          const SizedBox(height: 10),
        ],
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final c in SellCategory.values) _CategoryTile(category: c, onTap: () => _go('/sell/${c.slug}')),
          ],
        ),
        const SizedBox(height: 14),
        Text('Ads are reviewed before they go live', textAlign: TextAlign.center, style: SellTokens.caption),
      ],
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onTap, required this.onDiscard});
  final SellDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final photos = draft.photos;
    final stepNo = SellStep.values.indexOf(draft.step) + 1;
    return Semantics(
      button: true,
      label: 'Continue ${draft.headline}, step $stepNo of 4',
      child: Material(
        color: SellTokens.soft.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SellTokens.rCard),
          side: BorderSide(color: SellTokens.accent.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SellTokens.rCard),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: photos.isEmpty
                        ? Container(color: SellTokens.soft, child: Icon(draft.category.icon, color: SellTokens.accent))
                        : SellPhoto(localPath: photos.first.localPath, url: photos.first.url),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue: ${draft.headline}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Step $stepNo of 4 · saved ${SellFormat.ago(draft.updatedAt)}${photos.isEmpty ? '' : ' · ${photos.length} photo${photos.length == 1 ? '' : 's'}'}',
                        style: SellTokens.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Discard draft',
                  onPressed: onDiscard,
                  icon: Icon(Icons.delete_outline_rounded, color: SellTokens.muted, size: 20),
                ),
                Icon(Icons.chevron_right_rounded, color: SellTokens.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final SellCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${category.label}. ${category.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: SellTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SellTokens.rCard),
          side: BorderSide(color: SellTokens.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SellTokens.rCard),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: SellTokens.soft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(category.icon, color: SellTokens.accent, size: 20),
                ),
                const SizedBox(height: 8),
                Text(category.label, style: SellTokens.label.copyWith(color: SellTokens.ink, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(category.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: SellTokens.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// W11 — returns 'save', 'discard' or null (keep editing).
Future<String?> showLeaveSheet(BuildContext context) {
  return showSellSheet<String>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Save this ad for later?', style: SellTokens.heading),
        const SizedBox(height: 6),
        Text('Your photos and details stay on this phone for 14 days. Continue any time from Sell.',
            style: SellTokens.body.copyWith(color: SellTokens.ink2, fontSize: 14)),
        const SizedBox(height: 16),
        SellButton(label: 'Save and exit', onPressed: () => Navigator.of(ctx).pop('save')),
        const SizedBox(height: 8),
        SellButton(label: 'Keep editing', kind: SellButtonKind.tonal, onPressed: () => Navigator.of(ctx).pop()),
        const SizedBox(height: 8),
        SellButton(label: 'Discard ad', kind: SellButtonKind.danger, onPressed: () => Navigator.of(ctx).pop('discard')),
      ],
    ),
  );
}

/// W14 — session expired while posting. The draft is already saved.
Future<void> showReauthSheet(BuildContext context, {required String resumeLocation}) {
  return showSellSheet<void>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign in again to post', style: SellTokens.heading),
        const SizedBox(height: 6),
        Text('You were signed out for security. Your ad is saved. After you sign in we’ll bring you right back here.',
            style: SellTokens.body.copyWith(color: SellTokens.ink2, fontSize: 14)),
        const SizedBox(height: 16),
        SellButton(
          label: 'Sign in',
          onPressed: () {
            Navigator.of(ctx).pop();
            GoRouter.of(context).go('/login?redirect=${Uri.encodeComponent(resumeLocation)}');
          },
        ),
      ],
    ),
  );
}
