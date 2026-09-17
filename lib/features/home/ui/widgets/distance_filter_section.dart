import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/home/ui/widgets/location_picker_dialog.dart';
import 'package:ado_dad_user/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Radius choices shown in the filter sheets (audit 4.5). Null = Anywhere.
const List<double?> kSearchRadiiKm = [5, 10, 25, 50, 100, null];

/// Key used in the filter result map passed back to the category list.
const String kMaxDistanceKmFilter = 'maxDistanceKm';

String radiusLabel(double? km) => km == null ? 'Anywhere' : '${km.round()} km';

/// Remembers the last radius per category. Storage errors are ignored: the
/// filter simply starts at Anywhere.
class SearchRadiusPrefs {
  SearchRadiusPrefs._();

  static String _key(String categoryId) => 'filter_radius_km_$categoryId';

  static Future<double?> load(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_key(categoryId));
      return v != null && kSearchRadiiKm.contains(v) ? v : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String? categoryId, double? km) async {
    if (categoryId == null || categoryId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (km == null) {
        await prefs.remove(_key(categoryId));
      } else {
        await prefs.setDouble(_key(categoryId), km);
      }
    } catch (_) {}
  }
}

/// "Near {place} · Change" plus radius chips. Reads and changes the app-wide
/// place through [LocationService], so the list re-queries with the new
/// coordinates when the sheet is applied.
class DistanceFilterSection extends StatelessWidget {
  final double? radiusKm;
  final ValueChanged<double?> onChanged;

  const DistanceFilterSection({
    super.key,
    required this.radiusKm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserPlace?>(
      valueListenable: LocationService().place,
      builder: (context, place, _) {
        final hasPlace = place != null;
        final placeText = !hasPlace
            ? 'Set your location to filter by distance'
            : 'Near ${place.label ?? 'your location'}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: AppColors.greyColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    placeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: AppColors.blackColor1),
                  ),
                ),
                TextButton(
                  onPressed: () => showLocationPickerDialog(context),
                  child: Text(hasPlace ? 'Change' : 'Set'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final km in kSearchRadiiKm)
                  ChoiceChip(
                    label: Text(radiusLabel(km)),
                    selected: radiusKm == km,
                    // Without a place a radius has nothing to measure from.
                    onSelected: (!hasPlace && km != null) ? null : (_) => onChanged(km),
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: radiusKm == km ? Colors.white : AppColors.blackColor,
                      fontWeight: radiusKm == km ? FontWeight.w600 : FontWeight.w500,
                    ),
                    showCheckmark: false,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
