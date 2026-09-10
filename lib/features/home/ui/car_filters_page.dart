import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/features/home/commercial_vehicle_type_filter_bloc/commercial_vehicle_type_filter_bloc.dart';
import 'package:ado_dad_user/features/home/fuelType_filter_bloc/fuel_type_filter_bloc.dart';
import 'package:ado_dad_user/features/home/manufacturer_bloc/manufacturer_bloc.dart';
import 'package:ado_dad_user/features/home/model_filter_bloc/model_filter_bloc.dart';
import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/features/home/transmissionType_filter_bloc/transmission_type_filter_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/services/filter_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarFiltersPage extends StatefulWidget {
  final String? categoryId;
  final String? categoryTitle;
  final Map<String, dynamic>? currentFilters;
  const CarFiltersPage({
    super.key,
    this.categoryId,
    this.categoryTitle,
    this.currentFilters,
  });

  @override
  State<CarFiltersPage> createState() => _CarFiltersPageState();
}

class _CarFiltersPageState extends State<CarFiltersPage> {
  List<String> get categories {
    final base = <String>[
      'Brands',
      'Model',
      'Price',
      'Fuel Type',
      'Transmission',
      'Year',
      // 'KM Driven',
    ];
    if (widget.categoryId == 'commercial_vehicle') {
      return ['Type', ...base];
    }
    return base;
  }

  int selectedCategoryIndex = 0;
  String brandQuery = '';
  String modelQuery = '';
  String fuelTypeQuery = '';
  String transmissionQuery = '';
  String commercialTypeQuery = '';
  final Set<String> _selectedManufacturerIds = {};
  final Set<String> _selectedFuelTypeIds = {};
  final Set<String> _selectedTransmissionTypeIds = {};
  final Set<String> _selectedModelIds = {};
  final Set<String> _selectedCommercialVehicleTypes = {}; // e.g. {'van','truck'}
  final _minYearCtrl = TextEditingController();
  final _maxYearCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _brandSearchCtrl = TextEditingController();
  final _modelSearchCtrl = TextEditingController();
  final _commercialTypeSearchCtrl = TextEditingController();

  // Filter state service
  final FilterStateService _filterStateService = FilterStateService();

  // Debounce timer for manufacturer search
  Timer? _manufacturerSearchTimer;
  // Debounce timer for model search
  Timer? _modelSearchTimer;

  // Live result count
  final AddRepository _repo = AddRepository();
  int? _resultCount;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedFilterState();
    // Load manufacturers with appropriate vehicleCategory on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vehicleCategory = _getVehicleCategoryForFilter();
        context.read<ManufacturerBloc>().add(
              ManufacturerEvent.load(vehicleCategory: vehicleCategory),
            );
      }
    });
    _refreshCount();
  }

  /// Get vehicleCategory based on categoryId for filter page
  /// Car (private_vehicle), Premium Vehicle (private_vehicle), Commercial Vehicle (commercial_vehicle) → passenger_car
  /// Bike (two_wheeler) → two_wheeler
  String? _getVehicleCategoryForFilter() {
    final categoryId = widget.categoryId;
    if (categoryId == 'two_wheeler') {
      return 'two_wheeler';
    }
    // Both "Car" and "Premium Vehicles" use categoryId 'private_vehicle'
    // Both should show 'passenger_car' manufacturers
    if (categoryId == 'private_vehicle' || categoryId == 'commercial_vehicle') {
      // TODO(backend): commercial vehicles should use their own manufacturer category
      return 'passenger_car';
    }
    return null; // No filter if category is not recognized
  }

  void _loadSavedFilterState() {
    if (widget.categoryId != null) {
      final savedState =
          _filterStateService.getCarFilterState(widget.categoryId!);
      // Only load saved state if there are actually applied filters (not empty)
      if (savedState != null && !savedState.isEmpty) {
        setState(() {
          _selectedManufacturerIds.clear();
          _selectedManufacturerIds.addAll(savedState.selectedManufacturerIds);
          _selectedFuelTypeIds.clear();
          _selectedFuelTypeIds.addAll(savedState.selectedFuelTypeIds);
          _selectedTransmissionTypeIds.clear();
          _selectedTransmissionTypeIds
              .addAll(savedState.selectedTransmissionTypeIds);
          _selectedModelIds.clear();
          _selectedModelIds.addAll(savedState.selectedModelIds);
          _selectedCommercialVehicleTypes.clear();
          _selectedCommercialVehicleTypes
              .addAll(savedState.selectedCommercialVehicleTypes);
          _minYearCtrl.text = savedState.minYear ?? '';
          _maxYearCtrl.text = savedState.maxYear ?? '';
          _minPriceCtrl.text = savedState.minPrice ?? '';
          _maxPriceCtrl.text = savedState.maxPrice ?? '';
          brandQuery = savedState.brandQuery;
          _brandSearchCtrl.text = savedState.brandQuery;
          modelQuery = savedState.modelQuery;
          _modelSearchCtrl.text = savedState.modelQuery;
        });

        // If there's a saved brandQuery, trigger a search after the page is built
        if (savedState.brandQuery.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final vehicleCategory = _getVehicleCategoryForFilter();
              context.read<ManufacturerBloc>().add(
                    ManufacturerEvent.search(
                      savedState.brandQuery,
                      vehicleCategory: vehicleCategory,
                    ),
                  );
            }
          });
        }

        // If there's a saved modelQuery, trigger a search after the page is built
        if (savedState.modelQuery.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<ModelFilterBloc>().add(
                    ModelFilterEvent.search(savedState.modelQuery),
                  );
            }
          });
        }
      }
    }
  }

  void _saveFilterState() {
    if (widget.categoryId != null) {
      final state = CarFilterState(
        selectedManufacturerIds: _selectedManufacturerIds,
        selectedFuelTypeIds: _selectedFuelTypeIds,
        selectedTransmissionTypeIds: _selectedTransmissionTypeIds,
        selectedModelIds: _selectedModelIds,
        selectedCommercialVehicleTypes: _selectedCommercialVehicleTypes,
        minYear: _minYearCtrl.text.isEmpty ? null : _minYearCtrl.text,
        maxYear: _maxYearCtrl.text.isEmpty ? null : _maxYearCtrl.text,
        minPrice: _minPriceCtrl.text.isEmpty ? null : _minPriceCtrl.text,
        maxPrice: _maxPriceCtrl.text.isEmpty ? null : _maxPriceCtrl.text,
        brandQuery: brandQuery,
        modelQuery: modelQuery,
      );
      _filterStateService.saveCarFilterState(widget.categoryId!, state);
    }
  }

  @override
  void dispose() {
    _manufacturerSearchTimer?.cancel();
    _modelSearchTimer?.cancel();
    _countTimer?.cancel();
    _minYearCtrl.dispose();
    _maxYearCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _brandSearchCtrl.dispose();
    _modelSearchCtrl.dispose();
    _commercialTypeSearchCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Live result count
  // ===========================================================================
  void _refreshCount() {
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final count = await _repo.fetchAdsCount(
          category: widget.categoryId,
          search: brandQuery.isNotEmpty ? null : null,
          manufacturerIds: _selectedManufacturerIds.toList(),
          modelIds: _selectedModelIds.toList(),
          fuelTypeIds: _selectedFuelTypeIds.toList(),
          transmissionTypeIds: _selectedTransmissionTypeIds.toList(),
          commercialVehicleTypes: _selectedCommercialVehicleTypes.toList(),
          minYear: int.tryParse(_minYearCtrl.text),
          maxYear: int.tryParse(_maxYearCtrl.text),
          minPrice: int.tryParse(_minPriceCtrl.text),
          maxPrice: int.tryParse(_maxPriceCtrl.text),
        );
        if (mounted) {
          setState(() => _resultCount = count);
        }
      } catch (_) {
        // Ignore count errors silently; keep last known count.
      }
    });
  }

  // ===========================================================================
  // Clear all
  // ===========================================================================
  void _clearAll() {
    setState(() {
      _selectedCommercialVehicleTypes.clear();
      _selectedManufacturerIds.clear();
      _selectedFuelTypeIds.clear();
      _selectedTransmissionTypeIds.clear();
      _selectedModelIds.clear();
      _minYearCtrl.clear();
      _maxYearCtrl.clear();
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      brandQuery = '';
      _brandSearchCtrl.clear();
      modelQuery = '';
      _modelSearchCtrl.clear();
      fuelTypeQuery = '';
      transmissionQuery = '';
      commercialTypeQuery = '';
      _commercialTypeSearchCtrl.clear();
    });
    // Clear saved state
    if (widget.categoryId != null) {
      _filterStateService.clearCarFilterState(widget.categoryId!);
    }
    _refreshCount();
  }

  // ===========================================================================
  // Apply / validate
  // ===========================================================================
  void _applyFilters() {
    final min =
        _minYearCtrl.text.isNotEmpty ? int.tryParse(_minYearCtrl.text) : null;
    final max =
        _maxYearCtrl.text.isNotEmpty ? int.tryParse(_maxYearCtrl.text) : null;

    final minP =
        _minPriceCtrl.text.isNotEmpty ? int.tryParse(_minPriceCtrl.text) : null;
    final maxP =
        _maxPriceCtrl.text.isNotEmpty ? int.tryParse(_maxPriceCtrl.text) : null;

    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Min Year cannot be greater than Max Year')),
      );
      return;
    }

    if (minP != null && maxP != null && minP > maxP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Min Price cannot be greater than Max Price')),
      );
      return;
    }

    // Save current filter state before returning
    _saveFilterState();

    Navigator.pop<Map<String, dynamic>>(context, {
      'commercialVehicleTypes':
          _selectedCommercialVehicleTypes.toList(growable: false),
      'manufacturerIds': _selectedManufacturerIds.toList(),
      'fuelTypeIds': _selectedFuelTypeIds.toList(),
      'transmissionTypeIds': _selectedTransmissionTypeIds.toList(),
      'modelIds': _selectedModelIds.toList(),
      'minYear': min,
      'maxYear': max,
      'minPrice': minP,
      'maxPrice': maxP,
    });
  }

  // ===========================================================================
  // Brand / Model search dispatch (debounced)
  // ===========================================================================
  void _dispatchBrandSearch(String v) {
    _manufacturerSearchTimer?.cancel();
    _manufacturerSearchTimer =
        Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final vehicleCategory = _getVehicleCategoryForFilter();
      if (v.isEmpty) {
        context.read<ManufacturerBloc>().add(
              ManufacturerEvent.load(vehicleCategory: vehicleCategory),
            );
      } else {
        context.read<ManufacturerBloc>().add(
              ManufacturerEvent.search(v, vehicleCategory: vehicleCategory),
            );
      }
    });
  }

  void _dispatchModelSearch(String v) {
    _modelSearchTimer?.cancel();
    _modelSearchTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (v.isEmpty) {
        context.read<ModelFilterBloc>().add(const ModelFilterEvent.load());
      } else {
        context.read<ModelFilterBloc>().add(ModelFilterEvent.search(v));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 20.0,
              tablet: 26.0,
              largeTablet: 30.0,
              desktop: 34.0,
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Filters',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 18.0,
              tablet: 24.0,
              largeTablet: 28.0,
              desktop: 32.0,
            ),
          ),
        ),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Reset',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 14.0,
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Brand
          _selectorRow(
            label: 'Brand',
            subtitle: _selectedManufacturerIds.isEmpty
                ? 'Any'
                : '${_selectedManufacturerIds.length} selected',
            onTap: _openBrandSheet,
          ),
          const SizedBox(height: 12),

          // 2. Model
          _selectorRow(
            label: 'Model',
            subtitle: _selectedModelIds.isEmpty
                ? 'Any'
                : '${_selectedModelIds.length} selected',
            onTap: _openModelSheet,
          ),
          const SizedBox(height: 20),

          // 3. Price range
          _sectionLabel('Price range'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _minPriceCtrl,
                  hint: '₹ Min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _maxPriceCtrl,
                  hint: '₹ Max',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Year
          _sectionLabel('Year'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _minYearCtrl,
                  hint: 'From',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _maxYearCtrl,
                  hint: 'To',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Fuel
          _sectionLabel('Fuel'),
          const SizedBox(height: 10),
          _fuelChips(),
          const SizedBox(height: 20),

          // 6. Transmission
          _sectionLabel('Transmission'),
          const SizedBox(height: 10),
          _transmissionChips(),

          // 7. Body type (commercial only)
          if (widget.categoryId == 'commercial_vehicle') ...[
            const SizedBox(height: 20),
            _sectionLabel('Body type'),
            const SizedBox(height: 10),
            _bodyTypeChips(),
          ],

          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 48,
              tablet: 65,
              largeTablet: 75,
              desktop: 85,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 8,
                      tablet: 10,
                      largeTablet: 12,
                      desktop: 14,
                    ),
                  ),
                ),
              ),
              onPressed: _applyFilters,
              child: Text(
                _resultCount == null
                    ? 'Show results'
                    : 'Show $_resultCount results',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16.0,
                    tablet: 22.0,
                    largeTablet: 26.0,
                    desktop: 30.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Reusable UI helpers
  // ===========================================================================
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 15.0,
          tablet: 20.0,
          largeTablet: 22.0,
          desktop: 24.0,
        ),
        fontWeight: FontWeight.w600,
        color: AppColors.blackColor,
      ),
    );
  }

  Widget _selectorRow({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerColor, width: 0.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 15.0,
                        tablet: 20.0,
                        largeTablet: 22.0,
                        desktop: 24.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 13.0,
                        tablet: 18.0,
                        largeTablet: 20.0,
                        desktop: 22.0,
                      ),
                      color: AppColors.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.greyColor,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24.0,
                tablet: 28.0,
                largeTablet: 32.0,
                desktop: 36.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => _refreshCount(),
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16.0,
          tablet: 20.0,
          largeTablet: 22.0,
          desktop: 24.0,
        ),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 15.0,
            tablet: 20.0,
            largeTablet: 22.0,
            desktop: 24.0,
          ),
          color: AppColors.greyColor,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 14,
            tablet: 18,
            largeTablet: 22,
            desktop: 26,
          ),
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 20,
            desktop: 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GetResponsiveSize.getResponsiveBorderRadius(
              context,
              mobile: 9,
              tablet: 10,
              largeTablet: 12,
              desktop: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.dividerColor,
            width: selected ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 14.0,
              tablet: 18.0,
              largeTablet: 20.0,
              desktop: 22.0,
            ),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.blackColor,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Fuel chips
  // ===========================================================================
  Widget _fuelChips() {
    return BlocBuilder<FuelTypeFilterBloc, FuelTypeFilterState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_) => const SizedBox.shrink(),
          loaded: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((m) {
                final id = m.id;
                final selected = _selectedFuelTypeIds.contains(id);
                return _filterChip(
                  label: m.displayName.trim(),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedFuelTypeIds.remove(id);
                      } else {
                        _selectedFuelTypeIds.add(id);
                      }
                    });
                    _refreshCount();
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Transmission chips
  // ===========================================================================
  Widget _transmissionChips() {
    return BlocBuilder<TransmissionTypeFilterBloc, TransmissionTypeFilterState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_) => const SizedBox.shrink(),
          loaded: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((m) {
                final id = m.id;
                final selected = _selectedTransmissionTypeIds.contains(id);
                return _filterChip(
                  label: m.displayName.trim(),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTransmissionTypeIds.remove(id);
                      } else {
                        _selectedTransmissionTypeIds.add(id);
                      }
                    });
                    _refreshCount();
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Body type chips (commercial vehicle only)
  // ===========================================================================
  Widget _bodyTypeChips() {
    return BlocBuilder<CommercialVehicleTypeFilterBloc,
        CommercialVehicleTypeFilterState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_) => const SizedBox.shrink(),
          loaded: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((t) {
                final selected =
                    _selectedCommercialVehicleTypes.contains(t.name);
                return _filterChip(
                  label: t.displayName.trim(),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedCommercialVehicleTypes.remove(t.name);
                      } else {
                        _selectedCommercialVehicleTypes.add(t.name);
                      }
                    });
                    _refreshCount();
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Brand bottom sheet
  // ===========================================================================
  Future<void> _openBrandSheet() async {
    final manufacturerBloc = context.read<ManufacturerBloc>();
    manufacturerBloc.state.maybeWhen(
      loaded: (_) {},
      orElse: () => manufacturerBloc.add(ManufacturerEvent.load(
          vehicleCategory: _getVehicleCategoryForFilter())),
    );
    var brandVisible = 20;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: manufacturerBloc,
          child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.8,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    _sheetHeader('Select Brand'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _searchField(
                        controller: _brandSearchCtrl,
                        hint: 'Search Brand',
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => brandQuery = v);
                          _dispatchBrandSearch(v);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: BlocBuilder<ManufacturerBloc, ManufacturerState>(
                        builder: (context, state) {
                          return state.when(
                            initial: () => const SizedBox.shrink(),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (msg) => Center(child: Text(msg)),
                            loaded: (items) {
                              return NotificationListener<ScrollNotification>(
                                onNotification: (n) {
                                  if (n.metrics.pixels >=
                                          n.metrics.maxScrollExtent - 200 &&
                                      brandVisible < items.length) {
                                    setSheetState(() => brandVisible += 20);
                                  }
                                  return false;
                                },
                                child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                itemCount: brandVisible.clamp(0, items.length),
                                itemBuilder: (_, i) {
                                  final m = items[i];
                                  final id = m.id;
                                  final checked =
                                      _selectedManufacturerIds.contains(id);
                                  return CheckboxListTile(
                                    value: checked,
                                    onChanged: (_) {
                                      setSheetState(() {
                                        if (checked) {
                                          _selectedManufacturerIds.remove(id);
                                        } else {
                                          _selectedManufacturerIds.add(id);
                                        }
                                      });
                                    },
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      m.displayName.trim(),
                                      style: TextStyle(
                                        fontSize: GetResponsiveSize
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 16.0,
                                          tablet: 20.0,
                                          largeTablet: 24.0,
                                          desktop: 28.0,
                                        ),
                                      ),
                                    ),
                                    checkboxShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 2),
                              ));
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ));
      },
    );
    // Sheet dismissed: sync the outer page + count.
    if (mounted) {
      setState(() {});
      _refreshCount();
    }
  }

  // ===========================================================================
  // Model bottom sheet
  // ===========================================================================
  Future<void> _openModelSheet() async {
    final brandIds = _selectedManufacturerIds.toList();
    // Models are scoped to the selected brand(s) and fetched once per open.
    final Future<List<VehicleModel>> modelsFuture = brandIds.isEmpty
        ? Future.value(<VehicleModel>[])
        : _fetchModelsForBrands(brandIds);
    var modelQ = '';
    var modelVisible = 20;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.8,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                if (brandIds.isEmpty) {
                  return Column(
                    children: [
                      _sheetHeader('Select Model'),
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Select a brand first to see its models.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _sheetHeader('Select Model'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _searchField(
                        controller: _modelSearchCtrl,
                        hint: 'Search Model',
                        onChanged: (v) {
                          setSheetState(() {
                            modelQ = v;
                            modelVisible = 20;
                          });
                          setState(() => modelQuery = v);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: FutureBuilder<List<VehicleModel>>(
                        future: modelsFuture,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final all = snap.data ?? const <VehicleModel>[];
                          final q = modelQ.trim().toLowerCase();
                          final items = q.isEmpty
                              ? all
                              : all
                                  .where((m) =>
                                      m.displayName.toLowerCase().contains(q))
                                  .toList();
                          if (items.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No models found.'),
                              ),
                            );
                          }
                          final count = modelVisible.clamp(0, items.length);
                          return NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.pixels >=
                                      n.metrics.maxScrollExtent - 200 &&
                                  modelVisible < items.length) {
                                setSheetState(() => modelVisible += 20);
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                              itemCount: count,
                              itemBuilder: (_, i) {
                                final m = items[i];
                                final id = m.id;
                                final checked =
                                    _selectedModelIds.contains(id);
                                return CheckboxListTile(
                                  value: checked,
                                  onChanged: (_) {
                                    setSheetState(() {
                                      if (checked) {
                                        _selectedModelIds.remove(id);
                                      } else {
                                        _selectedModelIds.add(id);
                                      }
                                    });
                                  },
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    m.displayName.trim(),
                                    style: TextStyle(
                                      fontSize: GetResponsiveSize
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 16.0,
                                        tablet: 20.0,
                                        largeTablet: 24.0,
                                        desktop: 28.0,
                                      ),
                                    ),
                                  ),
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    // Sheet dismissed: sync the outer page + count.
    if (mounted) {
      setState(() {});
      _refreshCount();
    }
  }

  Future<List<VehicleModel>> _fetchModelsForBrands(List<String> brandIds) async {
    final all = <VehicleModel>[];
    final seen = <String>{};
    for (final id in brandIds) {
      try {
        final list = await _repo.fetchModelsByManufacturer(id);
        for (final m in list) {
          if (seen.add(m.id)) all.add(m);
        }
      } catch (_) {
        // Ignore per-brand fetch failures; show whatever loaded.
      }
    }
    return all;
  }

  Widget _sheetHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 17.0,
                  tablet: 22.0,
                  largeTablet: 26.0,
                  desktop: 30.0,
                ),
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16.0,
          tablet: 20.0,
          largeTablet: 22.0,
          desktop: 24.0,
        ),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search_rounded,
          size: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 24.0,
            tablet: 28.0,
            largeTablet: 32.0,
            desktop: 36.0,
          ),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 16.0,
            tablet: 20.0,
            largeTablet: 22.0,
            desktop: 24.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 14,
            tablet: 18,
            largeTablet: 22,
            desktop: 26,
          ),
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 20,
            desktop: 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GetResponsiveSize.getResponsiveBorderRadius(
              context,
              mobile: 9,
              tablet: 10,
              largeTablet: 12,
              desktop: 14,
            ),
          ),
        ),
      ),
    );
  }
}
