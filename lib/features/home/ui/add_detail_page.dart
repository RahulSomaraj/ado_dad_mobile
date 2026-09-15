import 'package:ado_dad_user/common/ad_category.dart';
import 'package:ado_dad_user/common/ad_format.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/phone_number_util.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/features/home/services/chat_service.dart';
import 'package:ado_dad_user/features/home/services/offer_service.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_bars.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_body.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_gallery.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_header.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_section.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_seller.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_specs.dart';
import 'package:ado_dad_user/features/home/ui/ad_detail/ad_detail_states.dart';
import 'package:ado_dad_user/features/home/ui/report_ad_dialog.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ad detail screen.
///
/// One build path for every bloc state: the page always renders the last ad
/// it had (`_lastAd`) and only swaps controls for busy / sold / owner. The
/// sections live in `ui/ad_detail/`; this file owns state and actions.
class AdDetailPage extends StatefulWidget {
  final AddModel ad;
  const AdDetailPage({super.key, required this.ad});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  static const String _loginRedirect = '/add-detail-page';

  late AddModel _lastAd;

  /// Signed-in user id. Read synchronously from the already-initialised
  /// SharedPrefs so owner controls are right on the first frame; confirmed
  /// asynchronously in case prefs weren't ready.
  String? _userId;
  bool _userResolved = false;

  @override
  void initState() {
    super.initState();
    _lastAd = widget.ad;
    _userId = SharedPrefs().getString('user_id');
    _userResolved = _userId != null;
    _confirmUser();
  }

  Future<void> _confirmUser() async {
    final id = await SharedPrefs().getUserId();
    if (!mounted) return;
    if (id != _userId || !_userResolved) {
      setState(() {
        _userId = id;
        _userResolved = true;
      });
    }
  }

  /// null while unknown (reserve space, show no owner/buyer-only controls).
  bool? _isOwner(AddModel ad) {
    final sellerId = ad.user?.id;
    if (_userId != null && sellerId != null && sellerId.isNotEmpty) {
      return _userId == sellerId;
    }
    if (!_userResolved) return null;
    if (_userId == null) return false; // signed out → always a buyer
    // Signed in but the seeded list row has no seller yet: wait for the
    // detail response rather than flashing buyer controls at the owner.
    if (identical(ad, widget.ad)) return null;
    return false;
  }

  // ------------------------------------------------------------------ helpers

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '').trim();
    return msg.isEmpty ? 'Something went wrong. Try again.' : msg;
  }

  Future<bool> _requireLogin(String message) async {
    final ok = await AuthGuard.isAuthenticated();
    if (!ok && mounted) {
      DialogUtil.showLoginPromptDialog(
        context,
        message: message,
        redirectPath: _loginRedirect,
      );
    }
    return ok;
  }

  bool _ensureSeller(AddModel ad) {
    final sellerId = ad.user?.id;
    if (sellerId == null || sellerId.isEmpty) {
      _snack('Seller details are still loading. Try again in a moment.');
      return false;
    }
    return true;
  }

  String _titleFor(AddModel ad) =>
      AdFormat.clean(ad.title) ?? AdDetailSpecs(ad).fallbackTitle;

  /// After sold / delete: hand `true` back so My Ads / Home refresh.
  void _leaveAfterChange() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/home');
    }
  }

  // ------------------------------------------------------------------ actions

  Future<void> _share(AddModel ad) async {
    if (!await _requireLogin('Log in to share this ad.')) return;
    final title = _titleFor(ad);
    final price = AdFormat.inr(ad.price);
    final text = StringBuffer()
      ..writeln('$title — $price')
      ..writeln(ad.location)
      ..writeln()
      ..writeln('See it on Adodad: https://adodad.com/');
    await SharePlus.instance.share(
      ShareParams(text: text.toString(), subject: '$title on Adodad'),
    );
  }

  Future<void> _chat(AddModel ad) async {
    if (!await _requireLogin('Log in to chat with the seller.')) return;
    if (!mounted || !_ensureSeller(ad)) return;
    ChatService.startDirectChat(
      context: context,
      adId: ad.id,
      adTitle: _titleFor(ad),
      adPosterName: ad.user?.name ?? 'Seller',
      otherUserId: ad.user!.id,
    );
  }

  Future<void> _offer(AddModel ad) async {
    if (!await _requireLogin('Log in to make an offer.')) return;
    if (!mounted || !_ensureSeller(ad)) return;
    OfferService.showOfferPopup(
      context: context,
      adId: ad.id,
      adTitle: _titleFor(ad),
      adPosterName: ad.user?.name ?? 'Seller',
      otherUserId: ad.user!.id,
      adPrice: ad.price,
    );
  }

  Future<void> _call(AddModel ad) async {
    final raw = ad.user?.phone?.trim() ?? '';
    if (raw.isEmpty) {
      _snack('Seller phone number isn\'t available.');
      return;
    }
    // Dial in E.164 so numbers from other countries (and "+91" pasted twice)
    // reach the right line.
    final cc = (ad.user?.countryCode?.trim().isNotEmpty ?? false)
        ? ad.user!.countryCode!.trim()
        : '+91';
    final normalised = PhoneNumberUtil.normalise(raw, cc);
    final number = normalised.isValid ? normalised.e164 : raw;
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (!await launchUrl(uri)) _snack('Couldn\'t open the phone app.');
    } catch (_) {
      _snack('Couldn\'t open the phone app.');
    }
  }

  void _report(AddModel ad) {
    final reportedUserId = ad.user?.id;
    if (reportedUserId == null || reportedUserId.isEmpty) {
      _snack('Seller details are still loading. Try again in a moment.');
      return;
    }
    ReportAdDialog.show(context, reportedUserId: reportedUserId, adId: ad.id);
  }

  Future<void> _edit(AddModel ad) async {
    if (!await _requireLogin('Log in to edit this ad.')) return;
    if (!mounted) return;
    final route = AdCategory.fromApi(ad.category).editRoute;
    if (route == null) {
      _snack('This ad can\'t be edited from the app.');
      return;
    }
    final bloc = context.read<AdDetailBloc>();
    final changed = await context.push<bool>(route, extra: ad);
    if (!mounted) return;
    if (changed == true) bloc.add(AdDetailEvent.fetch(ad.id));
  }

  Future<void> _markSold(AddModel ad) async {
    if (!await _requireLogin('Log in to mark this ad as sold.')) return;
    if (!mounted) return;
    final bloc = context.read<AdDetailBloc>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet16)),
      ),
      builder: (sheetContext) => _ConfirmSheet(
        title: 'Mark this ad as sold?',
        body: 'It will be removed from search and buyers won\'t be able to '
            'contact you about it. This can\'t be undone.',
        confirmLabel: 'Mark as sold',
      ),
    );
    if (confirmed == true) bloc.add(AdDetailEvent.markAsSold(ad.id));
  }

  Future<void> _delete(AddModel ad) async {
    final bloc = context.read<AdDetailBloc>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet16)),
      ),
      builder: (sheetContext) => _ConfirmSheet(
        title: 'Delete this ad?',
        body: 'The ad, its photos and its chats will be removed. '
            'This can\'t be undone.',
        confirmLabel: 'Delete ad',
        destructive: true,
      ),
    );
    if (confirmed == true) bloc.add(AdDetailEvent.deleteAd(ad.id));
  }

  Future<void> _refresh(AddModel ad) async {
    final bloc = context.read<AdDetailBloc>();
    bloc.add(AdDetailEvent.fetch(ad.id));
    try {
      await bloc.stream.first.timeout(const Duration(seconds: 12));
    } catch (_) {
      // Timeout: the indicator just stops; the listener reports real errors.
    }
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdDetailBloc, AdDetailState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          loaded: (ad) {},
          error: (e) {
            _snack(_friendlyError(e));
          },
          markingAsSold: () {},
          markedAsSold: (ad) {
            _snack('Marked as sold.');
            _leaveAfterChange();
          },
          deleting: () {},
          deleted: () {
            _snack('Ad deleted.');
            _leaveAfterChange();
          },
        );
      },
      builder: (context, state) {
        // Every state resolves to "which ad to show" + "is an action running".
        var busy = false;
        var coldError = false;
        var coldLoading = false;
        state.when(
          initial: () {
            coldLoading = true;
          },
          loading: () {
            coldLoading = true;
          },
          loaded: (ad) {
            _lastAd = ad;
          },
          error: (_) {
            coldError = true;
          },
          markingAsSold: () {
            busy = true;
          },
          markedAsSold: (ad) {
            _lastAd = ad;
          },
          deleting: () {
            busy = true;
          },
          deleted: () {
            busy = true;
          },
        );

        // The route always seeds the bloc, so these only show on a deep link
        // that arrives without an ad.
        final hasContent = _lastAd.id.isNotEmpty;
        if (!hasContent && coldLoading) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: const AdDetailSkeleton(),
          );
        }
        if (!hasContent && coldError) {
          return Scaffold(
            backgroundColor: AppColors.whiteColor,
            body: AdDetailErrorView(
              onRetry: () => context
                  .read<AdDetailBloc>()
                  .add(AdDetailEvent.fetch(widget.ad.id)),
            ),
          );
        }

        final ad = _lastAd;
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: _buildBody(ad),
          bottomNavigationBar: _buildBar(ad, busy: busy),
        );
      },
    );
  }

  Widget _buildBody(AddModel ad) {
    final isOwner = _isOwner(ad);
    final specs = AdDetailSpecs(ad);
    final overview = specs.overview;
    final documents = specs.documents;
    final features = specs.features;
    final description = ad.description.trim();
    final isSold = ad.soldOut == true;

    final actions = <Widget>[
      AdDetailOverlayButton(
        icon: Icons.ios_share,
        semanticLabel: 'Share ad',
        onTap: () => _share(ad),
      ),
      if (isOwner == true)
        _OwnerMenuButton(onDelete: () => _delete(ad))
      else if (isOwner == false)
        AdDetailFavoriteOverlayButton(ad: ad),
    ];

    return RefreshIndicator(
      color: AppColors.primaryColor,
      // Below the status bar + overlay controls.
      edgeOffset: MediaQuery.of(context).padding.top + 48,
      onRefresh: () => _refresh(ad),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AdDetailGallery(
              ad: ad,
              actions: actions,
              isOwner: isOwner == true,
              onAddPhotos: isOwner == true ? () => _edit(ad) : null,
            ),
          ),
          if (isSold)
            SliverToBoxAdapter(
              child: AdDetailSoldBanner(isProperty: specs.category.isProperty),
            ),
          SliverToBoxAdapter(
            child: AdDetailHeader(
              ad: ad,
              specs: specs,
              ownerBlock: isOwner == true ? AdDetailOwnerBlock(ad: ad) : null,
            ),
          ),
          if (overview.isNotEmpty) ...[
            const SliverToBoxAdapter(child: AdDetailBand()),
            SliverToBoxAdapter(
              child: AdDetailSection(
                title: 'Overview',
                child: AdDetailSpecTable(rows: overview),
              ),
            ),
          ],
          if (documents.isNotEmpty) ...[
            const SliverToBoxAdapter(child: AdDetailBand()),
            SliverToBoxAdapter(
              child: AdDetailSection(
                title: 'Documents',
                child: AdDetailSpecTable(rows: documents),
              ),
            ),
          ],
          if (features.isNotEmpty) ...[
            const SliverToBoxAdapter(child: AdDetailBand()),
            SliverToBoxAdapter(
              child: AdDetailSection(
                title: specs.category.isProperty ? 'Amenities' : 'Features',
                child: AdDetailFeatureChips(features: features),
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SliverToBoxAdapter(child: AdDetailBand()),
            SliverToBoxAdapter(
              child: AdDetailSection(
                title: 'Description',
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s(context, AppSpacing.gutter),
                  AppSpacing.s(context, AppSpacing.lg16),
                  AppSpacing.s(context, AppSpacing.gutter),
                  AppSpacing.md12,
                ),
                child: AdDetailExpandableText(text: description),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: AdDetailFooter(
              ad: ad,
              onReport: isOwner == false ? () => _report(ad) : null,
            ),
          ),
          if (isOwner != true) ...[
            const SliverToBoxAdapter(child: AdDetailBand()),
            SliverToBoxAdapter(child: AdDetailSellerCard(ad: ad)),
            if (!isSold)
              SliverToBoxAdapter(
                child: AdDetailSafetyNote(
                    isProperty: specs.category.isProperty),
              ),
          ],
          SliverToBoxAdapter(child: AdDetailSimilarAds(ad: ad)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl24)),
        ],
      ),
    );
  }

  Widget _buildBar(AddModel ad, {required bool busy}) {
    final isOwner = _isOwner(ad);
    final isSold = ad.soldOut == true;

    if (isOwner == null) {
      // Reserve the bar's height so content doesn't jump when it resolves.
      return Container(
        color: AppColors.whiteColor,
        child: SafeArea(
          top: false,
          child: const SizedBox(height: 48 + AppSpacing.md12 + 14),
        ),
      );
    }
    if (isOwner) {
      return AdDetailOwnerBar(
        busy: busy,
        onEdit: () => _edit(ad),
        onMarkSold: isSold ? null : () => _markSold(ad),
      );
    }
    if (isSold) {
      return AdDetailSoldBar(
        onSeeSimilar: () => context.push('/search?from=ad-detail'),
      );
    }
    final hasPhone = ad.user?.phone?.trim().isNotEmpty ?? false;
    return AdDetailContactBar(
      busy: busy,
      onChat: () => _chat(ad),
      onOffer: () => _offer(ad),
      onCall: hasPhone ? () => _call(ad) : null,
    );
  }
}

/// ⋮ menu on the gallery for the owner. Holds the destructive action so it
/// isn't one tap away in the main flow.
class _OwnerMenuButton extends StatelessWidget {
  const _OwnerMenuButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdDetailOverlayButton(
      semanticLabel: 'More options',
      child: PopupMenuButton<String>(
        tooltip: 'More options',
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control12),
        ),
        onSelected: (value) {
          if (value == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.redColor),
                const SizedBox(width: AppSpacing.md12),
                Text('Delete ad',
                    style: AppTextstyle.bodyText
                        .copyWith(color: AppColors.redColor)),
              ],
            ),
          ),
        ],
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.more_vert, size: 20, color: Color(0xFF0A0A0A)),
        ),
      ),
    );
  }
}

/// Bottom-sheet confirmation used for mark-as-sold and delete.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl24, AppSpacing.xl24, AppSpacing.xl24, AppSpacing.lg16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextstyle.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.sm8),
            Text(body, style: AppTextstyle.bodyText),
            const SizedBox(height: AppSpacing.xl24),
            Row(
              children: [
                Expanded(
                  child: AdDetailBarButton.tonal(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm8),
                Expanded(
                  child: destructive
                      ? ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button12),
                            ),
                          ),
                          child: Text(confirmLabel, style: AppTextstyle.button),
                        )
                      : AdDetailBarButton.filled(
                          label: confirmLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
