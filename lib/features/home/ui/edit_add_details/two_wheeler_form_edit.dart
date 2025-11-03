import 'dart:typed_data';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
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

class TwoWheelerFormEdit extends StatefulWidget {
  final AddModel ad;
  const TwoWheelerFormEdit({super.key, required this.ad});

  @override
  State<TwoWheelerFormEdit> createState() => _TwoWheelerFormEditState();
}

class _TwoWheelerFormEditState extends State<TwoWheelerFormEdit> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _priceCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _descCtrl;

  // dropdown data
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

  // fields
  late int _price;
  late String _location;
  late int _year;
  late int _mileage;
  late String _color;
  bool _isFirstOwner = false;
  bool _hasInsurance = false;
  bool _hasRcBook = false;
  late String _description;

  // images
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _newImageFiles = []; // newly picked
  late List<String> _imageUrls; // existing + uploaded

  // video upload variables
  Uint8List? _newVideoFile; // newly picked video
  String? _uploadedVideoUrl; // uploaded video URL
  String? _videoFileName;
  late String? _existingVideoUrl; // existing video from ad

  @override
  void initState() {
    super.initState();

    // prefill text fields from ad
    _price = widget.ad.price;
    _location = widget.ad.location;
    _year = widget.ad.year ?? DateTime.now().year;
    _mileage = widget.ad.mileage ?? 0;
    _color = widget.ad.color ?? '';
    _isFirstOwner = widget.ad.isFirstOwner ?? false;
    _hasInsurance = widget.ad.hasInsurance ?? false;
    _hasRcBook = widget.ad.hasRcBook ?? false;
    _description = widget.ad.description;
    _imageUrls = List<String>.from(widget.ad.images);
    _existingVideoUrl = widget.ad.link?.isNotEmpty == true
        ? widget.ad.link
        : null; // existing video URL

    // CHANGED: init controllers with current values
    _priceCtrl = TextEditingController(text: _price.toString());
    _locationCtrl = TextEditingController(text: _location);
    _yearCtrl = TextEditingController(text: _year.toString());
    _mileageCtrl = TextEditingController(text: _mileage.toString());
    _colorCtrl = TextEditingController(text: _color);
    _descCtrl = TextEditingController(text: _description);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) load manufacturers
    final repo = AddRepository();
    final manufacturers = await repo.fetchManufacturers();
    setState(() => _manufacturers = manufacturers);

    // preselect manufacturer by id
    final manufacturerId = widget.ad.manufacturer?.id;
    _selectedManufacturer = _manufacturers.firstWhere(
      (m) => m.id == manufacturerId,
      orElse: () => _manufacturers.first,
    );

    // 2) load models for selected manufacturer, then select by id
    if (_selectedManufacturer != null) {
      _models = await repo.fetchModelsByManufacturer(_selectedManufacturer!.id);
      setState(() {});

      final modelId = widget.ad.model?.id;
      _selectedModel = _models.isNotEmpty
          ? _models.firstWhere(
              (m) => m.id == modelId,
              orElse: () => _models.first,
            )
          : null;
    }

    // 3) load variants for selected model, then select by (string) variant id if you store it
    if (_selectedModel != null) {
      _variants = await repo.fetchVariantsByModel(_selectedModel!.id);
      setState(() {});

      // if your AddModel.variant stores name instead of id, adjust the match
      _selectedVariant = _variants.firstWhere(
        (v) => v.id == widget.ad.variant,
        orElse: () => _variants.first,
      );
    }

    // 4) load transmission types and fuel types; preselect by IDs
    try {
      _transmissionTypes = await repo.fetchVehicleTransmissionTypes();
      _selectedTransmissionType = _transmissionTypes.firstWhere(
        (t) => t.id == widget.ad.transmissionId,
        orElse: () {
          // try best-effort match by name if ID missing
          final name = (widget.ad.transmission ?? '').toLowerCase();
          return _transmissionTypes.firstWhere(
            (t) => t.displayName.toLowerCase() == name,
            orElse: () => _transmissionTypes.first,
          );
        },
      );
    } catch (_) {}

    try {
      _fuelTypes = await repo.fetchVehicleFuelTypes();
      _selectedFuelType = _fuelTypes.firstWhere(
        (f) => f.id == widget.ad.fuelTypeId,
        orElse: () {
          final name = (widget.ad.fuelType ?? '').toLowerCase();
          return _fuelTypes.firstWhere(
            (f) => f.displayName.toLowerCase() == name,
            orElse: () {
              if (_fuelTypes.isNotEmpty) {
                return _fuelTypes.first;
              }
              throw Exception('No fuel types available');
            },
          );
        },
      );
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // CHANGED: dispose controllers
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _colorCtrl.dispose();
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

  // Future<void> _submitWithBloc(BuildContext context) async {
  //   if (!_formKey.currentState!.validate()) return;
  //   _formKey.currentState!.save();

  //   // upload new images (kept from your code)
  //   await _uploadNewImages();

  //   final payload = {
  //     "vehicleType": "two_wheeler",
  //     "price": _price,
  //     "location": _location,
  //     "manufacturerId": _selectedManufacturer?.id,
  //     "modelId": _selectedModel?.id,
  //     "variantId": _selectedVariant?.id,
  //     "year": _year,
  //     "mileage": _mileage,
  //     "color": _color,
  //     "isFirstOwner": _isFirstOwner,
  //     "hasInsurance": _hasInsurance,
  //     "hasRcBook": _hasRcBook,
  //     "description": _description,
  //     "images": _imageUrls,
  //     "fuelTypeId": _selectedFuelType?.id,
  //     "transmissionTypeId": _selectedTransmissionType?.id,
  //     "additionalFeatures": widget.ad.additionalFeatures ?? [],
  //   };

  //   context.read<AdEditBloc>().add(
  //         AdEditEvent.submit(
  //           adId: widget.ad.id,
  //           category: widget.ad.category.isNotEmpty
  //               ? widget.ad.category
  //               : 'two_wheeler',
  //           payload: payload,
  //         ),
  //       );
  // }

  Future<void> _submitWithBloc(BuildContext context) async {
    FocusScope.of(context).unfocus(); // CHANGED: commit IME text
    if (!_formKey.currentState!.validate()) return;

    await _uploadNewImages();
    await _uploadVideo();

    // CHANGED: read from controllers instead of saved fields
    final payload = {
      "vehicleType": "two_wheeler", // keep only if backend wants it in data
      "price": int.parse(_priceCtrl.text.trim()),
      "location": _locationCtrl.text.trim(),
      "manufacturerId": _selectedManufacturer?.id,
      "modelId": _selectedModel?.id,
      "variantId": _selectedVariant?.id,
      "year": int.parse(_yearCtrl.text.trim()),
      "mileage": int.parse(_mileageCtrl.text.trim()),
      "color": _colorCtrl.text.trim(),
      "isFirstOwner": _isFirstOwner,
      "hasInsurance": _hasInsurance,
      "hasRcBook": _hasRcBook,
      "description": _descCtrl.text.trim(),
      "images": _imageUrls,
      "link": _uploadedVideoUrl ?? _existingVideoUrl, // Video URL
      "fuelTypeId": _selectedFuelType?.id,
      "transmissionTypeId": _selectedTransmissionType?.id,
      "additionalFeatures": widget.ad.additionalFeatures ?? [],
    };

    // optional: drop null/empty strings to avoid server wiping fields with blanks
    // payload
    //     .removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    debugPrint('UPDATE PAYLOAD => $payload'); // CHANGED: sanity check once

    context.read<AdEditBloc>().add(
          AdEditEvent.submit(
            adId: widget.ad.id,
            category: widget.ad.category.isNotEmpty
                ? widget.ad.category
                : 'two_wheeler',
            payload: payload,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // form-only page (no header sections)
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
                // Refresh listings and navigate to home
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
                  // Price & location
                  GetInput(
                    label: 'Price',
                    isNumberField: true,
                    // initialValue: _price.toString(),
                    controller: _priceCtrl,
                    // onSaved: (v) => _price = int.tryParse(v ?? '') ?? _price,
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 10,
                          tablet: 14,
                          largeTablet: 18,
                          desktop: 22)),
                  GetInput(
                    label: 'Location',
                    // initialValue: _location,
                    controller: _locationCtrl,
                    // onSaved: (v) => _location = v ?? '',
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
                    // initialValue: _year.toString(),
                    controller: _yearCtrl,
                    // onSaved: (v) => _year = int.tryParse(v ?? '') ?? _year,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Mileage (km)',
                    isNumberField: true,
                    // initialValue: _mileage.toString(),
                    controller: _mileageCtrl,

                    // onSaved: (v) =>
                    //     _mileage = int.tryParse(v ?? '') ?? _mileage,
                  ),
                  const SizedBox(height: 10),
                  GetInput(
                    label: 'Color',
                    // initialValue: _color,
                    controller: _colorCtrl,
                    // onSaved: (v) => _color = v ?? '',
                  ),
                  const SizedBox(height: 10),

                  // Toggles
                  CheckboxListTile(
                    value: _isFirstOwner,
                    title: Text(
                      'Is First Owner',
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
                    onChanged: (v) =>
                        setState(() => _isFirstOwner = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasInsurance,
                    title: Text(
                      'Has Insurance',
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
                    onChanged: (v) =>
                        setState(() => _hasInsurance = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _hasRcBook,
                    title: Text(
                      'Has RC Book',
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
                    onChanged: (v) => setState(() => _hasRcBook = v ?? false),
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
                            // initialValue: _description,
                            controller: _descCtrl,
                            // onSaved: (v) => _description = v ?? '',
                          ),
                        )
                      : GetInput(
                          label: 'Description',
                          maxLines: 5,
                          // initialValue: _description,
                          controller: _descCtrl,
                          // onSaved: (v) => _description = v ?? '',
                        ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 20,
                          tablet: 28,
                          largeTablet: 36,
                          desktop: 44)),

                  // Images (existing + add new)
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
                      ..._imageUrls.map((url) => Stack(
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
                                        size:
                                            GetResponsiveSize.getResponsiveSize(
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
                          )),
                      ..._newImageFiles.map((bytes) => Image.memory(
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
                          )),
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

                  // Save button
                  // SizedBox(
                  //   height: 50,
                  //   child: ElevatedButton(
                  //     onPressed: _submit,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColors.primaryColor,
                  //       foregroundColor: AppColors.whiteColor,
                  //       shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(14)),
                  //     ),
                  //     child:
                  //         Text('Save Changes', style: AppTextstyle.buttonText),
                  //   ),
                  // ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 50,
                              tablet: 65,
                              largeTablet: 75,
                              desktop: 85),
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () => _submitWithBloc(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GetResponsiveSize.getResponsiveBorderRadius(
                                      context,
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
                                          GetResponsiveSize.getResponsiveSize(
                                              context,
                                              mobile: 2,
                                              tablet: 2.5,
                                              largeTablet: 3,
                                              desktop: 3.5),
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: AppTextstyle.buttonText.copyWith(
                                      fontSize: GetResponsiveSize
                                          .getResponsiveFontSize(
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
                        SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 24,
                                desktop: 28)),
                      ],
                    ),
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
          CommonDecoration.textFieldDecoration(labelText: 'Variant *').copyWith(
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
}
