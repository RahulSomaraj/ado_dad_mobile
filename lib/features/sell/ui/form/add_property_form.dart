import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AddPropertyForm extends StatefulWidget {
  final String categoryTitle;
  final String categoryId;
  const AddPropertyForm(
      {super.key, required this.categoryTitle, required this.categoryId});

  @override
  State<AddPropertyForm> createState() => _AddPropertyFormState();
}

class _AddPropertyFormState extends State<AddPropertyForm> {
  final GlobalKey<FormState> _sellerFormKey = GlobalKey<FormState>();
  String _description = '';
  int _price = 0;
  String _location = '';
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _imageFiles = [];
  final List<String> _uploadedUrls = [];
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

  final List<String> _allAmenities = [
    "Gym",
    "Swimming Pool",
    "Security",
    "Lift",
    "24/7 Water Supply"
  ];

  List<String> _selectedAmenities = [];
  final Map<String, String> _propertyTypeMap = {
    'apartment': 'apartment',
    'house': 'house',
    'villa': 'villa',
    'plot': 'plot',
    'commercial': 'commercial',
    'office': 'office',
    'shop': 'shop',
    'warehouse': 'warehouse',
  };

  String? _selectedPropertyType;
  int _bedrooms = 0;
  int _bathrooms = 0;
  int _areasqft = 0;
  int _floor = 0;
  bool _isFurnished = true;
  bool _hasParking = true;
  bool _hasGarden = true;

  void _addAdvertisement() async {
    if (!_sellerFormKey.currentState!.validate()) return;
    _sellerFormKey.currentState!.save();

    await _uploadImages(); // S3 Upload

    final ad = {
      "description": _description,
      "price": _price,
      "location": _location,
      "images": _uploadedUrls,
      "propertyType": _selectedPropertyType,
      "bedrooms": _bedrooms,
      "bathrooms": _bathrooms,
      "areaSqft": _areasqft,
      "floor": _floor,
      "isFurnished": _isFurnished,
      "hasParking": _hasParking,
      "hasGarden": _hasGarden,
      "amenities": _selectedAmenities,
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
                          buildDropdown<String>(
                            labelText: 'Property Type',
                            items: _propertyTypeMap.keys.toList(),
                            selectedValue: _selectedPropertyType,
                            errorMsg: 'Please select a property type',
                            onChanged: (val) {
                              setState(() {
                                _selectedPropertyType = val;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Bedrooms',
                            isNumberField: true,
                            onSaved: (val) =>
                                _bedrooms = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Bathrooms',
                            isNumberField: true,
                            onSaved: (val) =>
                                _bathrooms = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Area Sqft',
                            isNumberField: true,
                            onSaved: (val) =>
                                _areasqft = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Floor',
                            isNumberField: true,
                            onSaved: (val) =>
                                _floor = int.tryParse(val ?? '0') ?? 0,
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _isFurnished,
                            title: const Text('Is Furnished?'),
                            onChanged: (val) {
                              setState(() {
                                _isFurnished = val ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _hasParking,
                            title: const Text('Has Parking?'),
                            onChanged: (val) {
                              setState(() {
                                _hasParking = val ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          CheckboxListTile(
                            value: _hasGarden,
                            title: const Text('Has Garden?'),
                            onChanged: (val) {
                              setState(() {
                                _hasGarden = val ?? false;
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
                            'Amenities',
                            style: AppTextstyle.sectionTitleTextStyle,
                          ),
                          const SizedBox(height: 10),
                          buildAmenitiesCheckboxList(
                            allFeatures: _allAmenities,
                            selectedFeatures: _selectedAmenities,
                            onChanged: (updated) {
                              setState(() => _selectedAmenities = updated);
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

  Widget buildAmenitiesCheckboxList({
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
}
