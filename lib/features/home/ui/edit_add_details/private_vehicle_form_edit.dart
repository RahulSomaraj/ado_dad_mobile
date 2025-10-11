import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehicle_variant_model.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:image_picker/image_picker.dart';

class PrivateVehicleFormEdit extends StatefulWidget {
  final AddModel ad;
  const PrivateVehicleFormEdit({super.key, required this.ad});

  @override
  State<PrivateVehicleFormEdit> createState() => _PrivateVehicleFormEditState();
}

class _PrivateVehicleFormEditState extends State<PrivateVehicleFormEdit> {
  final _formKey = GlobalKey<FormState>();

  // ---- Controllers (like in TwoWheelerFormEdit)
  late final TextEditingController _priceCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _descCtrl;

  // Dropdown data
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

  // Other fields
  bool _isFirstOwner = false;
  bool _hasInsurance = false;
  bool _hasRcBook = false;
  List<String> _additionalFeatures = [];

  // Images
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _newImageFiles = []; // newly picked
  late List<String> _imageUrls; // existing + uploaded

  // video upload variables
  Uint8List? _newVideoFile; // newly picked video
  String? _uploadedVideoUrl; // uploaded video URL
  String? _videoFileName;
  late String? _existingVideoUrl; // existing video from ad

  // ---- Helpers
  String _fuelLabel(VehicleFuelType f) => (f.displayName).toString();
  String _transLabel(VehicleTransmissionType t) => (t.displayName).toString();

  int _safeInt(String? s, {required int fallback}) {
    if (s == null) return fallback;
    final t = s.trim();
    if (t.isEmpty) return fallback;
    return int.tryParse(t) ?? fallback;
  }

  @override
  void initState() {
    super.initState();

    // Prefill from ad
    final price = widget.ad.price;
    final location = widget.ad.location;
    final year = widget.ad.year ?? DateTime.now().year;
    final mileage = widget.ad.mileage ?? 0;
    final color = widget.ad.color ?? '';
    final description = widget.ad.description;

    _isFirstOwner = widget.ad.isFirstOwner ?? false;
    _hasInsurance = widget.ad.hasInsurance ?? false;
    _hasRcBook = widget.ad.hasRcBook ?? false;
    _imageUrls = List<String>.from(widget.ad.images);
    _additionalFeatures = List<String>.from(widget.ad.additionalFeatures ?? []);
    _existingVideoUrl = widget.ad.link?.isNotEmpty == true
        ? widget.ad.link
        : null; // existing video URL

    // Controllers (like your TwoWheelerFormEdit)
    _priceCtrl = TextEditingController(text: price.toString());
    _locationCtrl = TextEditingController(text: location);
    _yearCtrl = TextEditingController(text: year.toString());
    _mileageCtrl = TextEditingController(text: mileage.toString());
    _colorCtrl = TextEditingController(text: color);
    _descCtrl = TextEditingController(text: description);

    _bootstrap();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = AddRepository();

    // 1) Manufacturers
    _manufacturers = await repo.fetchManufacturers();
    if (!mounted) return;

    final manufacturerId = widget.ad.manufacturer?.id;
    if (_manufacturers.isNotEmpty) {
      _selectedManufacturer = _manufacturers.firstWhere(
        (m) => m.id == manufacturerId,
        orElse: () => _manufacturers.first,
      );
    }

    // 2) Models for selected manufacturer
    if (_selectedManufacturer != null) {
      _models = await repo.fetchModelsByManufacturer(_selectedManufacturer!.id);
    }

    final modelId = widget.ad.model?.id;
    if (_models.isNotEmpty) {
      _selectedModel = _models.firstWhere(
        (m) => m.id == modelId,
        orElse: () => _models.first,
      );
    }

    // 3) Variants for selected model
    if (_selectedModel != null) {
      _variants = await repo.fetchVariantsByModel(_selectedModel!.id);
    }

    final variantIdOrName = widget.ad.variant;
    if (_variants.isNotEmpty && variantIdOrName != null) {
      _selectedVariant = _variants.firstWhere(
        (v) => v.id == variantIdOrName || v.name == variantIdOrName,
        orElse: () => _variants.first,
      );
    }

    // 4) Transmission / Fuel
    try {
      _transmissionTypes = await repo.fetchVehicleTransmissionTypes();
      final txId = widget.ad.transmissionId;
      _selectedTransmissionType = _transmissionTypes.firstWhere(
        (t) => t.id == txId,
        orElse: () {
          final name = (widget.ad.transmission ?? '').toLowerCase();
          return _transmissionTypes.firstWhere(
            (t) => _transLabel(t).toLowerCase() == name,
            orElse: () => _transmissionTypes.first,
          );
        },
      );
    } catch (_) {}

    try {
      _fuelTypes = await repo.fetchVehicleFuelTypes();
      final fuelId = widget.ad.fuelTypeId;
      _selectedFuelType = _fuelTypes.firstWhere(
        (f) => f.id == fuelId,
        orElse: () {
          final name = (widget.ad.fuelType ?? '').toLowerCase();
          return _fuelTypes.firstWhere(
            (f) => _fuelLabel(f).toLowerCase() == name,
            orElse: () => _fuelTypes.first,
          );
        },
      );
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _newImageFiles.add(bytes);
      }
      if (mounted) setState(() {});
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

  Future<void> _submitWithBloc(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    await _uploadNewImages();
    await _uploadVideo();

    final payload = {
      "vehicleType": (widget.ad.vehicleType?.isNotEmpty ?? false)
          ? widget.ad.vehicleType
          : "four_wheeler",
      "price": _safeInt(_priceCtrl.text, fallback: widget.ad.price),
      "location": _locationCtrl.text.trim(),
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,
      "year": _safeInt(_yearCtrl.text,
          fallback: widget.ad.year ?? DateTime.now().year),
      "mileage": _safeInt(_mileageCtrl.text, fallback: widget.ad.mileage ?? 0),
      "color": _colorCtrl.text.trim(),
      "isFirstOwner": _isFirstOwner,
      "hasInsurance": _hasInsurance,
      "hasRcBook": _hasRcBook,
      "description": _descCtrl.text.trim(),
      "images": _imageUrls,
      "link": _uploadedVideoUrl ?? _existingVideoUrl, // Video URL
      "fuelTypeId": _selectedFuelType?.id,
      "transmissionTypeId": _selectedTransmissionType?.id,
      "additionalFeatures": _additionalFeatures,
    };

    // Optionally drop empty strings/nulls:
    payload
        .removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    debugPrint('UPDATE PAYLOAD (private_vehicle) => $payload');

    context.read<AdEditBloc>().add(
          AdEditEvent.submit(
            adId: widget.ad.id,
            category: widget.ad.category.isNotEmpty
                ? widget.ad.category
                : 'private_vehicle',
            payload: payload,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Add Details',
          style: AppTextstyle.appbarText,
        ),
      ),
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: BlocConsumer<AdEditBloc, AdEditState>(
          listener: (context, state) {
            state.whenOrNull(
              saving: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Saving...'))),
              success: (_) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('✅ Saved')));
                context
                    .read<AdvertisementBloc>()
                    .add(const AdvertisementEvent.fetchAllListings());
                context.go('/home');
              },
              failure: (msg) => ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('❌ Failed: $msg'))),
            );
          },
          builder: (context, state) {
            final isSaving =
                state.maybeWhen(saving: () => true, orElse: () => false);

            return Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Price
                  GetInput(
                    label: 'Price',
                    isNumberField: true,
                    controller: _priceCtrl,
                  ),
                  const SizedBox(height: 10),

                  // Location
                  GetInput(
                    label: 'Location',
                    controller: _locationCtrl,
                  ),
                  const SizedBox(height: 10),

                  // Manufacturer / Model / Variant
                  buildDropdown<VehicleManufacturer>(
                    labelText: 'Manufacturer *',
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
                    labelText: 'Model *',
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

                  // Toggles
                  CheckboxListTile(
                    value: _isFirstOwner,
                    title: const Text('Is First Owner'),
                    onChanged: (v) =>
                        setState(() => _isFirstOwner = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasInsurance,
                    title: const Text('Has Insurance'),
                    onChanged: (v) =>
                        setState(() => _hasInsurance = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasRcBook,
                    title: const Text('Has RC Book'),
                    onChanged: (v) => setState(() => _hasRcBook = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),

                  // Description
                  GetInput(
                    label: 'Description',
                    maxLines: 5,
                    controller: _descCtrl,
                  ),
                  const SizedBox(height: 20),

                  // Additional Features
                  Text('Additional Features',
                      style: AppTextstyle.sectionTitleTextStyle),
                  const SizedBox(height: 10),
                  _buildFeatures(),
                  const SizedBox(height: 20),

                  // Images
                  Text('Images', style: AppTextstyle.sectionTitleTextStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._imageUrls.map((url) => Stack(
                            children: [
                              Image.network(url,
                                  width: 100, height: 100, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _imageUrls.remove(url)),
                                  child: Container(
                                    color: Colors.black54,
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      ..._newImageFiles.map((bytes) => Image.memory(bytes,
                          width: 100, height: 100, fit: BoxFit.cover)),
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
                  const SizedBox(height: 24),

                  // Video Upload Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Upload Video',
                            style: AppTextstyle.sectionTitleTextStyle,
                          ),
                          const SizedBox(height: 20),
                          _buildVideoPicker(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          isSaving ? null : () => _submitWithBloc(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Save Changes',
                              style: AppTextstyle.buttonText),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final all = <String>[
      "Sunroof",
      "Leather Seats",
      "Navigation System",
      "Reverse Camera",
      "Bluetooth Connectivity",
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: all.map((feature) {
        final isSelected = _additionalFeatures.contains(feature);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    if (!isSelected) _additionalFeatures.add(feature);
                  } else {
                    _additionalFeatures.remove(feature);
                  }
                });
              },
            ),
            Text(feature),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildVariantDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<VehicleVariant>(
          decoration:
              CommonDecoration.textFieldDecoration(labelText: 'Variant *'),
          value: _selectedVariant,
          dropdownColor: Colors.white,
          isExpanded: true,
          items: _variants.map((VehicleVariant variant) {
            return DropdownMenuItem<VehicleVariant>(
              value: variant,
              child: Text(
                variant.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedVariant = val);
          },
          validator: (value) =>
              value == null ? 'Please select a variant' : null,
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    // Show existing video if available, otherwise show new video selection
    final displayText = _videoFileName ??
        (_existingVideoUrl != null ? _existingVideoUrl! : 'No video selected');
    final hasVideo = _videoFileName != null || _existingVideoUrl != null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Text field showing filename
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                displayText,
                style: TextStyle(
                  color: hasVideo ? Colors.black87 : Colors.grey.shade500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Choose File button
          Container(
            height: 56,
            width: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickVideo,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
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
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _existingVideoUrl != null ? 'Change' : 'Choose File',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
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
