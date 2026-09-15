import 'dart:async';

import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/sell_repository.dart';
import '../../domain/sell_config.dart';
import 'sell_ui.dart';

class BrandModelResult {
  final VehicleManufacturer brand;
  final VehicleModel model;
  const BrandModelResult(this.brand, this.model);
}

/// W04 (d): popular brands → search → models, one sheet.
Future<BrandModelResult?> showBrandModelSheet(
  BuildContext context, {
  required SellConfig config,
  required SellRepository repository,
}) {
  return showSellSheet<BrandModelResult>(
    context,
    (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.82,
      child: _BrandModelPicker(config: config, repository: repository),
    ),
  );
}

class _BrandModelPicker extends StatefulWidget {
  const _BrandModelPicker({required this.config, required this.repository});
  final SellConfig config;
  final SellRepository repository;

  @override
  State<_BrandModelPicker> createState() => _BrandModelPickerState();
}

class _BrandModelPickerState extends State<_BrandModelPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  VehicleManufacturer? _brand;
  List<VehicleManufacturer> _brands = const [];
  List<VehicleModel> _models = const [];
  bool _loading = true;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadBrands('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadBrands(String q) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final list = await widget.repository.searchBrands(widget.config, q);
      if (!mounted || id != _request) return;
      setState(() {
        _brands = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _loadModels(VehicleManufacturer brand) async {
    _debounce?.cancel();
    final id = ++_request;
    setState(() {
      _brand = brand;
      _models = const [];
      _loading = true;
      _failed = false;
      _search.clear();
    });
    try {
      final list = await widget.repository.models(brand.id);
      if (!mounted || id != _request) return;
      setState(() {
        _models = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _onQuery(String q) {
    if (_brand != null) {
      setState(() {});
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _loadBrands(q));
  }

  @override
  Widget build(BuildContext context) {
    final inModels = _brand != null;
    final q = _search.text.trim().toLowerCase();
    final models = q.isEmpty ? _models : _models.where((m) => m.displayName.toLowerCase().contains(q)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (inModels)
              IconButton(
                tooltip: 'Back to brands',
                onPressed: () {
                  setState(() {
                    _brand = null;
                    _search.clear();
                  });
                  _loadBrands('');
                },
                icon: Icon(Icons.arrow_back_rounded, color: SellTokens.ink),
              ),
            Expanded(
              child: Text(inModels ? '${_brand!.displayName} models' : 'Choose the brand', style: SellTokens.heading),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SellInput(
          controller: _search,
          hint: inModels ? 'Search models' : 'Search brands',
          prefix: Icon(Icons.search_rounded, color: SellTokens.muted, size: 20),
          onChanged: _onQuery,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const _SheetSkeleton()
              : _failed
                  ? _RetryBox(
                      message: inModels ? 'Couldn’t load models.' : 'Couldn’t load brands.',
                      onRetry: () => inModels ? _loadModels(_brand!) : _loadBrands(_search.text),
                    )
                  : inModels
                      ? _modelList(models)
                      : _brandList(),
        ),
      ],
    );
  }

  Widget _brandList() {
    if (_brands.isEmpty) return _notListed('No brands match “${_search.text.trim()}”.');
    final showGrid = _search.text.trim().isEmpty;
    if (showGrid) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Popular', style: SellTokens.caption),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              for (final b in _brands.take(12))
                Material(
                  color: SellTokens.input,
                  borderRadius: BorderRadius.circular(SellTokens.rInput),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(SellTokens.rInput),
                    onTap: () => _loadModels(b),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(b.displayName, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: SellTokens.label.copyWith(color: SellTokens.ink)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_brands.length > 12) ...[
            Padding(padding: const EdgeInsets.fromLTRB(0, 16, 0, 4), child: Text('All brands', style: SellTokens.caption)),
            for (final b in _brands.skip(12)) _row(b.displayName, () => _loadModels(b)),
          ],
          _notListedRow(),
        ],
      );
    }
    return ListView(children: [for (final b in _brands) _row(b.displayName, () => _loadModels(b)), _notListedRow()]);
  }

  Widget _modelList(List<VehicleModel> models) {
    if (models.isEmpty) return _notListed('No models found for ${_brand!.displayName}.');
    return ListView(
      children: [
        for (final m in models) _row(m.displayName, () => Navigator.of(context).pop(BrandModelResult(_brand!, m))),
        _notListedRow(),
      ],
    );
  }

  Widget _row(String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SellTokens.line.withValues(alpha: 0.6)))),
          child: Row(
            children: [
              Expanded(child: Text(text, style: SellTokens.body)),
              Icon(Icons.chevron_right_rounded, color: SellTokens.muted),
            ],
          ),
        ),
      );

  Widget _notListedRow() => InkWell(
        onTap: _explainNotListed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Text(
            _brand == null ? 'My brand isn’t listed' : 'My model isn’t listed',
            style: SellTokens.label.copyWith(color: SellTokens.accentText, fontWeight: FontWeight.w600),
          ),
        ),
      );

  Widget _notListed(String message) => ListView(
        children: [
          const SizedBox(height: 24),
          Text(message, textAlign: TextAlign.center, style: SellTokens.body.copyWith(color: SellTokens.muted)),
          const SizedBox(height: 8),
          Center(child: _notListedRow()),
        ],
      );

  void _explainNotListed() {
    showSellSheet<void>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Not in our list yet?', style: SellTokens.heading),
          const SizedBox(height: 8),
          Text(
            'Pick the closest match for now and write the exact name in your description. We add new brands and models every week.',
            style: SellTokens.body.copyWith(color: SellTokens.ink2),
          ),
          const SizedBox(height: 16),
          SellButton(label: 'OK', onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }
}

/// W05: year list, newest first, within the config limits.
Future<int?> showYearSheet(BuildContext context, {required int min, required int max, int? selected}) {
  final years = [for (var y = max; y >= min; y--) y];
  return showSellSheet<int>(
    context,
    (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Year', style: SellTokens.heading),
          const SizedBox(height: 4),
          Text('The year on the RC book', style: SellTokens.caption),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.9),
              itemCount: years.length,
              itemBuilder: (_, i) {
                final y = years[i];
                return SellChip(label: '$y', selected: y == selected, onTap: () => Navigator.of(ctx).pop(y));
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class PickedLocation {
  final String label;
  final double latitude;
  final double longitude;
  const PickedLocation(this.label, this.latitude, this.longitude);
}

/// W06: "Use my location" + Places search.
Future<PickedLocation?> showLocationSheet(BuildContext context) {
  return showSellSheet<PickedLocation>(
    context,
    (ctx) => SizedBox(height: MediaQuery.of(ctx).size.height * 0.8, child: const _LocationPicker()),
  );
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker();
  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  final _places = GooglePlacesService(apiKey: AppConfig.googlePlacesApiKey);
  final _search = TextEditingController();
  Timer? _debounce;
  List<PlacePrediction> _predictions = const [];
  bool _locating = false;
  bool _searching = false;
  String? _message;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() => _message = 'Turn on location, or search for your area below.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _message = 'Location permission is off. Search for your area below.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      final label = await _places.reverseGeocode(latitude: pos.latitude, longitude: pos.longitude);
      if (!mounted) return;
      Navigator.of(context).pop(PickedLocation(
        _short(label) ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        pos.latitude,
        pos.longitude,
      ));
    } catch (_) {
      if (mounted) setState(() => _message = 'Couldn’t find you. Search for your area below.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// "Kakkanad, Kochi, Kerala 682030, India" → "Kakkanad, Kochi".
  String? _short(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final parts = address.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length <= 2) return parts.join(', ');
    final useful = parts.where((p) => !RegExp(r'\d{6}').hasMatch(p) && p != 'India').toList();
    return useful.take(2).join(', ');
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _predictions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final list = await _places.getPlacePredictions(input: q.trim());
      if (!mounted) return;
      setState(() {
        _predictions = list;
        _searching = false;
      });
    });
  }

  Future<void> _choose(PlacePrediction p) async {
    setState(() => _searching = true);
    final details = await _places.getPlaceDetails(p.placeId);
    if (!mounted) return;
    setState(() => _searching = false);
    final loc = details?.geometry?.location;
    if (loc == null) {
      setState(() => _message = 'Couldn’t open that place. Try another result.');
      return;
    }
    Navigator.of(context).pop(PickedLocation(_short(p.description) ?? details!.name, loc.lat, loc.lng));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Where is it?', style: SellTokens.heading),
        const SizedBox(height: 4),
        Text('Buyers nearby see your ad first. We show the area, not your address.', style: SellTokens.caption),
        const SizedBox(height: 12),
        SellButton(
          label: _locating ? 'Finding you…' : 'Use my location',
          icon: Icons.my_location_rounded,
          kind: SellButtonKind.tonal,
          busy: _locating,
          onPressed: _useCurrent,
        ),
        const SizedBox(height: 12),
        SellInput(
          controller: _search,
          hint: 'Search area or town',
          prefix: Icon(Icons.search_rounded, color: SellTokens.muted, size: 20),
          suffix: _searching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          onChanged: _onQuery,
          textInputAction: TextInputAction.search,
        ),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, style: SellTokens.caption.copyWith(color: SellTokens.warnFg))),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            itemCount: _predictions.length,
            itemBuilder: (_, i) {
              final p = _predictions[i];
              return InkWell(
                onTap: () => _choose(p),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SellTokens.line.withValues(alpha: 0.6)))),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, color: SellTokens.muted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.description, style: SellTokens.body.copyWith(fontSize: 14))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SheetSkeleton extends StatelessWidget {
  const _SheetSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        height: 40,
        decoration: BoxDecoration(color: SellTokens.input, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _RetryBox extends StatelessWidget {
  const _RetryBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: SellTokens.body.copyWith(color: SellTokens.muted)),
          const SizedBox(height: 10),
          SellButton(label: 'Try again', kind: SellButtonKind.tonal, expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}
