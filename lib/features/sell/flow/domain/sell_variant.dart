/// One row from `GET /vehicle-inventory/variants?modelId=…`.
///
/// The endpoint's `$project` already populates `fuelType` and
/// `transmissionType` to `{_id, name, displayName}` and emits `price`,
/// `engineSpecs`, `performanceSpecs` and `seatingCapacity`. The app used to
/// parse only `_id` + `name` and throw the rest away, which is why the seller
/// was asked for fuel and transmission a second time.
///
/// `colors` is projected only by servers carrying the Sep 2026 change; when it
/// is absent [SellRepository.variantColors] fills it from the detail endpoint.
class SellVariant {
  final String id;
  final String name;
  final String displayName;
  final String? fuelTypeId;
  final String? fuelLabel;
  final String? transmissionTypeId;
  final String? transmissionLabel;
  final int? engineCc;
  final int? seats;
  final List<String> colors;

  const SellVariant({
    required this.id,
    required this.name,
    required this.displayName,
    this.fuelTypeId,
    this.fuelLabel,
    this.transmissionTypeId,
    this.transmissionLabel,
    this.engineCc,
    this.seats,
    this.colors = const [],
  });

  /// "Manual · 1197 cc · 5 seats" — the line under the variant's name.
  String get spec => [
        if (transmissionLabel != null) transmissionLabel!,
        if (engineCc != null && engineCc! > 0) '$engineCc cc',
        if (seats != null && seats! > 0) '$seats seats',
      ].join(' · ');

  /// "VXi · Petrol · Manual · 1197 cc" — the filled picker row.
  String get summary => [
        displayName,
        if (fuelLabel != null) fuelLabel!,
        if (transmissionLabel != null) transmissionLabel!,
        if (engineCc != null && engineCc! > 0) '$engineCc cc',
      ].join(' · ');

  /// Groups the sheet. Variants with no fuel fall into "Other".
  String get fuelGroup => fuelLabel ?? 'Other';

  static String? _text(dynamic raw) {
    final s = raw?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? _int(dynamic raw) {
    if (raw is num) return raw.round();
    return int.tryParse('${raw ?? ''}');
  }

  /// A populated `{_id, name, displayName}` object, or a bare id string.
  static (String?, String?) _ref(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return (_text(m['_id'] ?? m['id']), _text(m['displayName'] ?? m['name']));
    }
    return (_text(raw), null);
  }

  factory SellVariant.fromJson(Map<String, dynamic> json) {
    final (fuelId, fuelLabel) = _ref(json['fuelType']);
    final (transId, transLabel) = _ref(json['transmissionType']);
    final engine = json['engineSpecs'];
    final name = _text(json['name']) ?? '';
    final display = _text(json['displayName']) ?? name;
    return SellVariant(
      id: _text(json['_id'] ?? json['id']) ?? '',
      name: name,
      displayName: display.isEmpty ? name : display,
      fuelTypeId: fuelId,
      fuelLabel: fuelLabel,
      transmissionTypeId: transId,
      transmissionLabel: transLabel,
      engineCc: engine is Map ? _int(engine['capacity']) : null,
      seats: _int(json['seatingCapacity']),
      colors: (json['colors'] is List)
          ? (json['colors'] as List)
              .map((e) => '$e'.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : const [],
    );
  }

  @override
  String toString() => displayName;
}
