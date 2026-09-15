import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_spacing.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:flutter/material.dart';

/// One block of the detail page: flat surface, 16 dp gutter, 16 top /
/// 20 bottom, optional heading row. Sections are separated by
/// [AdDetailBand], never by shadows or dividers.
class AdDetailSection extends StatelessWidget {
  const AdDetailSection({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
    this.bleedRight = false,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;

  /// Override the default 16/16/16/20 padding.
  final EdgeInsets? padding;

  /// Let the child run to the right screen edge (horizontal rails) while the
  /// heading keeps the gutter.
  final bool bleedRight;

  @override
  Widget build(BuildContext context) {
    final g = AppSpacing.s(context, AppSpacing.gutter);
    final pad = padding ??
        EdgeInsets.fromLTRB(
          g,
          AppSpacing.s(context, AppSpacing.lg16),
          bleedRight ? 0 : g,
          AppSpacing.s(context, AppSpacing.xl20),
        );
    return Container(
      width: double.infinity,
      color: AppColors.whiteColor,
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.only(right: bleedRight ? g : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: AppTextstyle.sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            SizedBox(height: AppSpacing.s(context, AppSpacing.md12)),
          ],
          child,
        ],
      ),
    );
  }
}

/// The 8 dp scaffold-coloured gap between sections.
class AdDetailBand extends StatelessWidget {
  const AdDetailBand({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: AppSpacing.sm8);
  }
}

/// "See all ›" style text action used in section headers.
class AdDetailTextAction extends StatelessWidget {
  const AdDetailTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextstyle.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
