import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/common/widgets/location_picker_widget.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/media_upload/media_upload_bloc.dart';
import 'package:ado_dad_user/features/sell/ui/form/widgets/photo_step_widget.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  int _step = 0; // 0 = Photos, 1 = Details, 2 = Review
  String? _title;
  String _description = '';
  int _price = 0;
  String _location = '';
  double? _latitude;
  double? _longitude;
  /// Photos/video live here and upload to S3 as soon as they are picked.
  late final MediaUploadBloc _mediaBloc =
      MediaUploadBloc(repository: AddRepository());

  // Helper method to check if property type requires only basic fields
  bool _isRestrictedPropertyType() {
    return _selectedPropertyType == 'plot' ||
        _selectedPropertyType == 'commercial' ||
        _selectedPropertyType == 'office' ||
        _selectedPropertyType == 'shop' ||
        _selectedPropertyType == 'warehouse';
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
  bool _isFurnished = false;
  bool _hasParking = false;
  bool _hasGarden = false;

  @override
  void dispose() {
    _mediaBloc.close();
    super.dispose();
  }

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

    final ad = <String, dynamic>{
      "description": _description,
      "price": _price,
      "location": _location,
      if (_latitude != null) "latitude": _latitude,
      if (_longitude != null) "longitude": _longitude,
      "images": media.imageUrls,
      "link": media.videoUrl,
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
          _reviewRow('Property type', _selectedPropertyType),
          _reviewRow(
            'Listing type',
            _selectedPropertyType == 'plot' ? 'Sell' : _listingType,
          ),
          _reviewRow('Area (sqft)', _areasqft > 0 ? '$_areasqft' : null),
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

}
