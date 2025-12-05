import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
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
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CommercialVehicleFormEdit extends StatefulWidget {
  final AddModel ad;
  const CommercialVehicleFormEdit({super.key, required this.ad});

  @override
  State<CommercialVehicleFormEdit> createState() =>
      _CommercialVehicleFormEditState();
}

class _CommercialVehicleFormEditState extends State<CommercialVehicleFormEdit> {
  final _formKey = GlobalKey<FormState>();

  // text controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _payloadCapacityCtrl;
  late final TextEditingController _payloadUnitCtrl;
  late final TextEditingController _axleCountCtrl;
  late final TextEditingController _seatingCapacityCtrl;
  late final TextEditingController _descCtrl;

  // dropdown & toggle data
  final Map<String, String> _commercialVehicleTypeMap = const {
    'truck': 'Truck',
    'van': 'Van',
    'bus': 'Bus',
    'tractor': 'Tractor',
    'trailer': 'Trailer',
    'forklift': 'Forklift',
  };
  final Map<String, String> _bodyTypeMap = const {
    'flatbed': 'flatbed',
    'container': 'container',
    'refrigerated': 'refrigerated',
    'tanker': 'tanker',
    'dump': 'dump',
    'pickup': 'pickup',
    'box': 'box',
    'passenger': 'passenger',
  };

  String? _selectedVehicleType; // e.g. 'truck'
  String? _selectedBodyType; // e.g. 'flatbed'

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

  bool _hasInsurance = false;
  bool _hasFitness = false;
  bool _hasPermit = false;

  // features
  final List<String> _allFeatures = const [
    "GPS Tracking",
    "Climate Control",
    "Safety Features",
    "Anti-lock Braking System"
  ];
  late List<String> _selectedFeatures;

  // images
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _newImageFiles = [];
  late List<String> _imageUrls;

  // video upload variables
  Uint8List? _newVideoFile; // newly picked video
  String? _uploadedVideoUrl; // uploaded video URL
  String? _videoFileName;
  late String? _existingVideoUrl; // existing video from ad
  bool _videoRemoved = false; // track if video was explicitly removed

  @override
  void initState() {
    super.initState();

    // ---- Prefill from ad ----
    _titleCtrl = TextEditingController(text: widget.ad.title ?? '');
    _priceCtrl = TextEditingController(text: widget.ad.price.toString());
    _locationCtrl = TextEditingController(text: widget.ad.location);
    _yearCtrl = TextEditingController(
        text: (widget.ad.year ?? DateTime.now().year).toString());
    _mileageCtrl =
        TextEditingController(text: (widget.ad.mileage ?? 0).toString());
    _colorCtrl = TextEditingController(text: widget.ad.color ?? '');

    _payloadCapacityCtrl = TextEditingController(
        text: (widget.ad.payloadCapacity ?? 0).toString());
    _payloadUnitCtrl = TextEditingController(text: widget.ad.payloadUnit ?? '');
    _axleCountCtrl =
        TextEditingController(text: (widget.ad.axleCount ?? 0).toString());
    _seatingCapacityCtrl = TextEditingController(
        text: (widget.ad.seatingCapacity ?? 0).toString());

    _descCtrl = TextEditingController(text: widget.ad.description);

    _selectedVehicleType =
        widget.ad.commercialVehicleType; // expects key like 'truck'
    _selectedBodyType = widget.ad.bodyType; // expects key like 'flatbed'

    _hasInsurance = widget.ad.hasInsurance ?? false;
    _hasFitness = widget.ad.hasFitness ?? false;
    _hasPermit = widget.ad.hasPermit ?? false;

    _selectedFeatures =
        List<String>.from(widget.ad.additionalFeatures ?? const []);
    _imageUrls = List<String>.from(widget.ad.images);
    _existingVideoUrl = widget.ad.link?.isNotEmpty == true
        ? widget.ad.link
        : null; // existing video URL

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = AddRepository();

    // manufacturers
    _manufacturers = await repo.fetchManufacturers();
    setState(() {});

    // preselect manufacturer by id
    final manufacturerId = widget.ad.manufacturer?.id;
    if (manufacturerId != null) {
      final m = _manufacturers.where((x) => x.id == manufacturerId);
      if (m.isNotEmpty) _selectedManufacturer = m.first;
    } else if (_manufacturers.isNotEmpty) {
      _selectedManufacturer = _manufacturers.first;
    }

    // models for selected manufacturer
    if (_selectedManufacturer != null) {
      _models = await repo.fetchModelsByManufacturer(_selectedManufacturer!.id);
      setState(() {});
      final modelId = widget.ad.model?.id;
      if (modelId != null) {
        final mm = _models.where((x) => x.id == modelId);
        if (mm.isNotEmpty) _selectedModel = mm.first;
      }
    }

    // variants for selected model
    if (_selectedModel != null) {
      _variants = await repo.fetchVariantsByModel(_selectedModel!.id);
      setState(() {});
      // if AddModel.variant is id:
      final variantId = widget.ad.variant;
      if (variantId != null) {
        final vv = _variants.where((x) => x.id == variantId);
        if (vv.isNotEmpty) _selectedVariant = vv.first;
      }
    }

    // transmission
    try {
      _transmissionTypes = await repo.fetchVehicleTransmissionTypes();
      _selectedTransmissionType = _transmissionTypes.firstWhere(
        (t) => t.id == widget.ad.transmissionId,
        orElse: () {
          final name = (widget.ad.transmission ?? '').toLowerCase();
          return _transmissionTypes.firstWhere(
            (t) => t.displayName.toLowerCase() == name,
            orElse: () => _transmissionTypes.isNotEmpty
                ? _transmissionTypes.first
                : throw Exception('No transmission types'),
          );
        },
      );
    } catch (_) {}

    // fuel
    try {
      _fuelTypes = await repo.fetchVehicleFuelTypes();
      _selectedFuelType = _fuelTypes.firstWhere(
        (f) => f.id == widget.ad.fuelTypeId,
        orElse: () {
          final name = (widget.ad.fuelType ?? '').toLowerCase();
          return _fuelTypes.firstWhere(
            (f) => f.displayName.toLowerCase() == name,
            orElse: () => _fuelTypes.isNotEmpty
                ? _fuelTypes.first
                : throw Exception('No fuel types'),
          );
        },
      );
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _colorCtrl.dispose();
    _payloadCapacityCtrl.dispose();
    _payloadUnitCtrl.dispose();
    _axleCountCtrl.dispose();
    _seatingCapacityCtrl.dispose();
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

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
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
          setState(() {
            _uploadedVideoUrl = url;
            _videoRemoved = false; // Reset removal flag when video is uploaded
          });
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

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await _uploadNewImages();
    await _uploadVideo();

    // Handle video URL - prioritize uploaded video, fallback to existing, or empty string if removed
    final linkValue = _videoRemoved && _uploadedVideoUrl == null
        ? "" // Explicitly set to empty string to remove video
        : (_uploadedVideoUrl ?? _existingVideoUrl);

    final payload = {
      // keep if backend expects an explicit type discriminator inside "data"
      "commercialVehicleType": _selectedVehicleType,
      "bodyType": _selectedBodyType,
      "title": _titleCtrl.text.trim(), // Include title like other fields

      "price": int.tryParse(_priceCtrl.text.trim()),
      "location": _locationCtrl.text.trim(),

      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,

      "year": int.tryParse(_yearCtrl.text.trim()),
      "mileage": int.tryParse(_mileageCtrl.text.trim()),
      "color": _colorCtrl.text.trim(),

      "payloadCapacity": int.tryParse(_payloadCapacityCtrl.text.trim() == ""
          ? "0"
          : _payloadCapacityCtrl.text.trim()),
      "payloadUnit": _payloadUnitCtrl.text.trim(),
      "axleCount": int.tryParse(
          _axleCountCtrl.text.trim() == "" ? "0" : _axleCountCtrl.text.trim()),

      "hasInsurance": _hasInsurance,
      "hasFitness": _hasFitness,
      "hasPermit": _hasPermit,

      "seatingCapacity": int.tryParse(_seatingCapacityCtrl.text.trim() == ""
          ? "0"
          : _seatingCapacityCtrl.text.trim()),
      "description": _descCtrl.text.trim(),
      "images": _imageUrls,
      "fuelTypeId": _selectedFuelType?.id,
      "transmissionTypeId": _selectedTransmissionType?.id,

      "additionalFeatures": _selectedFeatures,
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

    context.read<AdEditBloc>().add(AdEditEvent.submit(
          adId: widget.ad.id,
          category: widget.ad.category.isNotEmpty
              ? widget.ad.category
              : 'commercial_vehicle',
          payload: payload,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Add Details',
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
              saving: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saving...')),
                );
              },
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
                  SnackBar(
                      content:
                          Text(ErrorMessageUtil.getUserFriendlyMessage(msg))),
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
                  // price, location
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
                  GetInput(
                    label: 'Location',
                    controller: _locationCtrl,
                  ),
                  const SizedBox(height: 10),

                  // commercial vehicle type
                  buildDropdown<String>(
                    labelText: 'Commercial Vehicle Type',
                    items: _commercialVehicleTypeMap.keys.toList(),
                    selectedValue: _selectedVehicleType,
                    errorMsg: 'Please select a vehicle type',
                    // displayTextBuilder: (key) =>
                    //     _commercialVehicleTypeMap[key] ?? key,
                    onChanged: (val) => setState(() {
                      _selectedVehicleType = val;
                    }),
                  ),
                  const SizedBox(height: 10),

                  // body type
                  buildDropdown<String>(
                    labelText: 'Body Type',
                    items: _bodyTypeMap.keys.toList(),
                    selectedValue: _selectedBodyType,
                    errorMsg: 'Please select a body type',
                    // displayTextBuilder: (key) => _bodyTypeMap[key] ?? key,
                    onChanged: (val) => setState(() {
                      _selectedBodyType = val;
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Manufacturer / Model / Variant
                  buildDropdown<VehicleManufacturer>(
                    labelText: 'Manufacturer',
                    items: _manufacturers,
                    selectedValue: _selectedManufacturer,
                    errorMsg: 'Please select a manufacturer',
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
                  buildDropdown<VehicleModel>(
                    labelText: 'Model',
                    items: _models,
                    selectedValue: _selectedModel,
                    errorMsg: 'Please select a model',
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
                  buildDropdown<VehicleTransmissionType>(
                    labelText: 'Transmission Type',
                    items: _transmissionTypes,
                    selectedValue: _selectedTransmissionType,
                    errorMsg: 'Please select a transmission type',
                    onChanged: (t) =>
                        setState(() => _selectedTransmissionType = t),
                  ),
                  const SizedBox(height: 10),
                  buildDropdown<VehicleFuelType>(
                    labelText: 'Fuel Type',
                    items: _fuelTypes,
                    selectedValue: _selectedFuelType,
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

                  // Payload / Axle / Seating
                  GetInput(
                    label: 'Payload Capacity',
                    isNumberField: true,
                    controller: _payloadCapacityCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Payload Unit',
                    controller: _payloadUnitCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Axle Count',
                    isNumberField: true,
                    controller: _axleCountCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Seating Capacity',
                    isNumberField: true,
                    controller: _seatingCapacityCtrl,
                  ),
                  const SizedBox(height: 10),

                  // Toggles
                  CheckboxToggleWidget(
                    value: _hasInsurance,
                    title: 'Has Insurance',
                    onChanged: (v) =>
                        setState(() => _hasInsurance = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasFitness,
                    title: 'Has Fitness',
                    onChanged: (v) => setState(() => _hasFitness = v ?? false),
                  ),
                  CheckboxToggleWidget(
                    value: _hasPermit,
                    title: 'Has Permit',
                    onChanged: (v) => setState(() => _hasPermit = v ?? false),
                  ),
                  const SizedBox(height: 10),

                  // Features
                  const SectionTitleWidget(title: 'Additional Features'),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
                  FeaturesSelectionWidget(
                    allFeatures: _allFeatures,
                    selectedFeatures: _selectedFeatures,
                    onFeaturesChanged: (updated) =>
                        setState(() => _selectedFeatures = updated),
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
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 28)),

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

                  // Save button
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

  Widget _buildVariantDropdown() {
    final dropdown = DropdownButtonFormField<VehicleVariant>(
      decoration:
          CommonDecoration.textFieldDecoration(labelText: 'Variant').copyWith(
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
                largeTablet: 24,
                desktop: 28,
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

    // Wrap in SizedBox for tablets and above to match textbox height
    if (GetResponsiveSize.isTablet(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 0, // Not used since we check isTablet first
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
