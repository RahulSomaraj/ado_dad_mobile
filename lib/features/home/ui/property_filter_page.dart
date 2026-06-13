import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/services/filter_state_service.dart';
import 'package:flutter/material.dart';

class PropertyFiltersPage extends StatefulWidget {
  final String? categoryId;
  final String? categoryTitle;
  final Map<String, dynamic>? currentFilters;
  const PropertyFiltersPage({
    super.key,
    this.categoryId,
    this.categoryTitle,
    this.currentFilters,
  });

  @override
  State<PropertyFiltersPage> createState() => _PropertyFiltersPageState();
}

class _PropertyFiltersPageState extends State<PropertyFiltersPage> {
  String propertyTypeQuery = '';
  final Set<String> _selectedPropertyTypes = {};
  final _minBedroomsCtrl = TextEditingController();
  final _maxBedroomsCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _minAreaCtrl = TextEditingController();
  final _maxAreaCtrl = TextEditingController();

  // Boolean filter options
  bool? _isFurnished;
  bool? _hasParking;

  // Filter state service
  final FilterStateService _filterStateService = FilterStateService();

  // Live result count
  final AddRepository _repo = AddRepository();
  int? _resultCount;
  Timer? _countTimer;

  // Property type options from the add property form
  final Map<String, String> _propertyTypeMap = {
    'apartment': 'Apartment',
    'house': 'House',
    'villa': 'Villa',
    'plot': 'Plot',
    'commercial': 'Commercial',
    'office': 'Office',
    'shop': 'Shop',
    'warehouse': 'Warehouse',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedFilterState();
    _refreshCount();
  }

  void _loadSavedFilterState() {
    if (widget.categoryId != null) {
      final savedState =
          _filterStateService.getPropertyFilterState(widget.categoryId!);
      // Only load saved state if there are actually applied filters (not empty)
      if (savedState != null && !savedState.isEmpty) {
        setState(() {
          _selectedPropertyTypes.clear();
          _selectedPropertyTypes.addAll(savedState.selectedPropertyTypes);
          _minBedroomsCtrl.text = savedState.minBedrooms ?? '';
          _maxBedroomsCtrl.text = savedState.maxBedrooms ?? '';
          _minPriceCtrl.text = savedState.minPrice ?? '';
          _maxPriceCtrl.text = savedState.maxPrice ?? '';
          _minAreaCtrl.text = savedState.minArea ?? '';
          _maxAreaCtrl.text = savedState.maxArea ?? '';
          _isFurnished = savedState.isFurnished;
          _hasParking = savedState.hasParking;
          propertyTypeQuery = savedState.propertyTypeQuery;
        });
      }
    }
  }

  void _saveFilterState() {
    if (widget.categoryId != null) {
      final state = PropertyFilterState(
        selectedPropertyTypes: _selectedPropertyTypes,
        minBedrooms:
            _minBedroomsCtrl.text.isEmpty ? null : _minBedroomsCtrl.text,
        maxBedrooms:
            _maxBedroomsCtrl.text.isEmpty ? null : _maxBedroomsCtrl.text,
        minPrice: _minPriceCtrl.text.isEmpty ? null : _minPriceCtrl.text,
        maxPrice: _maxPriceCtrl.text.isEmpty ? null : _maxPriceCtrl.text,
        minArea: _minAreaCtrl.text.isEmpty ? null : _minAreaCtrl.text,
        maxArea: _maxAreaCtrl.text.isEmpty ? null : _maxAreaCtrl.text,
        isFurnished: _isFurnished,
        hasParking: _hasParking,
        propertyTypeQuery: propertyTypeQuery,
      );
      _filterStateService.savePropertyFilterState(widget.categoryId!, state);
    }
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _minBedroomsCtrl.dispose();
    _maxBedroomsCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
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
          propertyTypes: _selectedPropertyTypes.toList(),
          minBedrooms: int.tryParse(_minBedroomsCtrl.text),
          maxBedrooms: int.tryParse(_maxBedroomsCtrl.text),
          minPrice: int.tryParse(_minPriceCtrl.text),
          maxPrice: int.tryParse(_maxPriceCtrl.text),
          minArea: int.tryParse(_minAreaCtrl.text),
          maxArea: int.tryParse(_maxAreaCtrl.text),
          isFurnished: _isFurnished,
          hasParking: _hasParking,
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
      _selectedPropertyTypes.clear();
      _minBedroomsCtrl.clear();
      _maxBedroomsCtrl.clear();
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      _minAreaCtrl.clear();
      _maxAreaCtrl.clear();
      _isFurnished = null;
      _hasParking = null;
      propertyTypeQuery = '';
    });
    // Clear saved state
    if (widget.categoryId != null) {
      _filterStateService.clearPropertyFilterState(widget.categoryId!);
    }
    _refreshCount();
  }

  // ===========================================================================
  // Apply / validate
  // ===========================================================================
  void _applyFilters() {
    final minBedrooms = _minBedroomsCtrl.text.isNotEmpty
        ? int.tryParse(_minBedroomsCtrl.text)
        : null;
    final maxBedrooms = _maxBedroomsCtrl.text.isNotEmpty
        ? int.tryParse(_maxBedroomsCtrl.text)
        : null;
    final minPrice = _minPriceCtrl.text.isNotEmpty
        ? int.tryParse(_minPriceCtrl.text)
        : null;
    final maxPrice = _maxPriceCtrl.text.isNotEmpty
        ? int.tryParse(_maxPriceCtrl.text)
        : null;
    final minArea =
        _minAreaCtrl.text.isNotEmpty ? int.tryParse(_minAreaCtrl.text) : null;
    final maxArea =
        _maxAreaCtrl.text.isNotEmpty ? int.tryParse(_maxAreaCtrl.text) : null;

    // Validation
    if (minBedrooms != null &&
        maxBedrooms != null &&
        minBedrooms > maxBedrooms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Min Bedrooms cannot be greater than Max Bedrooms'),
        ),
      );
      return;
    }

    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Min Price cannot be greater than Max Price'),
        ),
      );
      return;
    }

    if (minArea != null && maxArea != null && minArea > maxArea) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Min Area cannot be greater than Max Area'),
        ),
      );
      return;
    }

    // Save current filter state before returning
    _saveFilterState();

    Navigator.pop<Map<String, dynamic>>(context, {
      'propertyTypes': _selectedPropertyTypes.toList(),
      'minBedrooms': minBedrooms,
      'maxBedrooms': maxBedrooms,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minArea': minArea,
      'maxArea': maxArea,
      'isFurnished': _isFurnished,
      'hasParking': _hasParking,
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
          // 1. Property type
          _sectionLabel('Property type'),
          const SizedBox(height: 10),
          _propertyTypeChips(),
          const SizedBox(height: 20),

          // 2. Bedrooms
          _sectionLabel('Bedrooms'),
          const SizedBox(height: 10),
          _bedroomChips(),
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

          // 4. Area (sqft)
          _sectionLabel('Area (sqft)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _minAreaCtrl,
                  hint: 'Min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _maxAreaCtrl,
                  hint: 'Max',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Furnishing
          _sectionLabel('Furnishing'),
          const SizedBox(height: 10),
          _furnishingChips(),
          const SizedBox(height: 20),

          // 6. Parking
          _sectionLabel('Parking'),
          const SizedBox(height: 10),
          _parkingChips(),

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
  // Property type chips
  // ===========================================================================
  Widget _propertyTypeChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _propertyTypeMap.entries.map((entry) {
        final key = entry.key;
        final selected = _selectedPropertyTypes.contains(key);
        return _filterChip(
          label: entry.value,
          selected: selected,
          onTap: () {
            setState(() {
              if (selected) {
                _selectedPropertyTypes.remove(key);
              } else {
                _selectedPropertyTypes.add(key);
              }
            });
            _refreshCount();
          },
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // Bedroom chips (write to controllers as source of truth)
  // ===========================================================================
  Widget _bedroomChips() {
    final min = _minBedroomsCtrl.text;
    final max = _maxBedroomsCtrl.text;

    bool isExact(String n) => min == n && max == n;
    final isFourPlus = min == '4' && max.isEmpty;
    final isAny = min.isEmpty && max.isEmpty;

    void setBedrooms(String? minVal, String? maxVal) {
      setState(() {
        _minBedroomsCtrl.text = minVal ?? '';
        _maxBedroomsCtrl.text = maxVal ?? '';
      });
      _refreshCount();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterChip(
          label: '1',
          selected: isExact('1'),
          onTap: () => setBedrooms('1', '1'),
        ),
        _filterChip(
          label: '2',
          selected: isExact('2'),
          onTap: () => setBedrooms('2', '2'),
        ),
        _filterChip(
          label: '3',
          selected: isExact('3'),
          onTap: () => setBedrooms('3', '3'),
        ),
        _filterChip(
          label: '4+',
          selected: isFourPlus,
          onTap: () => setBedrooms('4', ''),
        ),
        _filterChip(
          label: 'Any',
          selected: isAny,
          onTap: () => setBedrooms('', ''),
        ),
      ],
    );
  }

  // ===========================================================================
  // Furnishing chips
  // ===========================================================================
  Widget _furnishingChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterChip(
          label: 'Furnished',
          selected: _isFurnished == true,
          onTap: () {
            setState(() {
              _isFurnished = _isFurnished == true ? null : true;
            });
            _refreshCount();
          },
        ),
        _filterChip(
          label: 'Unfurnished',
          selected: _isFurnished == false,
          onTap: () {
            setState(() {
              _isFurnished = _isFurnished == false ? null : false;
            });
            _refreshCount();
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // Parking chip
  // ===========================================================================
  Widget _parkingChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterChip(
          label: 'Parking available',
          selected: _hasParking == true,
          onTap: () {
            setState(() {
              _hasParking = _hasParking == true ? null : true;
            });
            _refreshCount();
          },
        ),
      ],
    );
  }
}
