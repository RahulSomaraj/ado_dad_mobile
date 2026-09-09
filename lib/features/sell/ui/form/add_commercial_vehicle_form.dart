import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/searchable_dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/location_picker_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/media_upload/media_upload_bloc.dart';
import 'package:ado_dad_user/features/sell/ui/form/widgets/photo_step_widget.dart';
import 'package:ado_dad_user/models/advertisement_post_model/commercial_vehicle_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddCommercialVehicleForm extends StatefulWidget {
  final String categoryTitle;
  final String categoryId;
  const AddCommercialVehicleForm(
      {super.key, required this.categoryTitle, required this.categoryId});

  @override
  State<AddCommercialVehicleForm> createState() =>
      _AddCommercialVehicleFormState();
}

class _AddCommercialVehicleFormState extends State<AddCommercialVehicleForm> {
  final GlobalKey<FormState> _sellerFormKey = GlobalKey<FormState>();

  /// Category used to scope transmission / fuel type lookups.
  static const String _vehicleCategory = 'commercial_vehicle';
  int _step = 0; // 0 = Photos, 1 = Details, 2 = Review
  String? _title;
  int _price = 0;
  String _location = '';
  double? _latitude;
  double? _longitude;
  String _description = '';
  /// Photos/video live here and upload to S3 as soon as they are picked.
  late final MediaUploadBloc _mediaBloc =
      MediaUploadBloc(repository: AddRepository());

  CommercialVehicleType? _selectedVehicleType;
  final Map<String, String> _bodyTypeMap = {
    'flatbed': 'flatbed',
    'container': 'container',
    'refrigerated': 'refrigerated',
    'tanker': 'tanker',
    'dump': 'dump',
    'pickup': 'pickup',
    'box': 'box',
    'passenger': 'passenger',
    'others': 'others'
  };
  String? _selectedBodyType;

  final List<String> _allFeatures = [
    "GPS Tracking",
    "Climate Control",
    "Safety Features",
    "Anti-lock Braking System"
  ];

  List<String> _selectedFeatures = [];
  List<VehicleManufacturer> _manufacturers = [];
  VehicleManufacturer? _selectedManufacturer;
  List<VehicleModel> _models = [];
  VehicleModel? _selectedModel;
  List<VehicleVariant> _variants = [];
  VehicleVariant? _selectedVariant;

  @override
  void dispose() {
    _mediaBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context
        .read<AddPostBloc>()
        .add(const AddPostEvent.loadCommercialVehicleTypes());
    _loadManufacturers();
    _loadTransmissionTypes();
    _loadFuelTypes();
  }

  Future<void> _loadManufacturers() async {
    // For commercial_vehicle category,
    // fetch manufacturers with vehicleCategory 'passenger_car'
    // TODO(backend): commercial manufacturer category
    try {
      final manufacturers = await AddRepository().fetchManufacturers(
        vehicleCategory: 'passenger_car',
      );
      if (!mounted) return;
      setState(() {
        _manufacturers = manufacturers;
      });
    } catch (e) {
      debugPrint('Failed to load manufacturers: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load manufacturers')),
      );
    }
  }

  Future<void> _loadTransmissionTypes() async {
    try {
      final transmissionTypes = await AddRepository()
          .fetchVehicleTransmissionTypes(vehicleCategory: _vehicleCategory);
      if (!mounted) return;
      setState(() {
        // Keep only types that apply to this category (or to all).
        _transmissionTypes = transmissionTypes
            .where((t) => t.appliesTo(_vehicleCategory))
            .toList();
      });
    } catch (e) {
      // Optional: surface the error
      debugPrint('Failed to load transmission types: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load transmission types')),
      );
    }
  }

  Future<void> _loadFuelTypes() async {
    try {
      final fuelTypes = await AddRepository()
          .fetchVehicleFuelTypes(vehicleCategory: _vehicleCategory);
      if (!mounted) return;
      setState(() {
        // Keep only types that apply to this category (or to all).
        _fuelTypes =
            fuelTypes.where((f) => f.appliesTo(_vehicleCategory)).toList();
      });
    } catch (e) {
      // Optional: surface the error
      debugPrint('Failed to load fuel types: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load fuel types')),
      );
    }
  }

  int _year = 2023;
  int _mileage = 0;
  List<VehicleTransmissionType> _transmissionTypes = [];
  VehicleTransmissionType? _selectedtransmissionType;
  List<VehicleFuelType> _fuelTypes = [];
  VehicleFuelType? _selectedfuelType;
  String _color = '';
  int _payloadCapacity = 0;
  String _payloadUnit = '';
  int _axilCount = 0;
  bool _hasInsurance = false;
  bool _hasIFitness = false;
  bool _hasPermit = false;
  int _seatingCapacity = 0;

  void _showMediaMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addAdvertisement() async {
    if (!_sellerFormKey.currentState!.validate()) {
      setState(() => _step = 1); // Details step
      return;
    }
    _sellerFormKey.currentState!.save();

    // Photos were uploaded in the background while the form was filled.
    final media = _mediaBloc.state;
    if (!media.hasImages) {
      setState(() => _step = 0);
      _showMediaMessage('Add at least one photo to post your ad.');
      return;
    }
    if (!media.allDone) {
      setState(() => _step = 0);
      _showMediaMessage(media.hasFailed
          ? 'Some photos failed to upload. Tap them to retry or remove.'
          : 'Still uploading ${media.pendingCount} file(s), please wait a moment.');
      return;
    }

    final ad = {
      "commercialVehicleType": _selectedVehicleType?.name,
      "bodyType": _selectedBodyType,
      "price": _price,
      "location": _location,
      if (_latitude != null) "latitude": _latitude,
      if (_longitude != null) "longitude": _longitude,
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,
      "year": _year,
      "mileage": _mileage,
      "color": _color,
      "payloadCapacity": _payloadCapacity,
      "payloadUnit": _payloadUnit,
      "axleCount": _axilCount,
      "hasInsurance": _hasInsurance,
      "hasFitness": _hasIFitness,
      "hasPermit": _hasPermit,
      "description": _description,
      "images": media.imageUrls,
      "link": media.videoUrl,
      "fuelTypeId": _selectedfuelType!.id,
      "transmissionTypeId": _selectedtransmissionType!.id,
      "additionalFeatures": _selectedFeatures,
      "seatingCapacity": _seatingCapacity,
    };

    // Add title if provided
    if (_title != null && _title!.trim().isNotEmpty) {
      ad["title"] = _title!.trim();
    }

    context.read<AddPostBloc>().add(
          AddPostEvent.postAd(
            category: widget.categoryId,
            data: ad,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 40.0,
            tablet: 55.0,
            largeTablet: 65.0,
            desktop: 75.0,
          ),
        ),
        child: AppBar(
          backgroundColor: AppColors.whiteColor,
          leading: IconButton(
            icon: Icon(
              (!kIsWeb && Platform.isIOS)
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              color: Colors.black,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24,
                tablet: 30,
                largeTablet: 32,
                desktop: 36,
              ),
            ),
            onPressed: () {
              context.pop();
            },
          ),
          title: Text(
            'Post your Ad',
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
      ),
      body: BlocProvider<MediaUploadBloc>.value(
        value: _mediaBloc,
        child: BlocListener<MediaUploadBloc, MediaUploadState>(
          // Step nav (Next enabled/disabled) depends on media state.
          listener: (_, __) => setState(() {}),
          child: BlocConsumer<AddPostBloc, AddPostState>(
        listener: (context, state) async {
          state.whenOrNull(
            success: () async {
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Success'),
                    content: const Text('Ad posted successfully'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
              if (!context.mounted) return;
              // ✅ Refresh home listings
              context
                  .read<AdvertisementBloc>()
                  .add(const AdvertisementEvent.fetchAllListings());
              context.go('/home');
            },
            failure: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ErrorMessageUtil.getUserFriendlyMessage(msg),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red.shade300.withOpacity(0.9),
                ),
              );
            },
          );
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Form(
              key: _sellerFormKey,
              child: Column(
                children: [
                  _buildStepHeader(),
                  Offstage(
                    offstage: _step != 0,
                    child: PhotoStepWidget(categoryId: widget.categoryId),
                  ),
                  Offstage(
                    offstage: _step != 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  _formHeader(),
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 16,
                          tablet: 24,
                          largeTablet: 32,
                          desktop: 40,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          Text(
                            'Essential Details',
                            style: AppTextstyle.sectionTitleTextStyle.copyWith(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: AppTextstyle
                                        .sectionTitleTextStyle.fontSize ??
                                    18,
                                tablet: 24,
                                largeTablet: 30,
                                desktop: 36,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 20,
                              tablet: 28,
                              largeTablet: 36,
                              desktop: 44,
                            ),
                          ),
                          GetInput(
                            label: 'Price',
                            isNumberField: true,
                            onSaved: (val) =>
                                _price = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Title',
                            required: false,
                            onSaved: (val) => _title = val?.trim(),
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          LocationPickerWidget(
                            label: 'Location',
                            initialLocation: _location,
                            initialLatitude: _latitude,
                            initialLongitude: _longitude,
                            onLocationSelected:
                                (location, latitude, longitude) {
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
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          BlocBuilder<AddPostBloc, AddPostState>(
                            builder: (context, state) {
                              final bool isLoading = state.maybeWhen(
                                commercialVehicleTypesLoading: () => true,
                                orElse: () => false,
                              );
                              final String? errorText = state.maybeWhen(
                                commercialVehicleTypesFailure: (m) => m,
                                orElse: () => null,
                              );
                              final List<CommercialVehicleType> items =
                                  state.maybeWhen(
                                commercialVehicleTypesLoaded: (items) =>
                                    items.where((t) => t.isActive).toList(),
                                orElse: () => const [],
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildDropdown<CommercialVehicleType>(
                                    labelText: 'Commercial Vehicle Type',
                                    items: items,
                                    selectedValue: _selectedVehicleType,
                                    errorMsg: 'Please select a vehicle type',
                                    displayTextBuilder: (t) => t.displayName,
                                    onChanged: isLoading || errorText != null
                                        ? (_) {}
                                        : (val) {
                                            setState(() {
                                              _selectedVehicleType = val;
                                            });
                                          },
                                  ),
                                  if (isLoading)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Loading vehicle types...',
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  if (errorText != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        errorText,
                                        style: TextStyle(
                                            color: Colors.red.shade400),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          buildDropdown<String>(
                            labelText: 'Body Type',
                            items: _bodyTypeMap.keys.toList(),
                            selectedValue: _selectedBodyType,
                            errorMsg: 'Please select a body type',
                            onChanged: (val) {
                              setState(() {
                                _selectedBodyType = val;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
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
                            onChanged: (manufacturer) async {
                              setState(() {
                                _selectedManufacturer = manufacturer;
                                _selectedModel = null;
                                _models = [];
                                _selectedVariant = null;
                                _variants = [];
                              });

                              if (manufacturer != null) {
                                try {
                                  final models = await AddRepository()
                                      .fetchModelsByManufacturer(
                                          manufacturer.id);
                                  if (!mounted) return;
                                  setState(() => _models = models);
                                } catch (e) {
                                  debugPrint('Failed to load models: $e');
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Failed to load models')),
                                  );
                                }
                              }
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          buildSearchableDropdown<VehicleModel>(
                            labelText: 'Model',
                            items: _models,
                            selectedValue: _selectedModel,
                            getDisplayText: (item) => item.displayName,
                            enabled: _models.isNotEmpty &&
                                _selectedManufacturer != null,
                            onSearch: (query) async {
                              if (_selectedManufacturer == null) {
                                return [];
                              }
                              return await AddRepository()
                                  .fetchModelsByManufacturer(
                                _selectedManufacturer!.id,
                                search: query,
                              );
                            },
                            onChanged: (model) async {
                              setState(() {
                                _selectedModel = model;
                                _selectedVariant = null;
                                _variants = [];
                              });

                              if (model != null) {
                                try {
                                  final variants = await AddRepository()
                                      .fetchVariantsByModel(model.id);
                                  if (!mounted) return;
                                  setState(() => _variants = variants);
                                } catch (e) {
                                  debugPrint('Failed to load variants: $e');
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to load variants')),
                                  );
                                }
                              }
                            },
                            errorMsg: 'Please select a model',
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          _buildVariantDropdown(),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          buildSearchableDropdown<VehicleTransmissionType>(
                            labelText: 'Transmission Type',
                            items: _transmissionTypes,
                            selectedValue: _selectedtransmissionType,
                            getDisplayText: (item) => item.displayName,
                            errorMsg: 'Please select a transmission type',
                            onChanged: (transmissionType) async {
                              setState(() {
                                _selectedtransmissionType = transmissionType;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          buildSearchableDropdown<VehicleFuelType>(
                            labelText: 'Fuel Type',
                            items: _fuelTypes,
                            selectedValue: _selectedfuelType,
                            getDisplayText: (item) => item.displayName,
                            errorMsg: 'Please select a fuel type',
                            onChanged: (fuelType) async {
                              setState(() {
                                _selectedfuelType = fuelType;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Year',
                            isNumberField: true,
                            onSaved: (val) =>
                                _year = int.tryParse(val ?? '2023') ?? 2023,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Mileage (km)',
                            isNumberField: true,
                            onSaved: (val) =>
                                _mileage = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Color',
                            onSaved: (val) => _color = val ?? '',
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Payload Capacity',
                            isNumberField: true,
                            onSaved: (val) => _payloadCapacity =
                                int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Payload Unit',
                            onSaved: (val) => _payloadUnit = val ?? '',
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Axil Count',
                            isNumberField: true,
                            onSaved: (val) =>
                                _axilCount = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          CheckboxListTile(
                            value: _hasInsurance,
                            title: Text(
                              'Has Insurance',
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
                            onChanged: (val) {
                              setState(() {
                                _hasInsurance = val ?? false;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          CheckboxListTile(
                            value: _hasIFitness,
                            title: Text(
                              'Has Fitness',
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
                            onChanged: (val) {
                              setState(() {
                                _hasIFitness = val ?? false;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          CheckboxListTile(
                            value: _hasPermit,
                            title: Text(
                              'Has Permit',
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
                            onChanged: (val) {
                              setState(() {
                                _hasPermit = val ?? false;
                              });
                            },
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          GetInput(
                            label: 'Seating Capacity',
                            isNumberField: true,
                            onSaved: (val) => _seatingCapacity =
                                int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
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
                                    maxLines: 5,
                                    isDescription: true,
                                    onSaved: (val) => _description = val ?? '',
                                  ),
                                )
                              : GetInput(
                                  label: 'Description',
                                  isDescription: true,
                                  maxLines: 5,
                                  onSaved: (val) => _description = val ?? '',
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 15,
                      tablet: 20,
                      largeTablet: 26,
                      desktop: 32,
                    ),
                  ),
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 16,
                          tablet: 24,
                          largeTablet: 32,
                          desktop: 40,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          Text(
                            'Additional Features',
                            style: AppTextstyle.sectionTitleTextStyle.copyWith(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: AppTextstyle
                                        .sectionTitleTextStyle.fontSize ??
                                    18,
                                tablet: 24,
                                largeTablet: 30,
                                desktop: 36,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          buildFeatureCheckboxList(
                            allFeatures: _allFeatures,
                            selectedFeatures: _selectedFeatures,
                            onChanged: (updated) {
                              setState(() => _selectedFeatures = updated);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                  Offstage(
                    offstage: _step != 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Review your details and post',
                      style: AppTextstyle.sectionTitleTextStyle.copyWith(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile:
                              AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
                          tablet: 24,
                          largeTablet: 30,
                          desktop: 36,
                        ),
                      ),
                    ),
                  ),
                  _buildReviewSummary(),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 24,
                              largeTablet: 32,
                              desktop: 40,
                            ),
                          ),
                          child: SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 50,
                              tablet: 65,
                              largeTablet: 75,
                              desktop: 85,
                            ),
                            child: ElevatedButton(
                              onPressed: state.maybeWhen(
                                loading: () => () {
                                  SizedBox(
                                    height: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 20,
                                      tablet: 28,
                                      largeTablet: 34,
                                      desktop: 40,
                                    ),
                                    width: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 20,
                                      tablet: 28,
                                      largeTablet: 34,
                                      desktop: 40,
                                    ),
                                    child: CircularProgressIndicator(
                                      strokeWidth:
                                          GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 2,
                                        tablet: 2.5,
                                        largeTablet: 3,
                                        desktop: 3.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                orElse: () => _addAdvertisement,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.whiteColor,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    GetResponsiveSize.getResponsiveBorderRadius(
                                      context,
                                      mobile: 25,
                                      tablet: 30,
                                      largeTablet: 35,
                                      desktop: 40,
                                    ),
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Create Advertisement",
                                  style: AppTextstyle.buttonText.copyWith(
                                    fontSize:
                                        GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile:
                                          AppTextstyle.buttonText.fontSize ??
                                              16,
                                      tablet: 20,
                                      largeTablet: 24,
                                      desktop: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 30,
                            tablet: 40,
                            largeTablet: 50,
                            desktop: 60,
                          ),
                        ),
                      ],
                    ),
                  )
                      ],
                    ),
                  ),
                  _buildStepNav(),
                ],
              ),
            ),
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    const stepNames = ['Photos', 'Details', 'Review'];
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 24,
          largeTablet: 32,
          desktop: 40,
        ),
        vertical: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 12,
          tablet: 16,
          largeTablet: 20,
          desktop: 24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_step + 1} of 3',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 18,
                    largeTablet: 22,
                    desktop: 26,
                  ),
                ),
              ),
              Text(
                stepNames[_step],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 18,
                    largeTablet: 22,
                    desktop: 26,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 8,
              tablet: 12,
              largeTablet: 16,
              desktop: 20,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 4,
                      width: constraints.maxWidth * ((_step + 1) / 3),
                      color: AppColors.primaryColor,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Advances the step. Leaving Details (step 1) requires a valid form so
  /// the seller cannot reach Review with invalid data; saving here also
  /// populates the values shown in the Review summary.
  void _onNextPressed() {
    if (_step == 1) {
      final form = _sellerFormKey.currentState;
      if (form == null || !form.validate()) return;
      form.save();
    }
    if (_step >= 2) return;
    setState(() => _step++);
  }

  Widget _buildStepNav() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 24,
          largeTablet: 32,
          desktop: 40,
        ),
        vertical: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 12,
          tablet: 16,
          largeTablet: 20,
          desktop: 24,
        ),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 50,
                  tablet: 65,
                  largeTablet: 75,
                  desktop: 85,
                ),
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(
                          context,
                          mobile: 25,
                          tablet: 30,
                          largeTablet: 35,
                          desktop: 40,
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextstyle.buttonText.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: AppTextstyle.buttonText.fontSize ?? 16,
                        tablet: 20,
                        largeTablet: 24,
                        desktop: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_step > 0 && _step < 2)
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
          if (_step < 2)
            Expanded(
              child: SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 50,
                  tablet: 65,
                  largeTablet: 75,
                  desktop: 85,
                ),
                child: ElevatedButton(
                  onPressed: (_step == 0 && !_mediaBloc.state.hasImages)
                      ? null
                      : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(
                          context,
                          mobile: 25,
                          tablet: 30,
                          largeTablet: 35,
                          desktop: 40,
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: AppTextstyle.buttonText.copyWith(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: AppTextstyle.buttonText.fontSize ?? 16,
                        tablet: 20,
                        largeTablet: 24,
                        desktop: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- review

  String _photoSummary() {
    final media = _mediaBloc.state;
    final count = media.images.length;
    if (count == 0) return 'No photos';
    final label = count == 1 ? '1 photo' : '$count photos';
    if (media.hasFailed) return '$label · some failed';
    if (media.isUploading) return '$label · ${media.pendingCount} uploading…';
    return '$label · all uploaded';
  }

  Widget _reviewRow(String label, String? value) {
    final text = (value == null || value.trim().isEmpty) ? '—' : value;
    final fontSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 14,
      tablet: 18,
      largeTablet: 22,
      desktop: 26,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: AppColors.greyColor, fontSize: fontSize),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.blackColor,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact read-only summary shown on the Review step.
  Widget _buildReviewSummary() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 24,
          largeTablet: 32,
          desktop: 40,
        ),
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewRow('Photos', _photoSummary()),
          _reviewRow('Price', _price > 0 ? '₹ $_price' : null),
          _reviewRow('Location', _location),
          _reviewRow('Vehicle type', _selectedVehicleType?.displayName),
          _reviewRow('Body type', _selectedBodyType),
          _reviewRow('Manufacturer', _selectedManufacturer?.displayName),
          _reviewRow('Model', _selectedModel?.displayName),
          _reviewRow('Year', '$_year'),
        ],
      ),
    );
  }

  Widget _formHeader() {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 50,
        tablet: 70,
        largeTablet: 85,
        desktop: 100,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 16,
            tablet: 24,
            largeTablet: 32,
            desktop: 40,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Sell your ${widget.categoryTitle}",
                style: AppTextstyle.sellCategoryText.copyWith(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: AppTextstyle.sellCategoryText.fontSize ?? 18,
                    tablet: 24,
                    largeTablet: 30,
                    desktop: 36,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 20,
                tablet: 28,
                largeTablet: 36,
                desktop: 44,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push('/item-category');
              },
              child: Container(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 35,
                  tablet: 50,
                  largeTablet: 60,
                  desktop: 70,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 12,
                    tablet: 18,
                    largeTablet: 24,
                    desktop: 30,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 12,
                      largeTablet: 16,
                      desktop: 20,
                    ),
                  ),
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 1,
                      tablet: 1.5,
                      largeTablet: 2,
                      desktop: 2.5,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Change Category",
                    style: AppTextstyle.changeCategoryButtonTextStyle.copyWith(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: AppTextstyle
                                .changeCategoryButtonTextStyle.fontSize ??
                            14,
                        tablet: 18,
                        largeTablet: 22,
                        desktop: 26,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildFeatureCheckboxList({
    required List<String> allFeatures,
    required List<String> selectedFeatures,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 10,
        tablet: 16,
        largeTablet: 22,
        desktop: 28,
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
              onChanged: (bool? selected) {
                final updated = List<String>.from(selectedFeatures);
                if (selected == true) {
                  updated.add(feature);
                } else {
                  updated.remove(feature);
                }
                onChanged(updated);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 4,
                tablet: 8,
                largeTablet: 12,
                desktop: 16,
              ),
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
