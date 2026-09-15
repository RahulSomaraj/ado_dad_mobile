import 'dart:async';

import 'package:animations/animations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/sell_flow_cubit.dart';
import '../bloc/sell_media_cubit.dart';
import '../data/sell_draft_store.dart';
import '../data/sell_repository.dart';
import '../domain/sell_category.dart';
import '../domain/sell_config.dart';
import '../domain/sell_format.dart';
import '../domain/sell_models.dart';
import 'sell_start.dart';
import 'steps/details_step.dart';
import 'steps/photos_step.dart';
import 'steps/price_place_step.dart';
import 'steps/review_step.dart';
import 'submitted_page.dart';
import 'widgets/sell_ui.dart';

/// Route `/sell/:category` (`?draft=<id>` resumes). Loads the cached config
/// and the draft, then hands over to [SellFlowPage].
class SellFlowRoute extends StatefulWidget {
  const SellFlowRoute({super.key, required this.category, this.draftId});
  final SellCategory category;
  final String? draftId;

  @override
  State<SellFlowRoute> createState() => _SellFlowRouteState();
}

class _SellFlowRouteState extends State<SellFlowRoute> {
  late final Future<(SellConfig, SellDraft?)> _boot = _load();

  Future<(SellConfig, SellDraft?)> _load() async {
    final config = await SellRepository.cachedConfig(widget.category);
    SellDraft? draft;
    if (widget.draftId != null) {
      draft = await SellDraftStore.instance.load(widget.draftId!);
      if (draft != null && draft.category != widget.category) draft = null;
    }
    return (config, draft);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(SellConfig, SellDraft?)>(
      future: _boot,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: SellTokens.bg,
            body: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        final (config, draft) = snap.data!;
        return SellFlowPage(category: widget.category, config: config, draft: draft);
      },
    );
  }
}

class SellFlowPage extends StatefulWidget {
  const SellFlowPage({super.key, required this.category, required this.config, this.draft});
  final SellCategory category;
  final SellConfig config;
  final SellDraft? draft;

  @override
  State<SellFlowPage> createState() => _SellFlowPageState();
}

class _SellFlowPageState extends State<SellFlowPage> {
  final SellRepository _repo = SellRepository();
  late final SellMediaCubit _media;
  late final SellFlowCubit _flow;
  StreamSubscription<List<ConnectivityResult>>? _net;
  bool _leaving = false;
  bool _reauthShown = false;

  @override
  void initState() {
    super.initState();
    final draftId = widget.draft?.id ?? 'd${DateTime.now().millisecondsSinceEpoch}';
    late final SellFlowCubit flow;
    _media = SellMediaCubit(
      draftId: draftId,
      maxPhotos: widget.config.limits.maxPhotos,
      onChanged: () => flow.mediaChanged(),
    );
    flow = SellFlowCubit(
      category: widget.category,
      initialConfig: widget.config,
      draft: widget.draft,
      draftId: draftId,
      repository: _repo,
      mediaSnapshot: () => _media.state.items,
    );
    _flow = flow;
    if (widget.draft != null) _media.seed(widget.draft!.media);
    _flow.loadConfig().then((_) {
      if (mounted) _media.setMaxPhotos(_flow.state.config.limits.maxPhotos);
    });
    _watchNetwork();
  }

  Future<void> _watchNetwork() async {
    bool online(List<ConnectivityResult> r) => r.isEmpty || r.any((x) => x != ConnectivityResult.none);
    try {
      final now = await Connectivity().checkConnectivity();
      _apply(online(now));
    } catch (_) {}
    if (!mounted) return;
    _net = Connectivity().onConnectivityChanged.listen((r) => _apply(online(r)));
  }

  void _apply(bool online) {
    if (!mounted) return;
    _flow.setOnline(online);
    _media.setOnline(online);
    if (online && _flow.state.config.isFallback) {
      _flow.loadConfig().then((_) {
        if (mounted) _media.setMaxPhotos(_flow.state.config.limits.maxPhotos);
      });
    }
  }

  @override
  void dispose() {
    _net?.cancel();
    _flow.close();
    _media.close();
    super.dispose();
  }

  // ------------------------------------------------------------ navigation

  Future<void> _handleBack() async {
    if (_flow.state.isPosting || _leaving) return;
    FocusScope.of(context).unfocus();
    if (_flow.back()) return;
    await _leave();
  }

  Future<void> _leave() async {
    if (!_flow.hasContent) {
      await _flow.discard();
      _exit();
      return;
    }
    final choice = await showLeaveSheet(context);
    if (!mounted) return;
    if (choice == 'save') {
      await _flow.saveNow();
      _exit();
    } else if (choice == 'discard') {
      await _flow.discard();
      _exit();
    }
  }

  void _exit() {
    if (!mounted) return;
    _leaving = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    _flow.next();
  }

  Future<void> _onPost() async {
    FocusScope.of(context).unfocus();
    await _flow.submit();
  }

  void _onFlowState(BuildContext context, SellFlowState s) {
    final f = s.failure;
    if (s.submission == SubmissionStatus.failed &&
        f is ValidationFailure &&
        f.fields.containsKey(SellKeys.photos)) {
      // Expired or already-attached media: send every file again.
      _media.reuploadAll();
    }
    if (s.submission == SubmissionStatus.succeeded && s.created != null) {
      final cover = _media.state.photos.isEmpty ? null : _media.state.photos.first;
      _leaving = true;
      context.go(
        '/sell/submitted/${s.created!.id}',
        extra: SubmittedInfo(
          price: ReviewStep.priceLabel(s.values, s.category),
          title: ReviewStep.titleLabel(s.values, s.category),
          subtitle: ReviewStep.subtitleLabel(s.values, s),
          localPath: cover?.localPath,
          coverUrl: cover?.url,
          status: s.created!.status,
          categorySlug: s.category.slug,
        ),
      );
      return;
    }
    if (s.submission == SubmissionStatus.failed && s.failure is AuthFailure && !_reauthShown) {
      _reauthShown = true;
      showReauthSheet(context, resumeLocation: '/sell/${s.category.slug}?draft=${s.draftId}')
          .whenComplete(() => _reauthShown = false);
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SellFlowCubit>.value(value: _flow),
        BlocProvider<SellMediaCubit>.value(value: _media),
      ],
      child: BlocListener<SellFlowCubit, SellFlowState>(
        listenWhen: (a, b) => a.submission != b.submission,
        listener: _onFlowState,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack();
          },
          child: BlocBuilder<SellFlowCubit, SellFlowState>(
            buildWhen: (a, b) =>
                a.step != b.step ||
                a.online != b.online ||
                a.savedAt != b.savedAt ||
                a.restoredFrom != b.restoredFrom ||
                a.isPosting != b.isPosting ||
                a.submission != b.submission ||
                a.returnToReview != b.returnToReview,
            builder: (context, s) {
              return Scaffold(
                backgroundColor: SellTokens.bg,
                resizeToAvoidBottomInset: true,
                body: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(state: s, onBack: _handleBack),
                      if (!s.online)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(SellTokens.gutter, 0, SellTokens.gutter, 8),
                          child: SellBanner(
                            kind: SellBannerKind.warn,
                            icon: Icons.wifi_off_rounded,
                            title: 'You’re offline.',
                            body: 'Keep going. Photos will upload when you’re back.',
                          ),
                        ),
                      _StepHeader(state: s),
                      if (s.restoredFrom != null && widget.draft != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 0, SellTokens.gutter, 8),
                          child: BlocBuilder<SellMediaCubit, SellMediaState>(
                            builder: (context, m) => SellBanner(
                              kind: SellBannerKind.ok,
                              icon: Icons.history_rounded,
                              title: 'Welcome back.',
                              body: 'We restored your ${s.category.noun} from ${SellFormat.ago(s.restoredFrom!)}.'
                                  '${m.uploadingCount > 0 ? ' ${m.uploadingCount} photo${m.uploadingCount == 1 ? ' is' : 's are'} re-uploading.' : ''}',
                            ),
                          ),
                        ),
                      Expanded(
                        child: PageTransitionSwitcher(
                          duration: SellTokens.reduceMotion(context) ? Duration.zero : SellTokens.step,
                          reverse: false,
                          transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
                            animation: primary,
                            secondaryAnimation: secondary,
                            transitionType: SharedAxisTransitionType.horizontal,
                            fillColor: SellTokens.bg,
                            child: child,
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(s.step),
                            child: switch (s.step) {
                              SellStep.photos => const PhotosStep(),
                              SellStep.details => DetailsStep(repository: _repo),
                              SellStep.pricePlace => const PricePlaceStep(),
                              SellStep.review => const ReviewStep(),
                            },
                          ),
                        ),
                      ),
                      _ActionBar(onBack: _handleBack, onNext: _onNext, onPost: _onPost),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.onBack});
  final SellFlowState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final first = state.stepIndex == 0 && !state.returnToReview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, SellTokens.gutter, 4),
      child: Row(
        children: [
          Opacity(
            opacity: state.isPosting ? 0.4 : 1,
            child: IconButton(
              tooltip: first ? 'Close' : 'Back',
              onPressed: state.isPosting ? null : onBack,
              style: IconButton.styleFrom(
                backgroundColor: SellTokens.surface,
                side: BorderSide(color: SellTokens.line),
                minimumSize: const Size(40, 40),
              ),
              icon: Icon(first ? Icons.close_rounded : Icons.arrow_back_rounded, size: 20, color: SellTokens.ink),
            ),
          ),
          const Spacer(),
          if (state.savedAt != null)
            Semantics(
              liveRegion: true,
              child: Text(
                state.online ? '✓ Saved' : '✓ Saved on phone',
                style: SellTokens.caption.copyWith(color: SellTokens.okText, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.state});
  final SellFlowState state;

  @override
  Widget build(BuildContext context) {
    final i = state.stepIndex;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SellTokens.gutter, 2, SellTokens.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: 'Step ${i + 1} of 4, ${state.step.titleFor(state.category)}',
            excludeSemantics: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Step ${i + 1} of 4 · ${state.step.titleFor(state.category)}',
                    style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                BlocBuilder<SellMediaCubit, SellMediaState>(
                  builder: (context, m) => Text(
                    i == 0 || m.photoCount == 0
                        ? state.category.label
                        : '${m.photoCount} photo${m.photoCount == 1 ? '' : 's'}${m.allDone ? ' ✓' : ''}',
                    style: SellTokens.caption.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var k = 0; k < 4; k++) ...[
                if (k > 0) const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: SellTokens.track),
                          AnimatedFractionallySizedBox(
                            duration: SellTokens.step,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.centerLeft,
                            widthFactor: k < i ? 1 : (k == i ? (i == 3 ? 1 : 0.5) : 0),
                            child: ColoredBox(color: SellTokens.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onBack, required this.onNext, required this.onPost});
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SellFlowCubit>().state;
    final m = context.watch<SellMediaCubit>().state;
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    Widget content;
    switch (s.step) {
      case SellStep.photos:
        content = Row(
          children: [
            Expanded(child: Text(m.photoCount == 0 ? 'No photos yet' : SellMediaCubit.summary(m), style: SellTokens.caption)),
            SellButton(label: s.returnToReview ? 'Back to review' : 'Next', expand: false, onPressed: onNext),
          ],
        );
        break;
      case SellStep.details:
      case SellStep.pricePlace:
        final count = s.errors.length;
        content = Row(
          children: [
            if (count > 0)
              Expanded(
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onNext,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        count == 1 ? '1 field needs attention ↑' : '$count fields need attention ↑',
                        style: SellTokens.label.copyWith(color: SellTokens.errorText, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              SellButton(label: 'Back', kind: SellButtonKind.ghost, expand: false, onPressed: onBack),
              const Spacer(),
            ],
            SellButton(
              label: s.returnToReview
                  ? 'Back to review'
                  : s.step == SellStep.pricePlace
                      ? 'Review ad'
                      : 'Next',
              expand: false,
              kind: SellButtonKind.primary,
              onPressed: onNext,
            ),
          ],
        );
        break;
      case SellStep.review:
        final uploading = m.items.where((i) => !i.isDone).length;
        String? reason;
        if (!s.online) {
          reason = 'Posting needs a connection';
        } else if (uploading > 0) {
          reason = m.failedCount > 0
              ? '${m.failedCount} photo${m.failedCount == 1 ? '' : 's'} failed. Retry or remove in Photos'
              : 'Waiting for $uploading file${uploading == 1 ? '' : 's'} to upload';
        }
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.submission == SubmissionStatus.slow)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: SellBanner(
                  kind: SellBannerKind.warn,
                  icon: Icons.hourglass_top_rounded,
                  title: 'Still posting. Your network is slow.',
                  body: 'Keep the app open. Tapping again won’t create a duplicate.',
                ),
              ),
            SellButton(
              label: s.isPosting ? 'Posting…' : s.submission == SubmissionStatus.failed ? 'Try again' : 'Post ad',
              busy: s.isPosting,
              onPressed: reason == null && !s.isPosting ? onPost : null,
            ),
            if (reason != null) ...[
              const SizedBox(height: 6),
              Text(reason, textAlign: TextAlign.center, style: SellTokens.caption),
            ],
          ],
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: SellTokens.surface,
        border: Border(top: BorderSide(color: SellTokens.line)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.fromLTRB(SellTokens.gutter, 10, SellTokens.gutter, 10 + (keyboardOpen ? 0 : bottom)),
      child: content,
    );
  }
}
