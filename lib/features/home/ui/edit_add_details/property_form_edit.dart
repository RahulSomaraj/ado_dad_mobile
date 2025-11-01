import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:image_picker/image_picker.dart';

class PropertyFormEdit extends StatefulWidget {
  final AddModel ad;
  const PropertyFormEdit({super.key, required this.ad});

  @override
  State<PropertyFormEdit> createState() => _PropertyFormEditState();
}

class _PropertyFormEditState extends State<PropertyFormEdit> {
  final _formKey = GlobalKey<FormState>();

  // controllers (text fields)
  late final TextEditingController _priceCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _bedroomsCtrl;
  late final TextEditingController _bathroomsCtrl;
  late final TextEditingController _descCtrl;

  // toggles
  bool _isFurnished = false;
  bool _hasParking = false;
  bool _hasGarden = false;

  // dropdowns & chips
  final Map<String, String> _propertyTypeMap = const {
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

  final List<String> _allAmenities = const [
    "Gym",
    "Swimming Pool",
    "Security",
    "Lift",
    "24/7 Water Supply",
  ];
  late List<String> _selectedAmenities;

  // images
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _newImageFiles = []; // newly picked but not uploaded
  late List<String> _imageUrls; // existing + uploaded

  // video upload variables
  Uint8List? _newVideoFile; // newly picked video
  String? _uploadedVideoUrl; // uploaded video URL
  String? _videoFileName;
  late String? _existingVideoUrl; // existing video from ad

  @override
  void initState() {
    super.initState();

    // Prefill from ad
    _priceCtrl = TextEditingController(text: widget.ad.price.toString());
    _locationCtrl = TextEditingController(text: widget.ad.location);
    _descCtrl = TextEditingController(text: widget.ad.description);

    _selectedPropertyType = widget.ad.propertyType;
    _bedroomsCtrl =
        TextEditingController(text: (widget.ad.bedrooms ?? 0).toString());
    _bathroomsCtrl =
        TextEditingController(text: (widget.ad.bathrooms ?? 0).toString());
    _areaCtrl =
        TextEditingController(text: (widget.ad.areaSqft ?? 0).toString());
    _floorCtrl = TextEditingController(text: (widget.ad.floor ?? 0).toString());

    _isFurnished = widget.ad.isFurnished ?? false;
    _hasParking = widget.ad.hasParking ?? false;
    _hasGarden = widget.ad.hasGarden ?? false;

    _selectedAmenities = List<String>.from(widget.ad.additionalFeatures ?? []);
    _imageUrls = List<String>.from(widget.ad.images);
    _existingVideoUrl = widget.ad.link?.isNotEmpty == true
        ? widget.ad.link
        : null; // existing video URL
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _areaCtrl.dispose();
    _floorCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _newImageFiles.add(bytes);
      }
      setState(() {});
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newVideoFile = bytes;
        _videoFileName = picked.name;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_newVideoFile != null) {
      final url = await AddRepository().uploadVideoToS3(_newVideoFile!);
      if (url != null) {
        setState(() {
          _uploadedVideoUrl = url;
        });
      }
    }
  }

  Future<void> _uploadNewImages() async {
    if (_newImageFiles.isEmpty) return;
    final repo = AddRepository();
    for (final file in _newImageFiles) {
      final url = await repo.uploadImageToS3(file);
      if (url != null) _imageUrls.add(url);
    }
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await _uploadNewImages();
    await _uploadVideo();

    // Build property update payload (match your POST keys)
    final payload = <String, dynamic>{
      "price": int.tryParse(_priceCtrl.text.trim()),
      "location": _locationCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "images": _imageUrls,
      "propertyType": _selectedPropertyType,
      "bedrooms": int.tryParse(_bedroomsCtrl.text.trim()) ?? 0,
      "bathrooms": int.tryParse(_bathroomsCtrl.text.trim()) ?? 0,
      "areaSqft": int.tryParse(_areaCtrl.text.trim()) ?? 0,
      "floor": int.tryParse(_floorCtrl.text.trim()) ?? 0,
      "isFurnished": _isFurnished,
      "hasParking": _hasParking,
      "hasGarden": _hasGarden,
      "amenities": _selectedAmenities,
      "link": _uploadedVideoUrl ?? _existingVideoUrl, // Video URL
    };

    // Optional: drop null/empty string keys to avoid blank-overwrites
    payload.removeWhere(
      (k, v) => v == null || (v is String && v.trim().isEmpty),
    );

    debugPrint('PROPERTY UPDATE PAYLOAD => $payload');

    context.read<AdEditBloc>().add(
          AdEditEvent.submit(
            adId: widget.ad.id,
            category:
                widget.ad.category.isNotEmpty ? widget.ad.category : 'property',
            payload: payload,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Property Details',
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
              saving: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving...')),
              ),
              success: (updated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Saved')),
                );
                context
                    .read<AdvertisementBloc>()
                    .add(const AdvertisementEvent.fetchAllListings());
                context.go('/home');
              },
              failure: (msg) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Failed: $msg')),
                );
              },
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
                  // ===== Essential Details =====
                  Text(
                    'Essential Details',
                    style: AppTextstyle.sectionTitleTextStyle.copyWith(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile:
                            AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
                        tablet: 22,
                        largeTablet: 26,
                        desktop: 30,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 12,
                          tablet: 16,
                          largeTablet: 20,
                          desktop: 24)),

                  GetInput(
                    label: 'Price',
                    isNumberField: true,
                    controller: _priceCtrl,
                    // validator: (v) =>
                    //     (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),

                  GetInput(
                    label: 'Location',
                    controller: _locationCtrl,
                    // validator: (v) =>
                    //     (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),

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
                  const SizedBox(height: 10),

                  GetInput(
                    label: 'Bedrooms',
                    isNumberField: true,
                    controller: _bedroomsCtrl,
                  ),
                  const SizedBox(height: 10),

                  GetInput(
                    label: 'Bathrooms',
                    isNumberField: true,
                    controller: _bathroomsCtrl,
                  ),
                  const SizedBox(height: 10),

                  GetInput(
                    label: 'Area Sqft',
                    isNumberField: true,
                    controller: _areaCtrl,
                  ),
                  const SizedBox(height: 10),

                  GetInput(
                    label: 'Floor',
                    isNumberField: true,
                    controller: _floorCtrl,
                  ),
                  const SizedBox(height: 10),

                  CheckboxListTile(
                    value: _isFurnished,
                    title: Text(
                      'Is Furnished?',
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
                    onChanged: (v) => setState(() => _isFurnished = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasParking,
                    title: Text(
                      'Has Parking?',
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
                    onChanged: (v) => setState(() => _hasParking = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasGarden,
                    title: Text(
                      'Has Garden?',
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
                    onChanged: (v) => setState(() => _hasGarden = v ?? false),
                    contentPadding: EdgeInsets.zero,
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
                            maxLines: 5,
                            controller: _descCtrl,
                          ),
                        )
                      : GetInput(
                          label: 'Description',
                          maxLines: 5,
                          controller: _descCtrl,
                        ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 18,
                          tablet: 24,
                          largeTablet: 30,
                          desktop: 36)),

                  // ===== Amenities =====
                  Text(
                    'Amenities',
                    style: AppTextstyle.sectionTitleTextStyle.copyWith(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile:
                            AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
                        tablet: 22,
                        largeTablet: 26,
                        desktop: 30,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),
                  _buildAmenitiesCheckboxList(
                    all: _allAmenities,
                    selected: _selectedAmenities,
                    onChanged: (updated) =>
                        setState(() => _selectedAmenities = updated),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 18,
                          tablet: 24,
                          largeTablet: 30,
                          desktop: 36)),

                  // ===== Images =====
                  Text(
                    'Images',
                    style: AppTextstyle.sectionTitleTextStyle.copyWith(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile:
                            AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
                        tablet: 22,
                        largeTablet: 26,
                        desktop: 30,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),
                  Wrap(
                    spacing: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
                    runSpacing: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
                    children: [
                      // existing
                      ..._imageUrls.map(
                        (url) => Stack(
                          children: [
                            Image.network(
                              url,
                              width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 100,
                                  tablet: 130,
                                  largeTablet: 160,
                                  desktop: 190),
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 100,
                                  tablet: 130,
                                  largeTablet: 160,
                                  desktop: 190),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _imageUrls.remove(url));
                                },
                                child: Container(
                                  color: Colors.black54,
                                  padding: EdgeInsets.all(
                                      GetResponsiveSize.getResponsivePadding(
                                          context,
                                          mobile: 2,
                                          tablet: 4,
                                          largeTablet: 6,
                                          desktop: 8)),
                                  child: Icon(Icons.close,
                                      size: GetResponsiveSize.getResponsiveSize(
                                          context,
                                          mobile: 14,
                                          tablet: 18,
                                          largeTablet: 22,
                                          desktop: 26),
                                      color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      // newly picked (not uploaded yet)
                      ..._newImageFiles.map(
                        (bytes) => Image.memory(
                          bytes,
                          width: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 100,
                              tablet: 130,
                              largeTablet: 160,
                              desktop: 190),
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 100,
                              tablet: 130,
                              largeTablet: 160,
                              desktop: 190),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // add button
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 100,
                              tablet: 130,
                              largeTablet: 160,
                              desktop: 190),
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 100,
                              tablet: 130,
                              largeTablet: 160,
                              desktop: 190),
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.add,
                            size: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 24,
                                tablet: 32,
                                largeTablet: 40,
                                desktop: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24,
                          tablet: 32,
                          largeTablet: 40,
                          desktop: 48)),

                  // Video Upload Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(context,
                            mobile: 12,
                            tablet: 16,
                            largeTablet: 20,
                            desktop: 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
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
                            desktop: 40),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 10,
                                  tablet: 14,
                                  largeTablet: 18,
                                  desktop: 22)),
                          Text(
                            'Upload Video',
                            style: AppTextstyle.sectionTitleTextStyle.copyWith(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: AppTextstyle
                                        .sectionTitleTextStyle.fontSize ??
                                    18,
                                tablet: 22,
                                largeTablet: 26,
                                desktop: 30,
                              ),
                            ),
                          ),
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 20,
                                  tablet: 28,
                                  largeTablet: 36,
                                  desktop: 44)),
                          _buildVideoPicker(),
                          SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 20,
                                  tablet: 28,
                                  largeTablet: 36,
                                  desktop: 44)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24,
                          tablet: 32,
                          largeTablet: 40,
                          desktop: 48)),

                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 50, tablet: 65, largeTablet: 75, desktop: 85),
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GetResponsiveSize.getResponsiveBorderRadius(context,
                                mobile: 14,
                                tablet: 16,
                                largeTablet: 18,
                                desktop: 20),
                          ),
                        ),
                      ),
                      child: isSaving
                          ? SizedBox(
                              width: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 18,
                                  tablet: 24,
                                  largeTablet: 30,
                                  desktop: 36),
                              height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 18,
                                  tablet: 24,
                                  largeTablet: 30,
                                  desktop: 36),
                              child: CircularProgressIndicator(
                                strokeWidth:
                                    GetResponsiveSize.getResponsiveSize(context,
                                        mobile: 2,
                                        tablet: 2.5,
                                        largeTablet: 3,
                                        desktop: 3.5),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: AppTextstyle.buttonText.copyWith(
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile:
                                      AppTextstyle.buttonText.fontSize ?? 16,
                                  tablet: 20,
                                  largeTablet: 24,
                                  desktop: 28,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 28)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPicker() {
    // Show existing video if available, otherwise show new video selection
    final displayText = _videoFileName ??
        (_existingVideoUrl != null ? _existingVideoUrl! : 'No video selected');
    final hasVideo = _videoFileName != null || _existingVideoUrl != null;

    return Container(
      height: GetResponsiveSize.getResponsiveSize(context,
          mobile: 56, tablet: 70, largeTablet: 84, desktop: 98),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Text field showing filename
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  color: hasVideo ? Colors.black87 : Colors.grey.shade500,
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
            height: GetResponsiveSize.getResponsiveSize(context,
                mobile: 56, tablet: 70, largeTablet: 84, desktop: 98),
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 120, tablet: 150, largeTablet: 180, desktop: 210),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                bottomRight: Radius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickVideo,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  ),
                  bottomRight: Radius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _existingVideoUrl != null
                            ? Icons.edit
                            : Icons.upload_file,
                        color: Colors.black,
                        size: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 18,
                            tablet: 24,
                            largeTablet: 30,
                            desktop: 36),
                      ),
                      SizedBox(
                          width: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 4,
                              tablet: 6,
                              largeTablet: 8,
                              desktop: 10)),
                      Text(
                        _existingVideoUrl != null ? 'Change' : 'Choose File',
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

  Widget _buildAmenitiesCheckboxList({
    required List<String> all,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: GetResponsiveSize.getResponsiveSize(context,
          mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
      runSpacing: GetResponsiveSize.getResponsiveSize(context,
          mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
      children: all.map((feature) {
        final isSelected = selected.contains(feature);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? v) {
                final updated = List<String>.from(selected);
                if (v == true) {
                  if (!updated.contains(feature)) updated.add(feature);
                } else {
                  updated.remove(feature);
                }
                onChanged(updated);
              },
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
