import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddPrivateVehicleForm extends StatefulWidget {
  final String categoryTitle;
  final String categoryId;
  const AddPrivateVehicleForm(
      {super.key, required this.categoryTitle, required this.categoryId});

  @override
  State<AddPrivateVehicleForm> createState() => _AddPrivateVehicleFormState();
}

class _AddPrivateVehicleFormState extends State<AddPrivateVehicleForm> {
  final GlobalKey<FormState> _sellerFormKey = GlobalKey<FormState>();
  int _price = 0;
  String _location = '';
  final Map<String, String> _vehicleTypeMap = {
    'two_wheeler': 'Two Wheeler',
    'four_wheeler': 'Four Wheeler',
  };

  String? _selectedVehicleType;

  List<VehicleManufacturer> _manufacturers = [];
  VehicleManufacturer? _selectedManufacturer;
  List<VehicleModel> _models = [];
  VehicleModel? _selectedModel;
  List<VehicleVariant> _variants = [];
  VehicleVariant? _selectedVariant;
  int _year = 2023;
  int _mileage = 0;
  List<VehicleTransmissionType> _transmissionTypes = [];
  VehicleTransmissionType? _selectedtransmissionType;
  List<VehicleFuelType> _fuelTypes = [];
  VehicleFuelType? _selectedfuelType;
  String _color = '';
  bool _isFirstOwner = true;
  bool _hasInsurance = true;
  bool _hasRcBook = true;
  String _description = '';
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _imageFiles = [];
  final List<String> _uploadedUrls = [];

  // Video upload variables
  Uint8List? _videoFile;
  String? _uploadedVideoUrl;
  String? _videoFileName;

  @override
  void initState() {
    super.initState();
    _loadManufacturers();
    _loadTransmissionTypes();
    _loadFuelTypes();
  }

  Future<void> _loadManufacturers() async {
    final manufacturers = await AddRepository().fetchManufacturers();
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

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _imageFiles.add(bytes);
      }
      setState(() {});
    }
  }

  Future<void> _uploadImages() async {
    _uploadedUrls.clear();
    for (final file in _imageFiles) {
      final url = await AddRepository().uploadImageToS3(file);
      if (url != null) _uploadedUrls.add(url);
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _videoFile = bytes;
        _videoFileName = picked.name;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile != null) {
      final url = await AddRepository().uploadVideoToS3(_videoFile!);
      if (url != null) {
        setState(() {
          _uploadedVideoUrl = url;
        });
      }
    }
  }

  final List<String> _allFeatures = [
    "Sunroof",
    "Leather Seats",
    "Navigation System",
    "Reverse Camera",
    "Bluetooth Connectivity"
  ];

  List<String> _selectedFeatures = [];

  void _addAdvertisement() async {
    if (!_sellerFormKey.currentState!.validate()) return;
    _sellerFormKey.currentState!.save();

    await _uploadImages(); // S3 Upload
    await _uploadVideo(); // S3 Video Upload

    final ad = {
      "vehicleType": _selectedVehicleType,
      "price": _price,
      "location": _location,
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,
      "year": _year,
      "mileage": _mileage,
      "color": _color,
      "isFirstOwner": _isFirstOwner,
      "hasInsurance": _hasInsurance,
      "hasRcBook": _hasRcBook,
      "description": _description,
      "images": _uploadedUrls,
      "link": _uploadedVideoUrl, // Video URL
      "fuelTypeId": _selectedfuelType!.id,
      "transmissionTypeId": _selectedtransmissionType!.id,
      "additionalFeatures": _selectedFeatures,
    };

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
      body: BlocConsumer<AddPostBloc, AddPostState>(
        listener: (context, state) {
          state.whenOrNull(
            success: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Ad posted successfully")),
              );
              context.go('/home');
            },
            failure: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ Failed: $msg")),
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
                            label: 'Location',
                            onSaved: (val) => _location = val ?? '',
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
                            labelText: 'Vehicle Type *',
                            items: _vehicleTypeMap.keys.toList(),
                            selectedValue: _selectedVehicleType,
                            errorMsg: 'Please select a vehicle type',
                            onChanged: (val) {
                              setState(() {
                                _selectedVehicleType = val;
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
                          buildDropdown<VehicleManufacturer>(
                            labelText: 'Manufacturer *',
                            items: _manufacturers,
                            selectedValue: _selectedManufacturer,
                            errorMsg: 'Please select a manufacturer',
                            onChanged: (manufacturer) async {
                              setState(() {
                                _selectedManufacturer = manufacturer;
                                _selectedModel = null;
                                _models = [];
                                _selectedVariant = null;
                                _variants = [];
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
                          buildDropdown<VehicleModel>(
                            labelText: 'Model *',
                            items: _models,
                            selectedValue: _selectedModel,
                            onChanged: (model) async {
                              setState(() {
                                _selectedModel = model;
                                _selectedVariant = null;
                                _variants = [];
                              });

                              if (model != null) {
                                final variants = await AddRepository()
                                    .fetchVariantsByModel(model.id);
                                setState(() => _variants = variants);
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
                          buildDropdown<VehicleTransmissionType>(
                            labelText: 'Transmission Type',
                            items: _transmissionTypes,
                            selectedValue: _selectedtransmissionType,
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
                          buildDropdown<VehicleFuelType>(
                            labelText: 'Fuel Type',
                            items: _fuelTypes,
                            selectedValue: _selectedfuelType,
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
                                    maxLines: 5,
                                    onSaved: (val) => _description = val ?? '',
                                  ),
                                )
                              : GetInput(
                                  label: 'Description',
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
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
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
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Upload Images',
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
                          _buildImagePicker(),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 20,
                              tablet: 28,
                              largeTablet: 36,
                              desktop: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Video Upload Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(
                          context,
                          mobile: 12,
                          tablet: 16,
                          largeTablet: 20,
                          desktop: 24,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 1,
                            tablet: 1.5,
                            largeTablet: 2,
                            desktop: 2.5,
                          ),
                          blurRadius: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 5,
                            tablet: 7,
                            largeTablet: 9,
                            desktop: 11,
                          ),
                          offset: Offset(
                            0,
                            GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 2,
                              tablet: 3,
                              largeTablet: 4,
                              desktop: 5,
                            ),
                          ),
                        ),
                      ],
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
                            'Upload Video',
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
                          _buildVideoPicker(),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 20,
                              tablet: 28,
                              largeTablet: 36,
                              desktop: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  ),
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 30,
                      tablet: 40,
                      largeTablet: 50,
                      desktop: 60,
                    ),
                  )
                ],
              ),
            ),
          );
        },
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._imageFiles.map((bytes) => Image.memory(
                  bytes,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade300,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Container(
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 56,
        tablet: 75,
        largeTablet: 90,
        desktop: 105,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 1,
            tablet: 1.5,
            largeTablet: 2,
            desktop: 2.5,
          ),
        ),
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 8,
            tablet: 12,
            largeTablet: 16,
            desktop: 20,
          ),
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Text field showing filename
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 24,
                  largeTablet: 32,
                  desktop: 40,
                ),
              ),
              child: Text(
                _videoFileName ?? 'No video selected',
                style: TextStyle(
                  color: _videoFileName != null
                      ? Colors.black87
                      : Colors.grey.shade500,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 24,
                    desktop: 28,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Choose File button
          Container(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 56,
              tablet: 75,
              largeTablet: 90,
              desktop: 105,
            ),
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 120,
              tablet: 160,
              largeTablet: 200,
              desktop: 240,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(
                    context,
                    mobile: 8,
                    tablet: 12,
                    largeTablet: 16,
                    desktop: 20,
                  ),
                ),
                bottomRight: Radius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(
                    context,
                    mobile: 8,
                    tablet: 12,
                    largeTablet: 16,
                    desktop: 20,
                  ),
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickVideo,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 12,
                      largeTablet: 16,
                      desktop: 20,
                    ),
                  ),
                  bottomRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 12,
                      largeTablet: 16,
                      desktop: 20,
                    ),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _videoFileName != null ? Icons.edit : Icons.upload_file,
                        color: Colors.black,
                        size: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 18,
                          tablet: 24,
                          largeTablet: 28,
                          desktop: 32,
                        ),
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
                        _videoFileName != null ? 'Change' : 'Choose File',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 18,
                            largeTablet: 22,
                            desktop: 26,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final dropdown = DropdownButtonFormField<VehicleVariant>(
      decoration:
          CommonDecoration.textFieldDecoration(labelText: 'Variant *').copyWith(
        labelStyle: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 16.0,
            tablet: 20.0,
            largeTablet: 22.0,
            desktop: 24.0,
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
      ),
      value: _selectedVariant,
      dropdownColor: Colors.white,
      isExpanded: true,
      iconSize: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 24,
        tablet: 28,
        largeTablet: 32,
        desktop: 36,
      ),
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16.0,
          tablet: 20.0,
          largeTablet: 22.0,
          desktop: 24.0,
        ),
      ),
      items: _variants.map((VehicleVariant variant) {
        return DropdownMenuItem<VehicleVariant>(
          value: variant,
          child: Text(
            variant.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedVariant = val);
      },
      validator: (value) => value == null ? 'Please select a variant' : null,
    );

    // Wrap in SizedBox only for tablets and above to match GetInput height
    if (GetResponsiveSize.isTablet(context)) {
      return SizedBox(
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 0,
          tablet: 65,
          largeTablet: 75,
          desktop: 85,
        ),
        child: dropdown,
      );
    }
    return dropdown;
  }
}
