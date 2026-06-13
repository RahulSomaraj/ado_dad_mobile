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
                        ? AppColors.primaryColor
                        : AppColors.greyColor),
                title: Text(title,
                    style: TextStyle(
                        color: AppColors.blackColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400)),
                trailing: selected
                    ? const Icon(Icons.check, color: AppColors.primaryColor)
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 1),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.isDark
                      ? Colors.white10
                      : Colors.grey[200],
                ),
                child: const Icon(Icons.brightness_6_outlined,
                    color: AppColors.primaryColor),
              ),
              title: Text(
                'Appearance',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.blackColor),
              ),
              subtitle: Text(
                ThemeController.instance.label(),
                style: TextStyle(color: AppColors.greyColor, fontSize: 12),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 18, color: AppColors.greyColor),
              onTap: () => _openPicker(context),
            ),
          );
        },
      ),
    );
  }
}
