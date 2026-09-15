import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:flutter/material.dart';

/// Surface + 1 dp top rule, 12/14 padding, sitting on the real bottom inset.
class _BarShell extends StatelessWidget {
  const _BarShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(top: BorderSide(color: AppColors.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(g, AppSpacing.md12, g, 14),
        child: child,
      ),
    );
  }
}

/// Buyer bar: Call (48 square) · Offer · Chat (primary, right).
class AdDetailContactBar extends StatelessWidget {
  const AdDetailContactBar({
    super.key,
    required this.onChat,
    required this.onOffer,
    this.onCall,
    this.busy = false,
  });

  final VoidCallback onChat;
  final VoidCallback onOffer;

  /// Null hides the call button (no phone on the ad).
  final VoidCallback? onCall;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return _BarShell(
      child: Row(
        children: [
          if (onCall != null) ...[
            SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: 'Call seller',
                child: OutlinedButton(
                  onPressed: busy ? null : onCall,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.positiveText,
                    side: BorderSide(color: AppColors.dividerColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button12),
                    ),
                  ),
                  child: const Icon(Icons.call_outlined, size: 22),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm8),
          ],
          Expanded(
            flex: 20,
            child: AdDetailBarButton.outlined(
              icon: Icons.local_offer_outlined,
              label: 'Offer',
              onPressed: busy ? null : onOffer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm8),
          Expanded(
            flex: 27,
            child: AdDetailBarButton.filled(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onPressed: busy ? null : onChat,
            ),
          ),
        ],
      ),
    );
  }
}

/// Owner bar: Edit (tinted) · Mark as sold (filled).
class AdDetailOwnerBar extends StatelessWidget {
  const AdDetailOwnerBar({
    super.key,
    required this.onEdit,
    this.onMarkSold,
    this.busy = false,
  });

  final VoidCallback onEdit;

  /// Null when the ad is already sold.
  final VoidCallback? onMarkSold;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return _BarShell(
      child: Row(
        children: [
          Expanded(
            flex: 20,
            child: AdDetailBarButton.tonal(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onPressed: busy ? null : onEdit,
            ),
          ),
          if (onMarkSold != null) ...[
            const SizedBox(width: AppSpacing.sm8),
            Expanded(
              flex: 27,
              child: AdDetailBarButton.filled(
                label: busy ? 'Updating…' : 'Mark as sold',
                onPressed: busy ? null : onMarkSold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sold ad, buyer view: a single "See similar" action.
class AdDetailSoldBar extends StatelessWidget {
  const AdDetailSoldBar({super.key, required this.onSeeSimilar});

  final VoidCallback onSeeSimilar;

  @override
  Widget build(BuildContext context) {
    return _BarShell(
      child: AdDetailBarButton.filled(
        label: 'See similar ads',
        onPressed: onSeeSimilar,
      ),
    );
  }
}

enum _BarButtonKind { filled, outlined, tonal }

/// 48 dp, 12 radius — the only button shape used in the bars and sheets.
class AdDetailBarButton extends StatelessWidget {
  const AdDetailBarButton.filled(
      {super.key, this.icon, required this.label, this.onPressed})
      : _kind = _BarButtonKind.filled;
  const AdDetailBarButton.outlined(
      {super.key, this.icon, required this.label, this.onPressed})
      : _kind = _BarButtonKind.outlined;
  const AdDetailBarButton.tonal(
      {super.key, this.icon, required this.label, this.onPressed})
      : _kind = _BarButtonKind.tonal;

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final _BarButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button12),
    );
    const size = Size.fromHeight(48);
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTextstyle.button, maxLines: 1),
        ],
      ),
    );
    switch (_kind) {
      case _BarButtonKind.filled:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            minimumSize: size,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: shape,
          ),
          child: content,
        );
      case _BarButtonKind.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
            minimumSize: size,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: shape,
          ),
          child: content,
        );
      case _BarButtonKind.tonal:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.chipFill,
            foregroundColor: AppColors.blackColor,
            minimumSize: size,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: shape,
          ),
          child: content,
        );
    }
  }
}
