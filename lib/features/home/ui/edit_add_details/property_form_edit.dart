import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/checkbox_toggle_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/features_selection_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/image_picker_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/save_button_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/section_title_widget.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/widgets/video_upload_section_widget.dart';
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
                  const SectionTitleWidget(title: 'Essential Details'),
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

                  CheckboxToggleWidget(
                    value: _isFurnished,
                    title: 'Is Furnished?',
                    onChanged: (v) => setState(() => _isFurnished = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasParking,
                    title: 'Has Parking?',
                    onChanged: (v) => setState(() => _hasParking = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasGarden,
                    title: 'Has Garden?',
                    onChanged: (v) => setState(() => _hasGarden = v ?? false),
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
                  const SectionTitleWidget(title: 'Amenities'),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
                  FeaturesSelectionWidget(
                    allFeatures: _allAmenities,
                    selectedFeatures: _selectedAmenities,
                    onFeaturesChanged: (updated) =>
                        setState(() => _selectedAmenities = updated),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 18,
                          tablet: 24,
                          largeTablet: 30,
                          desktop: 36)),

                  // ===== Images =====
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
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 24,
                          tablet: 32,
                          largeTablet: 40,
                          desktop: 48)),

                  SaveButtonWidget(
                    isSaving: isSaving,
                    onSave: () => _submit(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
