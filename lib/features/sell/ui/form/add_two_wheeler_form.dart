import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
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
  int _price = 0;
  String _location = '';
  Map<String, String> vehicleTypeMap = {
    'two_wheeler': 'Two Wheeler',
    'four_wheeler': 'Four Wheeler',
  };
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

  final List<String> _allFeatures = [
    "Digital Console",
    "LED Headlight",
    "Mobile Charging Port",
    "External Fuel Filler",
    "Combi Brake System",
  ];

  List<String> _selectedFeatures = [];

  void _addAdvertisement() async {
    if (!_sellerFormKey.currentState!.validate()) return;
    _sellerFormKey.currentState!.save();

    await _uploadImages(); // S3 Upload

    final ad = {
      "vehicleType": "two_wheeler",
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
        preferredSize: Size.fromHeight(40.0),
        child: AppBar(
          backgroundColor: AppColors.whiteColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              context.pop();
            },
          ),
          title: Text(
            'Post your Ad',
            style: AppTextstyle.appbarText,
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
              // ✅ Refresh home listings
              context
                  .read<AdvertisementBloc>()
                  .add(const AdvertisementEvent.fetchAllListings());
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
                          SizedBox(height: 10),
                          Text(
                            'Essential Details',
                            style: AppTextstyle.sectionTitleTextStyle,
                          ),
                          SizedBox(height: 20),
                          GetInput(
                            label: 'Price',
                            isNumberField: true,
                            onSaved: (val) =>
                                _price = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Location',
                            onSaved: (val) => _location = val ?? '',
                          ),
                          SizedBox(height: 10),
                          IgnorePointer(
                            child: buildDropdown<String>(
                              labelText: 'Vehicle Type',
                              items: ['two_wheeler'],
                              selectedValue: 'two_wheeler',
                              onChanged: (_) {},
                              errorMsg: '',
                            ),
                          ),
                          SizedBox(height: 10),
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
                          SizedBox(height: 10),
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
                          SizedBox(height: 10),
                          buildDropdown<VehicleVariant>(
                            labelText: 'Variant *',
                            items: _variants,
                            selectedValue: _selectedVariant,
                            onChanged: (val) {
                              setState(() => _selectedVariant = val);
                            },
                            errorMsg: 'Please select a variant',
                          ),
                          SizedBox(height: 10),
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
                          SizedBox(height: 10),
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
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Year',
                            isNumberField: true,
                            onSaved: (val) =>
                                _year = int.tryParse(val ?? '2023') ?? 2023,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Mileage (km)',
                            isNumberField: true,
                            onSaved: (val) =>
                                _mileage = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Color',
                            onSaved: (val) => _color = val ?? '',
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _isFirstOwner,
                            title: const Text('Is First Owner'),
                            onChanged: (val) {
                              setState(() {
                                _isFirstOwner = val ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _hasInsurance,
                            title: const Text('Has Insurance'),
                            onChanged: (val) {
                              setState(() {
                                _hasInsurance = val ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _hasRcBook,
                            title: const Text('Has RC Book'),
                            onChanged: (val) {
                              setState(() {
                                _hasRcBook = val ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          GetInput(
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
                            style: AppTextstyle.sectionTitleTextStyle,
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
                            style: AppTextstyle.sectionTitleTextStyle,
                          ),
                          const SizedBox(height: 20),
                          _buildImagePicker(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state.maybeWhen(
                          loading: () => () {
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            );
                          },
                          orElse: () => _addAdvertisement,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.whiteColor,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Create Add",
                            style: AppTextstyle.buttonText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30)
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
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Sell your ${widget.categoryTitle}",
                style: AppTextstyle.sellCategoryText,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                context.go('/item-category');
              },
              child: Container(
                height: 35,
                width: 135,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Change Category",
                    style: AppTextstyle.changeCategoryButtonTextStyle,
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

  Widget buildFeatureCheckboxList({
    required List<String> allFeatures,
    required List<String> selectedFeatures,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
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
            ),
            Text(feature),
          ],
        );
      }).toList(),
    );
  }
}
