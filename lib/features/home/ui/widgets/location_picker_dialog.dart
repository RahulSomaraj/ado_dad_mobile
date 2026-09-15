import 'dart:async';

import 'package:ado_dad_user/services/location_service.dart';
import 'package:flutter/material.dart';

/// Opens the location picker. Resolves to true when the place changed.
///
/// The dialog writes only through [LocationService]; callers do not need to
/// act on the result — anything listening to `LocationService().place`
/// (the chip, the Home feed) updates itself.
Future<bool> showLocationPickerDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => const LocationPickerDialog(),
  );
  return changed ?? false;
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

enum _Busy { none, locating, saving }

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final LocationService _service = LocationService();
  late final TextEditingController _controller;

  List<PlaceSuggestion> _suggestions = const [];
  PlaceSuggestion? _selected;
  bool _loadingSuggestions = false;
  _Busy _busy = _Busy.none;
  String? _error;
  _SettingsAction? _errorAction;

  Timer? _debounce;
  int _query = 0; // drops suggestion responses for superseded input

  @override
  void initState() {
    super.initState();
    // Prefill only a place the user chose; a GPS name is not something they
    // typed and would turn into a manual pick if saved unchanged.
    final current = _service.place.value;
    _controller = TextEditingController(
      text: (current != null && current.isManual) ? current.label ?? '' : '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_selected != null && value != _selected!.description) {
      _selected = null;
    }
    if (_error != null) {
      setState(() {
        _error = null;
        _errorAction = null;
      });
    }
    _debounce?.cancel();
    final token = ++_query;

    if (value.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _loadingSuggestions = true);
      final results = await _service.resolver.suggest(value);
      if (!mounted || token != _query) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  void _pick(PlaceSuggestion s) {
    _debounce?.cancel();
    _query++;
    setState(() {
      _selected = s;
      _controller.text = s.description;
      _controller.selection =
          TextSelection.collapsed(offset: s.description.length);
      _suggestions = const [];
      _loadingSuggestions = false;
      _error = null;
      _errorAction = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _busy = _Busy.locating;
      _error = null;
      _errorAction = null;
    });
    final result = await _service.useDevice();
    if (!mounted) return;
    if (result == LocateResult.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = _Busy.none;
      switch (result) {
        case LocateResult.servicesOff:
          _error = 'Location is turned off on this device.';
          _errorAction = _SettingsAction.location;
        case LocateResult.permissionDeniedForever:
          _error = 'Location permission is blocked for Ado-dad.';
          _errorAction = _SettingsAction.app;
        case LocateResult.permissionDenied:
          _error = 'Location permission was not granted.';
          _errorAction = null;
        case LocateResult.noFix:
          _error = "Couldn't get your location. Try again, or type a place.";
          _errorAction = null;
        case LocateResult.ok:
          break;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = _Busy.saving;
      _error = null;
      _errorAction = null;
    });
    final result = await _service.setManual(
      placeId: _selected?.placeId,
      text: _controller.text,
    );
    if (!mounted) return;
    switch (result) {
      case SetPlaceResult.ok:
        Navigator.of(context).pop(true);
      case SetPlaceResult.empty:
        setState(() {
          _busy = _Busy.none;
          _error = 'Enter a town, city or area.';
        });
      case SetPlaceResult.notFound:
        setState(() {
          _busy = _Busy.none;
          _error =
              "Couldn't find that place. Pick a suggestion or try a nearby town.";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool busy = _busy != _Busy.none;

    return AlertDialog(
      title: const Text('Choose your location'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              enabled: !busy,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) {
                if (!busy) _save();
              },
              decoration: InputDecoration(
                hintText: 'e.g. Perunnad, Pathanamthitta, Kerala',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _loadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on, size: 16),
                      title: Text(
                        s.description,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: busy ? null : () => _pick(s),
                    );
                  },
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
              if (_errorAction != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _errorAction == _SettingsAction.app
                        ? _service.openAppSettings()
                        : _service.openLocationSettings(),
                    child: const Text('Open settings'),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : _useCurrentLocation,
              icon: _busy == _Busy.locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Use current location'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: busy ? null : _save,
          child: _busy == _Busy.saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

enum _SettingsAction { app, location }
