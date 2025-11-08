import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

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
      spacing: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 10,
        tablet: 14,
        largeTablet: 18,
        desktop: 22,
      ),
      runSpacing: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 8,
        tablet: 12,
        largeTablet: 16,
        desktop: 20,
      ),
      children: allFeatures.map((feature) {
        final isSelected = selectedFeatures.contains(feature);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (sel) {
                final updated = List<String>.from(selectedFeatures);
                if (sel == true) {
                  if (!updated.contains(feature)) updated.add(feature);
                } else {
                  updated.remove(feature);
                }
                onFeaturesChanged(updated);
              },
            ),
            Text(
              feature,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
