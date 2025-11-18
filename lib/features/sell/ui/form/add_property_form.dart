import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
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
  String? _title;
  String _description = '';
  int _price = 0;
  String _location = '';
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _imageFiles = [];
  final List<String> _uploadedUrls = [];

  // Helper method to check if property type requires only basic fields
  bool _isRestrictedPropertyType() {
    return _selectedPropertyType == 'plot' ||
        _selectedPropertyType == 'commercial' ||
        _selectedPropertyType == 'office' ||
        _selectedPropertyType == 'shop' ||
        _selectedPropertyType == 'warehouse';
  }

  // Video upload variables
  Uint8List? _videoFile;
  String? _uploadedVideoUrl;
  String? _videoFileName;
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

  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _videoFileName = null;
      _uploadedVideoUrl = null;
    });
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
  String? _listingType;
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
    await _uploadVideo(); // S3 Video Upload

    final ad = <String, dynamic>{
      "description": _description,
      "price": _price,
      "location": _location,
      "images": _uploadedUrls,
      "link": _uploadedVideoUrl, // Video URL
      "propertyType": _selectedPropertyType,
      "areaSqft": _areasqft,
    };

    // Add title if provided
    if (_title != null && _title!.trim().isNotEmpty) {
      ad["title"] = _title!.trim();
    }

    // Add listingType if selected (convert to lowercase)
    // For plot, always set to 'sell'
    if (_selectedPropertyType == 'plot') {
      ad["listingType"] = 'sell';
    } else if (_listingType != null && _listingType!.isNotEmpty) {
      ad["listingType"] = _listingType!.toLowerCase();
    }

    // Only include bedrooms and bathrooms for non-restricted property types
    if (!_isRestrictedPropertyType()) {
      ad["bedrooms"] = _bedrooms;
      ad["bathrooms"] = _bathrooms;
    }

    // Only include floor, isFurnished, hasGarden for non-restricted property types
    // (plot and warehouse don't need these)
    if (_selectedPropertyType != 'plot' &&
        _selectedPropertyType != 'warehouse') {
      ad["floor"] = _floor;
      ad["isFurnished"] = _isFurnished;
      ad["hasGarden"] = _hasGarden;
    }

    // hasParking is shown for all except plot
    if (_selectedPropertyType != 'plot') {
      ad["hasParking"] = _hasParking;
    }

    // Amenities are only for non-plot property types
    if (_selectedPropertyType != 'plot') {
      ad["amenities"] = _selectedAmenities;
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
                SnackBar(
                    content:
                        Text(ErrorMessageUtil.getUserFriendlyMessage(msg))),
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
                            labelText: 'Property Type',
                            items: _propertyTypeMap.keys.toList(),
                            selectedValue: _selectedPropertyType,
                            errorMsg: 'Please select a property type',
                            onChanged: (val) {
                              setState(() {
                                _selectedPropertyType = val;
                                // Auto-set listingType to 'Sell' for plot
                                if (val == 'plot') {
                                  _listingType = 'Sell';
                                }
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
                          _buildListingTypeDropdown(),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 10,
                              tablet: 16,
                              largeTablet: 22,
                              desktop: 28,
                            ),
                          ),
                          if (_selectedPropertyType != 'plot' &&
                              _selectedPropertyType != 'commercial' &&
                              _selectedPropertyType != 'office' &&
                              _selectedPropertyType != 'shop' &&
                              _selectedPropertyType != 'warehouse') ...[
                            GetInput(
                              label: 'Bedrooms',
                              isNumberField: true,
                              required: !_isRestrictedPropertyType(),
                              onSaved: (val) =>
                                  _bedrooms = int.tryParse(val ?? '0') ?? 0,
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
                              label: 'Bathrooms',
                              isNumberField: true,
                              required: !_isRestrictedPropertyType(),
                              onSaved: (val) =>
                                  _bathrooms = int.tryParse(val ?? '0') ?? 0,
                            ),
                          ],
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
                            label: 'Area Sqft',
                            isNumberField: true,
                            onSaved: (val) =>
                                _areasqft = int.tryParse(val ?? '0') ?? 0,
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
                          if (_selectedPropertyType != 'plot' &&
                              _selectedPropertyType != 'warehouse') ...[
                            GetInput(
                              label: 'Floor',
                              isNumberField: true,
                              required: !_isRestrictedPropertyType(),
                              onSaved: (val) =>
                                  _floor = int.tryParse(val ?? '0') ?? 0,
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
                              value: _isFurnished,
                              title: Text(
                                'Is Furnished?',
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
                                  _isFurnished = val ?? false;
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
                          ],
                          if (_selectedPropertyType != 'plot') ...[
                            CheckboxListTile(
                              value: _hasParking,
                              title: Text(
                                'Has Parking?',
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
                                  _hasParking = val ?? false;
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
                          ],
                          if (_selectedPropertyType != 'plot' &&
                              _selectedPropertyType != 'warehouse') ...[
                            CheckboxListTile(
                              value: _hasGarden,
                              title: Text(
                                'Has Garden?',
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
                                  _hasGarden = val ?? false;
                                });
                              },
                            ),
                          ],
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
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 15,
                      tablet: 20,
                      largeTablet: 26,
                      desktop: 32,
                    ),
                  ),
                  if (_selectedPropertyType != 'plot') ...[
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
                              'Amenities',
                              style:
                                  AppTextstyle.sectionTitleTextStyle.copyWith(
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
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
                            buildAmenitiesCheckboxList(
                              allFeatures: _selectedPropertyType == 'warehouse'
                                  ? ['Security', 'Lift', '24/7 Water Supply']
                                  : _allAmenities,
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
                  ],
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
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 20,
                      tablet: 28,
                      largeTablet: 36,
                      desktop: 44,
                    ),
                  ),
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
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 30,
                      tablet: 40,
                      largeTablet: 50,
                      desktop: 60,
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

  Widget buildAmenitiesCheckboxList({
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

  Widget _buildListingTypeDropdown() {
    final isPlot = _selectedPropertyType == 'plot';
    // Ensure listingType is set to 'Sell' for plot
    final displayValue = isPlot ? 'Sell' : _listingType;

    final dropdown = DropdownButtonFormField<String>(
      decoration:
          CommonDecoration.textFieldDecoration(labelText: 'Listing Type')
              .copyWith(
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
      ),
      value: displayValue,
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
        color: isPlot ? Colors.grey : Colors.black,
      ),
      items: ['Rent', 'Sell'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Colors.black,
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 24,
                desktop: 28,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: isPlot
          ? null
          : (val) {
              setState(() {
                _listingType = val;
              });
            },
      validator: (value) => null, // Optional field, no validation
    );

    // Wrap in SizedBox for tablets and above to match textbox height
    if (GetResponsiveSize.isTablet(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 0,
              tablet: 65,
              largeTablet: 75,
              desktop: 85,
            ),
            child: dropdown,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [dropdown],
    );
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
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
            ..._imageFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final bytes = entry.value;
              return Stack(
                children: [
                  Image.memory(
                    bytes,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
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
              child: Row(
                children: [
                  Expanded(
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
                  if (_videoFileName != null)
                    GestureDetector(
                      onTap: _removeVideo,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
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
}
