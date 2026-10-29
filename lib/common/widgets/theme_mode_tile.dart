import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/theme_controller.dart';
import 'package:flutter/material.dart';

/// A Profile menu card that lets the user pick Light / Dark / System theme.
/// Styled to match the existing ProfileMenuItem cards.
class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) {
            final current = ThemeController.instance.mode;
            Widget option(String title, IconData icon, ThemeMode mode) {
              final selected = current == mode;
              return ListTile(
                leading: Icon(icon,
                    color: selected
                        ? AppColors.brandText
                        : AppColors.greyColor),
                title: Text(title,
                    style: TextStyle(
                        color: AppColors.blackColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400)),
                trailing: selected
                    ? Icon(Icons.check, color: AppColors.brandText)
                    : null,
                onTap: () {
                  ThemeController.instance.setMode(mode);
                  Navigator.of(sheetContext).pop();
                },
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Appearance',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor)),
                    ),
                  ),
                  option('Light', Icons.light_mode_outlined, ThemeMode.light),
                  option('Dark', Icons.dark_mode_outlined, ThemeMode.dark),
                  option('System default', Icons.brightness_auto_outlined,
                      ThemeMode.system),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Material(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openPicker(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySoft),
                      child: Icon(Icons.brightness_6_outlined,
                          size: 20, color: AppColors.brandText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: AppColors.blackColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ThemeController.instance.label(),
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: AppColors.greyColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
