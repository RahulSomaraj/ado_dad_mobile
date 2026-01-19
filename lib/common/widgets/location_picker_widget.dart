import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/common/google_places_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerWidget extends StatefulWidget {
  final String label;
  final String? initialLocation;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(String location, double latitude, double longitude)
      onLocationSelected;
  final String? Function(String?)? validator;

  const LocationPickerWidget({
    super.key,
    required this.label,
    this.initialLocation,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _locationController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService(
    apiKey: AppConfig.googlePlacesApiKey,
  );

  String? _selectedLocation;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _locationController.text = widget.initialLocation ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _showLocationPickerDialog() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _LocationPickerDialog(
          initialLocation: _selectedLocation,
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          placesService: _placesService,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedLocation = result['location'] as String;
          _selectedLatitude = result['latitude'] as double;
          _selectedLongitude = result['longitude'] as double;
          _locationController.text = _selectedLocation!;
        });
        widget.onLocationSelected(
          _selectedLocation!,
          _selectedLatitude!,
          _selectedLongitude!,
        );
      }
    } catch (e) {
      // Show error message if dialog fails to open
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to open location picker. Please check Google Maps API key configuration.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          readOnly: true,
          decoration: CommonDecoration.textFieldDecoration(
            labelText: widget.label,
          ).copyWith(
            labelStyle: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 22,
                desktop: 24,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 18,
                desktop: 20,
              ),
              vertical: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 22,
                desktop: 24,
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: _showLocationPickerDialog,
              iconSize: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24,
                tablet: 28,
                largeTablet: 32,
                desktop: 36,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
          validator: widget.validator,
          onTap: _showLocationPickerDialog,
        ),
      ],
    );
  }
}

class _LocationPickerDialog extends StatefulWidget {
  final String? initialLocation;
  final double? initialLatitude;
  final double? initialLongitude;
  final GooglePlacesService placesService;

  const _LocationPickerDialog({
    required this.initialLocation,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.placesService,
  });

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _suggestions = [];

  LatLng _selectedLocation =
      const LatLng(20.5937, 78.9629); // Default to India center
  String? _selectedAddress;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialLocation;
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation,
      );
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchLocation(_searchController.text);
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final predictions = await widget.placesService.getPlacePredictions(
        input: query,
        region: 'in',
        language: 'en',
      );

      setState(() {
        _suggestions = predictions;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _selectSuggestion(PlacePrediction prediction) async {
    final placeDetails =
        await widget.placesService.getPlaceDetails(prediction.placeId);

    if (placeDetails?.geometry?.location != null) {
      final location = placeDetails!.geometry!.location;
      final address = placeDetails.formattedAddress ?? prediction.description;

      setState(() {
        _selectedLocation = LatLng(location.lat, location.lng);
        _selectedAddress = address;
        _marker = Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
        );
        _suggestions = [];
        _searchController.text = address;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation),
      );
    }
  }

  void _onMapTap(LatLng location) async {
    try {
      // Reverse geocode to get address from coordinates
      final address = await widget.placesService.reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      setState(() {
        _selectedLocation = location;
        _selectedAddress =
            address ?? '${location.latitude}, ${location.longitude}';
        _marker = Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
        );
        _searchController.text = _selectedAddress!;
      });
    } catch (e) {
      setState(() {
        _selectedLocation = location;
        _selectedAddress = '${location.latitude}, ${location.longitude}';
        _marker = Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if Google Maps API key is configured
    final apiKey = AppConfig.googlePlacesApiKey;
    final hasApiKey = apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY_HERE';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width > 600
            ? 600
            : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        child: hasApiKey
            ? Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Location',
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 18,
                                tablet: 22,
                                largeTablet: 26,
                                desktop: 30,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 18,
                                desktop: 20,
                              ),
                              vertical: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 16,
                              tablet: 20,
                              largeTablet: 22,
                              desktop: 24,
                            ),
                          ),
                        ),
                        // Suggestions
                        if (_suggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: Text(suggestion.description),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Map
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        try {
                          return GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation,
                              zoom: 14,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            onTap: _onMapTap,
                            markers: _marker != null ? {_marker!} : {},
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                            onCameraMove: (position) {
                              // Optional: Update marker position on camera move
                            },
                          );
                        } catch (e) {
                          // Fallback if map fails to load
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Map failed to load',
                                  style: TextStyle(
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile: 16,
                                      tablet: 20,
                                      largeTablet: 24,
                                      desktop: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please check your Google Maps API key configuration',
                                  style: TextStyle(
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile: 12,
                                      tablet: 16,
                                      largeTablet: 18,
                                      desktop: 22,
                                    ),
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  // Selected location info
                  if (_selectedAddress != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location:',
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 20,
                                desktop: 24,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress!,
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 20,
                                desktop: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedAddress != null
                              ? () {
                                  Navigator.of(context).pop({
                                    'location': _selectedAddress!,
                                    'latitude': _selectedLocation.latitude,
                                    'longitude': _selectedLocation.longitude,
                                  });
                                }
                              : null,
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Google Maps API key not configured',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 22,
                          largeTablet: 26,
                          desktop: 30,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Please configure your Google Maps API key in:\n1. .env file (GOOGLE_PLACES_API_KEY)\n2. android/app/src/main/res/values/strings.xml',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 24,
                        ),
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
      ),
    );
  }
}
