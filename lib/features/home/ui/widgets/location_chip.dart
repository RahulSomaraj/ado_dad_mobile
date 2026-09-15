import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/services/location_service.dart';
import 'package:flutter/material.dart';

/// The header's location line. Reads [LocationService.place] directly, so it
/// is correct from the first frame and updates wherever the place changes.
///
/// Never blank: a named place, else "Current location" (point known, name
/// pending or unavailable), else "Locating…" / "Set location".
class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.fontSize,
    required this.onTap,
  });

  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final service = LocationService();
    return ValueListenableBuilder<UserPlace?>(
      valueListenable: service.place,
      builder: (context, place, _) {
        return ValueListenableBuilder<LocationStatus>(
          valueListenable: service.status,
          builder: (context, status, _) {
            final String? label = place?.label;
            final bool named = label != null;
            final bool locating =
                place == null && status == LocationStatus.locating;

            final String text = label ??
                (place != null
                    ? 'Current location'
                    : locating
                        ? 'Locating…'
                        : 'Set location');

            final child = Text(
              text,
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: fontSize,
                decoration:
                    named ? TextDecoration.none : TextDecoration.underline,
                decorationColor: AppColors.whiteColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              softWrap: true,
            );

            return Semantics(
              button: !locating,
              label: named ? 'Location: $text. Change location' : text,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: locating ? null : onTap,
                child: named ? Tooltip(message: text, child: child) : child,
              ),
            );
          },
        );
      },
    );
  }
}
