import 'package:flutter/material.dart';

import '../../bloc/sell_flow_cubit.dart';

/// Registers a key per field so "2 fields need attention ↑" and "Fix ›" can
/// scroll the first failing field into view (W05, W09).
class StepScrollKeys {
  final ScrollController controller = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  int _handledTick = -1;

  GlobalKey keyFor(String field) => _keys.putIfAbsent(field, () => GlobalKey(debugLabel: 'sell:$field'));

  Widget wrap(String field, Widget child) => KeyedSubtree(key: keyFor(field), child: child);

  /// Call from build; acts once per [SellFlowState.attentionTick].
  void scrollToFirstError(BuildContext context, SellFlowState state) {
    if (state.attentionTick == _handledTick) return;
    _handledTick = state.attentionTick;
    if (state.errors.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final field in _orderedKeys()) {
        if (!state.errors.containsKey(field)) continue;
        final ctx = _keys[field]?.currentContext;
        if (ctx == null) continue;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: MediaQuery.maybeOf(ctx)?.disableAnimations == true ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        break;
      }
    });
  }

  /// Registration order == on-screen order.
  Iterable<String> _orderedKeys() => _keys.keys;

  /// Called by the step when rebuilt with a fresh tick from outside.
  void reset() => _handledTick = -1;
}
