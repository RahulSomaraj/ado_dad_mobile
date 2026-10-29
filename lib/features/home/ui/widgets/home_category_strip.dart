import 'package:ado_dad_user/common/app_fonts.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/ui/widgets/home_hero.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:flutter/material.dart';

/// One white card holding every category in a 3-column grid split by
/// hairlines. It floats over the bottom edge of the blue header.
/// Navigation stays in [HomePage] via [onTap].
class HomeCategoryCard extends StatelessWidget {
  const HomeCategoryCard({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<CategoryModel> items;
  final ValueChanged<CategoryModel> onTap;

  static const int columns = 3;

  static double cellHeight(BuildContext context) =>
      GetResponsiveSize.isTablet(context) ? 120 : 92;

  /// Height of the whole card for [count] categories.
  static double heightOf(BuildContext context, int count) =>
      cellHeight(context) * ((count + columns - 1) ~/ columns);

  @override
  Widget build(BuildContext context) {
    final double cellH = cellHeight(context);
    final int rows = (items.length + columns - 1) ~/ columns;
    final BorderSide line = BorderSide(color: AppColors.dividerColor);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: HomeHeroPalette.shadowInk
                .withValues(alpha: AppColors.isDark ? 0.6 : 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rows, (r) {
              return Row(
                children: List.generate(columns, (c) {
                  final i = r * columns + c;
                  final bool lastCol = c == columns - 1;
                  final bool lastRow = r == rows - 1;
                  return Expanded(
                    child: Container(
                      height: cellH,
                      decoration: BoxDecoration(
                        border: Border(
                          right: lastCol ? BorderSide.none : line,
                          bottom: lastRow ? BorderSide.none : line,
                        ),
                      ),
                      child: i < items.length
                          ? _CategoryCell(
                              category: items[i],
                              onTap: () => onTap(items[i]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool tab = GetResponsiveSize.isTablet(context);
    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: category.name,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: tab ? 68 : 50,
                height: tab ? 52 : 38,
                child: Image.asset(category.image, fit: BoxFit.contain),
              ),
              const SizedBox(height: 5),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: appFont(
                  fontSize: tab ? 14 : 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
