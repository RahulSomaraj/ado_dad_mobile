import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/searchable_dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/location_picker_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/media_upload/media_upload_bloc.dart';
import 'package:ado_dad_user/features/sell/ui/form/widgets/photo_step_widget.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddTwoWheelerForm extends StatefulWidget {
  final String categoryTitle;
  final String categoryId;

  const AddTwoWheelerForm({
    super.key,
    required this.categoryTitle,
    required this.categoryId,
  });

  @override
  State<AddTwoWheelerForm> createState() => _AddTwoWheelerFormState();
}

class _AddTwoWheelerFormState extends State<AddTwoWheelerForm> {
  final GlobalKey<FormState> _sellerFormKey = GlobalKey<FormState>();
  int _step = 0; // 0 = Details, 1 = Photos, 2 = Review
  String? _title;
  int _price = 0;
  String _location = '';
  double? _latitude;
  double? _longitude;
  List<VehicleManufacturer> _manufacturers = [];
  VehicleManufacturer? _selectedManufacturer;
  List<VehicleModel> _models = [];
  VehicleModel? _selectedModel;
  int _year = 2023;
  int _mileage = 0;
  List<VehicleTransmissionType> _transmissionTypes = [];
  VehicleTransmissionType? _selectedtransmissionType;
  List<VehicleFuelType> _fuelTypes = [];
  VehicleFuelType? _selectedfuelType;
  String _color = '';
  bool _isFirstOwner = false;
  bool _hasInsurance = false;
  bool _hasRcBook = false;
  String _description = '';
  /// Photos/video live here and upload to S3 as soon as they are picked.
  late final MediaUploadBloc _mediaBloc =
      MediaUploadBloc(repository: AddRepository());


  @override
  void dispose() {
    _mediaBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadManufacturers();
    _loadTransmissionTypes();
    _loadFuelTypes();
  }

  Future<void> _loadManufacturers() async {
    // For two_wheeler category, fetch manufacturers with vehicleCategory 'two_wheeler'
    final manufacturers = await AddRepository().fetchManufacturers(
      vehicleCategory: 'two_wheeler',
    );
    setState(() {
      _manufacturers = manufacturers;
    });
  }

  Future<void> _loadTransmissionTypes() async {
    try {
      final transmissionTypes =
          await AddRepository().fetchVehicleTransmissionTypes();
      if (!mounted) return;
      setState(() {
        _transmissionTypes = transmissionTypes;
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
      final fuelTypes = await AddRepository().fetchVehicleFuelTypes();
      if (!mounted) return;
      setState(() {
        _fuelTypes = fuelTypes;
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

  final List<String> _allFeatures = [
    "Digital Console",
    "LED Headlight",
    "Mobile Charging Port",
    "External Fuel Filler",
    "Combi Brake System",
  ];

  List<String> _selectedFeatures = [];

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
      "vehicleType": "two_wheeler",
      "price": _price,
      "location": _location,
      if (_latitude != null) "latitude": _latitude,
      if (_longitude != null) "longitude": _longitude,
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "year": _year,
      "mileage": _mileage,
      "color": _color,
      "isFirstOwner": _isFirstOwner,
      "hasInsurance": _hasInsurance,
      "hasRcBook": _hasRcBook,
      "description": _description,
      "images": media.imageUrls,
      "link": media.videoUrl,
      "fuelTypeId": _selectedfuelType!.id,
      "transmissionTypeId": _selectedtransmissionType!.id,
      "additionalFeatures": _selectedFeatures,
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
    print('Category Title: ${widget.categoryTitle}');
    print('Category Title: ${widget.categoryId}');
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
                  Divider(thickness: 2),
                  _formHeader(),
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                          buildSearchableDropdown<VehicleManufacturer>(
                            labelText: 'Manufacturer',
                            items: _manufacturers,
                            selectedValue: _selectedManufacturer,
                            errorMsg: 'Please select a manufacturer',
                            getDisplayText: (item) => item.displayName,
                            onSearch: (query) async {
                              return await AddRepository().fetchManufacturers(
                                search: query,
                                vehicleCategory: 'two_wheeler',
                              );
                            },
                            onChanged: (manufacturer) async {
                              setState(() {
                                _selectedManufacturer = manufacturer;
                                _selectedModel = null;
                                _models = [];
                              });

                              if (manufacturer != null) {
                                final models = await AddRepository()
                                    .fetchModelsByManufacturer(manufacturer.id);
                                setState(() => _models = models);
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
                              });
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
                          CheckboxListTile(
                            value: _isFirstOwner,
                            title: Text(
                              'Is First Owner',
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
                                _isFirstOwner = val ?? false;
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
                            value: _hasRcBook,
                            title: Text(
                              'Has RC Book',
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
                                _hasRcBook = val ?? false;
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
                  SizedBox(height: 15),
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      : () => setState(() => _step++),
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
}
