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

  @override
  void initState() {
    super.initState();

    // ---- Prefill from ad ----
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

    final payload = {
      // keep if backend expects an explicit type discriminator inside "data"
      "commercialVehicleType": _selectedVehicleType,
      "bodyType": _selectedBodyType,

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
      "link": _uploadedVideoUrl ?? _existingVideoUrl, // Video URL

      "fuelTypeId": _selectedFuelType?.id,
      "transmissionTypeId": _selectedTransmissionType?.id,

      "additionalFeatures": _selectedFeatures,
    };

    // Optional: drop null/blank values so backend doesn't wipe existing data
    payload.removeWhere((k, v) {
      if (v == null) return true;
      if (v is String && v.trim().isEmpty) return true;
      return false;
    });

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
          style: AppTextstyle.appbarText,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // price, location
                  GetInput(
                    label: 'Price',
                    isNumberField: true,
                    controller: _priceCtrl,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Location',
                    controller: _locationCtrl,
                  ),
                  const SizedBox(height: 10),

                  // commercial vehicle type
                  buildDropdown<String>(
                    labelText: 'Commercial Vehicle Type *',
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
                    labelText: 'Body Type *',
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
                  CheckboxListTile(
                    value: _hasInsurance,
                    title: const Text('Has Insurance'),
                    onChanged: (v) =>
                        setState(() => _hasInsurance = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasFitness,
                    title: const Text('Has Fitness'),
                    onChanged: (v) => setState(() => _hasFitness = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasPermit,
                    title: const Text('Has Permit'),
                    onChanged: (v) => setState(() => _hasPermit = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),

                  // Features
                  Text('Additional Features',
                      style: AppTextstyle.sectionTitleTextStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _allFeatures.map((feature) {
                      final isSelected = _selectedFeatures.contains(feature);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (sel) {
                              final updated =
                                  List<String>.from(_selectedFeatures);
                              if (sel == true) {
                                if (!updated.contains(feature))
                                  updated.add(feature);
                              } else {
                                updated.remove(feature);
                              }
                              setState(() => _selectedFeatures = updated);
                            },
                          ),
                          Text(feature),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Description
                  GetInput(
                    label: 'Description',
                    maxLines: 5,
                    controller: _descCtrl,
                  ),
                  const SizedBox(height: 16),

                  // Images
                  Text('Images', style: AppTextstyle.sectionTitleTextStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._imageUrls.map((url) => Stack(
                            children: [
                              Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
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
                      ..._newImageFiles.map((bytes) => Image.memory(
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

                  // Save button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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
