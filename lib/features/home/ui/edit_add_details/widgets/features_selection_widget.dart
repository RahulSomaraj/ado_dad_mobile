import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

/// Feature chips (wireframe: "Edit ad" → ADDITIONAL FEATURES).
class FeaturesSelectionWidget extends StatelessWidget {
  final List<String> allFeatures;
  final List<String> selectedFeatures;
  final ValueChanged<List<String>> onFeaturesChanged;

  const FeaturesSelectionWidget({
    super.key,
    required this.allFeatures,
    required this.selectedFeatures,
    required this.onFeaturesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 4,
      children: allFeatures.map((feature) {
        final isSelected = selectedFeatures.contains(feature);
        return FilterChip(
          label: Text(feature),
          selected: isSelected,
          onSelected: (sel) {
            final updated = List<String>.from(selectedFeatures);
            if (sel) {
              if (!updated.contains(feature)) updated.add(feature);
            } else {
              updated.remove(feature);
            }
            onFeaturesChanged(updated);
          },
          selectedColor: AppColors.primaryColor,
          checkmarkColor: Colors.white,
          showCheckmark: false,
          backgroundColor: AppColors.whiteColor,
          labelStyle: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 12.5,
              tablet: 15,
              largeTablet: 17,
              desktop: 19,
            ),
            color: isSelected ? Colors.white : AppColors.blackColor,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.greyColor.withOpacity(0.4),
            ),
          ),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
