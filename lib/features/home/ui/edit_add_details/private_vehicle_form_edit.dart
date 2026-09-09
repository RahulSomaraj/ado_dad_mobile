import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/searchable_dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/location_picker_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/checkbox_toggle_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/features_selection_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/image_picker_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/save_button_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/section_title_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/video_upload_section_widget.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:image_picker/image_picker.dart';


/// Returns the first element matching [test], or null when there is none.
T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Returns the first element, or null for an empty list.
T? _firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

class PrivateVehicleFormEdit extends StatefulWidget {
  final AddModel ad;
  const PrivateVehicleFormEdit({super.key, required this.ad});

  @override
  State<PrivateVehicleFormEdit> createState() => _PrivateVehicleFormEditState();
}

class _PrivateVehicleFormEditState extends State<PrivateVehicleFormEdit> {
  final _formKey = GlobalKey<FormState>();

  /// Category used to scope transmission / fuel lookups.
  static const String _vehicleCategory = 'passenger_car';

  // ---- Controllers (like in TwoWheelerFormEdit)
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _yearCtrl;

  String _location = '';
  double? _latitude;
  double? _longitude;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _descCtrl;

  // Dropdown data
  List<VehicleManufacturer> _manufacturers = [];
  VehicleManufacturer? _selectedManufacturer;

  List<VehicleModel> _models = [];
  VehicleModel? _selectedModel;

  List<VehicleVariant> _variants = [];
  VehicleVariant? _selectedVariant;

  List<VehicleTransmissionType> _transmissionTypes = [];
  VehicleTransmissionType? _selectedTransmissionType;

  List<VehicleFuelType> _fuelTypes = [];
  VehicleFuelType? _selectedFuelType;

  // Other fields
  bool _isFirstOwner = false;
  bool _hasInsurance = false;
  bool _hasRcBook = false;
  List<String> _additionalFeatures = [];

  // Features list
  final List<String> _allFeatures = const [
    "Sunroof",
    "Leather Seats",
    "Navigation System",
    "Reverse Camera",
    "Bluetooth Connectivity",
  ];

  // Images
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _newImageFiles = []; // newly picked
  late List<String> _imageUrls; // existing + uploaded

  // video upload variables
  Uint8List? _newVideoFile; // newly picked video
  String? _uploadedVideoUrl; // uploaded video URL
  String? _videoFileName;
  late String? _existingVideoUrl; // existing video from ad
  bool _videoRemoved = false; // track if video was explicitly removed

  // ---- Helpers
  String _fuelLabel(VehicleFuelType f) => (f.displayName).toString();
  String _transLabel(VehicleTransmissionType t) => (t.displayName).toString();

  int _safeInt(String? s, {required int fallback}) {
    if (s == null) return fallback;
    final t = s.trim();
    if (t.isEmpty) return fallback;
    return int.tryParse(t) ?? fallback;
  }

  @override
  void initState() {
    super.initState();

    // Prefill from ad
    final price = widget.ad.price;
    final location = widget.ad.location;
    final year = widget.ad.year ?? DateTime.now().year;
    final mileage = widget.ad.mileage ?? 0;
    final color = widget.ad.color ?? '';
    final description = widget.ad.description;

    _isFirstOwner = widget.ad.isFirstOwner ?? false;
    _hasInsurance = widget.ad.hasInsurance ?? false;
    _hasRcBook = widget.ad.hasRcBook ?? false;
    _imageUrls = List<String>.from(widget.ad.images);
    _additionalFeatures = List<String>.from(widget.ad.additionalFeatures ?? []);
    _existingVideoUrl = widget.ad.link?.isNotEmpty == true
        ? widget.ad.link
        : null; // existing video URL

    // Controllers (like your TwoWheelerFormEdit)
    _titleCtrl = TextEditingController(text: widget.ad.title ?? '');
    _priceCtrl = TextEditingController(text: price.toString());
    _location = location;
    _yearCtrl = TextEditingController(text: year.toString());

    // Initialize location coordinates if available
    _latitude = null; // widget.ad.latitude if available
    _longitude = null; // widget.ad.longitude if available
    _mileageCtrl = TextEditingController(text: mileage.toString());
    _colorCtrl = TextEditingController(text: color);
    _descCtrl = TextEditingController(text: description);

    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = AddRepository();

    // 1) Manufacturers with vehicleCategory 'passenger_car'
    try {
      _manufacturers =
          await repo.fetchManufacturers(vehicleCategory: 'passenger_car');
    } catch (e) {
      debugPrint('Failed to load manufacturers: $e');
    }
    if (!mounted) return;

    final manufacturerId = widget.ad.manufacturer?.id;
    _selectedManufacturer =
        _firstWhereOrNull(_manufacturers, (m) => m.id == manufacturerId) ??
            _firstOrNull(_manufacturers);

    // 2) Models for selected manufacturer
    final manufacturer = _selectedManufacturer;
    if (manufacturer != null) {
      try {
        _models = await repo.fetchModelsByManufacturer(manufacturer.id);
      } catch (e) {
        debugPrint('Failed to load models: $e');
      }
      if (!mounted) return;
    }

    final modelId = widget.ad.model?.id;
    _selectedModel = _firstWhereOrNull(_models, (m) => m.id == modelId) ??
        _firstOrNull(_models);

    // 3) Variants for selected model
    final model = _selectedModel;
    if (model != null) {
      try {
        _variants = await repo.fetchVariantsByModel(model.id);
      } catch (e) {
        debugPrint('Failed to load variants: $e');
      }
      if (!mounted) return;
    }

    final variantIdOrName = widget.ad.variant;
    if (variantIdOrName != null && variantIdOrName.trim().isNotEmpty) {
      final trimmedVariant = variantIdOrName.trim();
      // Variant not found => leave null instead of defaulting to first.
      _selectedVariant = _firstWhereOrNull(
        _variants,
        (v) =>
            v.id.trim() == trimmedVariant ||
            v.name.trim().toLowerCase() == trimmedVariant.toLowerCase(),
      );
    } else {
      // No variant stored, leave it null
      _selectedVariant = null;
    }

    // 4) Transmission / Fuel (scoped to this category)
    try {
      final types = await repo.fetchVehicleTransmissionTypes(
          vehicleCategory: _vehicleCategory);
      if (!mounted) return;
      _transmissionTypes =
          types.where((t) => t.appliesTo(_vehicleCategory)).toList();
      final txId = widget.ad.transmissionId;
      final name = (widget.ad.transmission ?? '').toLowerCase();
      _selectedTransmissionType =
          _firstWhereOrNull(_transmissionTypes, (t) => t.id == txId) ??
              _firstWhereOrNull(_transmissionTypes,
                  (t) => _transLabel(t).toLowerCase() == name) ??
              _firstOrNull(_transmissionTypes);
    } catch (e) {
      debugPrint('Failed to load transmission types: $e');
    }
    if (!mounted) return;

    try {
      final fuels =
          await repo.fetchVehicleFuelTypes(vehicleCategory: _vehicleCategory);
      if (!mounted) return;
      _fuelTypes = fuels.where((f) => f.appliesTo(_vehicleCategory)).toList();
      final fuelId = widget.ad.fuelTypeId;
      final name = (widget.ad.fuelType ?? '').toLowerCase();
      _selectedFuelType = _firstWhereOrNull(_fuelTypes, (f) => f.id == fuelId) ??
          _firstWhereOrNull(
              _fuelTypes, (f) => _fuelLabel(f).toLowerCase() == name) ??
          _firstOrNull(_fuelTypes);
    } catch (e) {
      debugPrint('Failed to load fuel types: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _newImageFiles.add(bytes);
      }
      if (!mounted) return;
      setState(() {});
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newVideoFile = bytes;
        _videoFileName = picked.name;
        _uploadedVideoUrl = null; // Clear previous upload
        _existingVideoUrl =
            null; // Clear existing video to replace with new one
        _videoRemoved = false; // Reset removal flag when new video is picked
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_newVideoFile != null) {
      try {
        print('📹 Starting video upload...');
        final url = await AddRepository().uploadVideoToS3(_newVideoFile!);
        if (url != null) {
          print('✅ Video uploaded successfully: $url');
          if (mounted) {
            setState(() {
              _uploadedVideoUrl = url;
              _videoRemoved =
                  false; // Reset removal flag when video is uploaded
            });
          }
        } else {
          print('❌ Video upload returned null URL');
        }
      } catch (e) {
        print('❌ Error uploading video: $e');
        // Optionally show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(ErrorMessageUtil.getUserFriendlyMessage(
                    'Failed to upload video: ${e.toString()}'))),
          );
        }
      }
    }
  }

  void _removeVideo() {
    setState(() {
      _newVideoFile = null;
      _videoFileName = null;
      _uploadedVideoUrl = null;
      _existingVideoUrl = null; // Clear existing video URL
      _videoRemoved = true; // Mark that video was explicitly removed
    });
  }

  Future<void> _uploadNewImages() async {
    if (_newImageFiles.isEmpty) return;
    final repo = AddRepository();
    for (final file in _newImageFiles) {
      final url = await repo.uploadImageToS3(file);
      if (url != null) _imageUrls.add(url);
    }
  }

  Future<void> _submitWithBloc(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    await _uploadNewImages();
    await _uploadVideo();

    // Handle video URL - prioritize uploaded video, fallback to existing, or empty string if removed
    final linkValue = _videoRemoved && _uploadedVideoUrl == null
        ? "" // Explicitly set to empty string to remove video
        : (_uploadedVideoUrl ?? _existingVideoUrl);

    final payload = {
      "vehicleType": (widget.ad.vehicleType?.isNotEmpty ?? false)
          ? widget.ad.vehicleType
          : "four_wheeler",
      "title": _titleCtrl.text.trim(), // Include title like other fields
      "price": _safeInt(_priceCtrl.text, fallback: widget.ad.price),
      "location": _location,
      if (_latitude != null) "latitude": _latitude,
      if (_longitude != null) "longitude": _longitude,
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,
      "year": _safeInt(_yearCtrl.text,
          fallback: widget.ad.year ?? DateTime.now().year),
      "mileage": _safeInt(_mileageCtrl.text, fallback: widget.ad.mileage ?? 0),
      "color": _colorCtrl.text.trim(),
      "isFirstOwner": _isFirstOwner,
      "hasInsurance": _hasInsurance,
      "hasRcBook": _hasRcBook,
      "description": _descCtrl.text.trim(),
      "images": _imageUrls,
      "fuelTypeId": _selectedFuelType?.id,
      "transmissionTypeId": _selectedTransmissionType?.id,
      "additionalFeatures": _additionalFeatures,
      "link": linkValue, // Include link like other fields
    };

    // Remove null/empty values, but preserve 'link' and 'title' fields
    final linkWasEmpty = payload['link'] == "";
    final titleValue = payload['title'];
    payload.removeWhere((k, v) =>
        k != 'link' &&
        k != 'title' &&
        (v == null || (v is String && v.trim().isEmpty)));
    // Restore link if it was explicitly set to empty string (to remove video)
    if (linkWasEmpty && _videoRemoved) {
      payload['link'] = "";
    }
    // Always restore title to ensure it's sent to backend (allows updating existing titles)
    if (titleValue != null) {
      payload['title'] = titleValue;
    }

    debugPrint('UPDATE PAYLOAD (private_vehicle) => $payload');

    context.read<AdEditBloc>().add(
          AdEditEvent.submit(
            adId: widget.ad.id,
            category: widget.ad.category.isNotEmpty
                ? widget.ad.category
                : 'private_vehicle',
            payload: payload,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ad',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: AppTextstyle.appbarText.fontSize ?? 20,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: BlocConsumer<AdEditBloc, AdEditState>(
          listener: (context, state) {
            state.whenOrNull(
              saving: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Saving...'))),
              success: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '✅ Saved',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
                context
                    .read<AdvertisementBloc>()
                    .add(const AdvertisementEvent.fetchAllListings());
                // Pop back with a result so the caller (ad detail / My Ads)
                // can refresh; fall back to home when there is nothing to pop.
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go('/home');
                }
              },
              failure: (msg) =>
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  ErrorMessageUtil.getUserFriendlyMessage(msg),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade300.withOpacity(0.9),
              )),
            );
          },
          builder: (context, state) {
            final isSaving =
                state.maybeWhen(saving: () => true, orElse: () => false);

            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 16, tablet: 24, largeTablet: 32, desktop: 40),
                  vertical: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 12, tablet: 18, largeTablet: 24, desktop: 30),
                ),
                children: [
                  // Price
                  GetInput(
                    label: 'Price',
                    isNumberField: true,
                    controller: _priceCtrl,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),

                  // Title
                  GetInput(
                    label: 'Title',
                    controller: _titleCtrl,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),

                  // Location
                  LocationPickerWidget(
                    label: 'Location',
                    initialLocation: _location,
                    initialLatitude: _latitude,
                    initialLongitude: _longitude,
                    onLocationSelected: (location, latitude, longitude) {
                      setState(() {
                        _location = location;
                        _latitude = latitude;
                        _longitude = longitude;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Manufacturer / Model / Variant
                  buildSearchableDropdown<VehicleManufacturer>(
                    labelText: 'Manufacturer',
                    items: _manufacturers,
                    selectedValue: _selectedManufacturer,
                    errorMsg: 'Please select a manufacturer',
                    getDisplayText: (item) => item.displayName,
                    onSearch: (query) async {
                      return await AddRepository().fetchManufacturers(
                        search: query,
                        vehicleCategory: 'passenger_car',
                      );
                    },
                    onChanged: (m) async {
                      setState(() {
                        _selectedManufacturer = m;
                        _selectedModel = null;
                        _models = [];
                        _selectedVariant = null;
                        _variants = [];
                      });
                      if (m != null) {
                        _models = await AddRepository()
                            .fetchModelsByManufacturer(m.id);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  buildSearchableDropdown<VehicleModel>(
                    labelText: 'Model',
                    items: _models,
                    selectedValue: _selectedModel,
                    errorMsg: 'Please select a model',
                    getDisplayText: (item) => item.displayName,
                    enabled:
                        _models.isNotEmpty && _selectedManufacturer != null,
                    onSearch: (query) async {
                      if (_selectedManufacturer == null) {
                        return [];
                      }
                      return await AddRepository().fetchModelsByManufacturer(
                        _selectedManufacturer!.id,
                        search: query,
                      );
                    },
                    onChanged: (mdl) async {
                      setState(() {
                        _selectedModel = mdl;
                        _selectedVariant = null;
                        _variants = [];
                      });
                      if (mdl != null) {
                        _variants =
                            await AddRepository().fetchVariantsByModel(mdl.id);
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildVariantDropdown(),
                  const SizedBox(height: 10),

                  // Transmission / Fuel
                  buildSearchableDropdown<VehicleTransmissionType>(
                    labelText: 'Transmission Type',
                    items: _transmissionTypes,
                    selectedValue: _selectedTransmissionType,
                    getDisplayText: (item) => item.displayName,
                    errorMsg: 'Please select a transmission type',
                    onChanged: (t) =>
                        setState(() => _selectedTransmissionType = t),
                  ),
                  const SizedBox(height: 10),
                  buildSearchableDropdown<VehicleFuelType>(
                    labelText: 'Fuel Type',
                    items: _fuelTypes,
                    selectedValue: _selectedFuelType,
                    getDisplayText: (item) => item.displayName,
                    errorMsg: 'Please select a fuel type',
                    onChanged: (f) => setState(() => _selectedFuelType = f),
                  ),
                  const SizedBox(height: 10),

                  // Year / Mileage / Color
                  GetInput(
                    label: 'Year',
                    isNumberField: true,
                    controller: _yearCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Mileage (km)',
                    isNumberField: true,
                    controller: _mileageCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Color',
                    controller: _colorCtrl,
                  ),
                  const SizedBox(height: 10),

                  // Toggles
                  CheckboxToggleWidget(
                    value: _isFirstOwner,
                    title: 'Is First Owner',
                    onChanged: (v) =>
                        setState(() => _isFirstOwner = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasInsurance,
                    title: 'Has Insurance',
                    onChanged: (v) =>
                        setState(() => _hasInsurance = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasRcBook,
                    title: 'Has RC Book',
                    onChanged: (v) => setState(() => _hasRcBook = v ?? false),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),

                  // Description field with additional height for tablets/desktop
                  GetResponsiveSize.isTablet(context)
                      ? SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 0,
                            tablet: 140,
                            largeTablet: 160,
                            desktop: 180,
                          ),
                          child: GetInput(
                            label: 'Description',
                            isDescription: true,
                            maxLines: 5,
                            controller: _descCtrl,
                          ),
                        )
                      : GetInput(
                          label: 'Description',
                          isDescription: true,
                          maxLines: 5,
                          controller: _descCtrl,
                        ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 20,
                          tablet: 28,
                          largeTablet: 36,
                          desktop: 44)),

                  // Additional Features
                  const SectionTitleWidget(title: 'Additional Features'),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
                  FeaturesSelectionWidget(
                    allFeatures: _allFeatures,
                    selectedFeatures: _additionalFeatures,
                    onFeaturesChanged: (updated) =>
                        setState(() => _additionalFeatures = updated),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 20,
                          tablet: 28,
                          largeTablet: 36,
                          desktop: 44)),

                  // Images
                  const SectionTitleWidget(title: 'Images'),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),
                  ImagePickerWidget(
                    imageUrls: _imageUrls,
                    newImageFiles: _newImageFiles,
                    onPickImages: _pickImages,
                    onRemoveImage: (url) =>
                        setState(() => _imageUrls.remove(url)),
                    onRemoveNewImage: _removeNewImage,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24,
                          tablet: 32,
                          largeTablet: 40,
                          desktop: 48)),

                  // Video Upload Section
                  VideoUploadSectionWidget(
                    videoFileName: _videoFileName,
                    existingVideoUrl: _existingVideoUrl,
                    onPickVideo: _pickVideo,
                    onRemoveVideo: _removeVideo,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24,
                          tablet: 32,
                          largeTablet: 40,
                          desktop: 48)),

                  // Save
                  SaveButtonWidget(
                    isSaving: isSaving,
                    onSave: () => _submitWithBloc(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVariantDropdown() {
    return buildSearchableDropdown<VehicleVariant>(
      labelText: 'Variant',
      items: _variants,
      selectedValue: _selectedVariant,
      getDisplayText: (item) => item.name,
      enabled: _variants.isNotEmpty,
      onChanged: (val) {
        setState(() => _selectedVariant = val);
      },
      errorMsg: 'Please select a variant',
    );
  }
}
