import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
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
  final List<String> categories = const [
    'Property Type',
    'Bedrooms',
    'Price',
    'Area Sqft',
    'Furnish',
    'Parking Facility',
  ];

  int selectedCategoryIndex = 0;
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
    _minBedroomsCtrl.dispose();
    _maxBedroomsCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftPaneWidth = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 150.0, // Keep mobile unchanged
      tablet: 200.0,
      largeTablet: 260.0,
      desktop: 300.0,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 20.0, // Keep mobile unchanged
              tablet: 26.0,
              largeTablet: 30.0,
              desktop: 34.0,
            ),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Property Filters',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 18.0, // Keep mobile unchanged
              tablet: 24.0,
              largeTablet: 28.0,
              desktop: 32.0,
            ),
          ),
        ),
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: () {
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
                _filterStateService
                    .clearPropertyFilterState(widget.categoryId!);
              }
            },
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 14.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // left categories
          Container(
            width: leftPaneWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemBuilder: (context, index) {
                final isSelected = index == selectedCategoryIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => selectedCategoryIndex = index),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text(
                      categories[index],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: theme.textTheme.titleMedium?.fontSize ??
                              16.0, // Keep mobile unchanged
                          tablet: 22.0,
                          largeTablet: 24.0,
                          desktop: 28.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: categories.length,
            ),
          ),

          // right panel
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: Builder(
                builder: (_) {
                  final bedroomsIndex = categories.indexOf('Bedrooms');
                  final priceIndex = categories.indexOf('Price');
                  final areaIndex = categories.indexOf('Area Sqft');
                  final furnishIndex = categories.indexOf('Furnish');
                  final parkingIndex = categories.indexOf('Parking Facility');

                  if (selectedCategoryIndex == bedroomsIndex) {
                    return _bedroomsPanel();
                  }

                  if (selectedCategoryIndex == priceIndex) {
                    return _pricePanel();
                  }

                  if (selectedCategoryIndex == areaIndex) {
                    return _areaPanel();
                  }

                  if (selectedCategoryIndex == furnishIndex) {
                    return _furnishPanel();
                  }

                  if (selectedCategoryIndex == parkingIndex) {
                    return _parkingPanel();
                  }

                  if (selectedCategoryIndex == 0) {
                    return _propertyTypePanel();
                  }

                  return Center(
                    child: Text(
                      'Select "${categories[selectedCategoryIndex]}" filters here',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16.0,
              tablet: 20.0,
              largeTablet: 24.0,
              desktop: 28.0,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 48, // Keep mobile unchanged
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
              onPressed: () {
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
                final minArea = _minAreaCtrl.text.isNotEmpty
                    ? int.tryParse(_minAreaCtrl.text)
                    : null;
                final maxArea = _maxAreaCtrl.text.isNotEmpty
                    ? int.tryParse(_maxAreaCtrl.text)
                    : null;

                // Validation
                if (minBedrooms != null &&
                    maxBedrooms != null &&
                    minBedrooms > maxBedrooms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Min Bedrooms cannot be greater than Max Bedrooms'),
                    ),
                  );
                  return;
                }

                if (minPrice != null &&
                    maxPrice != null &&
                    minPrice > maxPrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Min Price cannot be greater than Max Price'),
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
              },
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16.0, // Keep mobile unchanged
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

  Widget _propertyTypePanel() {
    final theme = Theme.of(context);
    final filtered = _propertyTypeMap.entries.where((entry) {
      final name = entry.value.toLowerCase();
      return propertyTypeQuery.isEmpty ||
          name.contains(propertyTypeQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 8,
              tablet: 10,
              largeTablet: 12,
              desktop: 14,
            ),
          ),
          child: TextField(
            onChanged: (v) => setState(() => propertyTypeQuery = v),
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
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
                  mobile: 24.0, // Keep mobile unchanged
                  tablet: 28.0,
                  largeTablet: 32.0,
                  desktop: 36.0,
                ),
              ),
              hintText: 'Search Property Type',
              hintStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // View All option
        Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 30,
              tablet: 36,
              largeTablet: 42,
              desktop: 48,
            ),
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 8,
              tablet: 10,
              largeTablet: 12,
              desktop: 14,
            ),
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
            0,
          ),
          child: InkWell(
            onTap: () {
              Navigator.pop<Map<String, dynamic>>(context, {});
            },
            child: Text(
              'View All Properties',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 14.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final entry = filtered[i];
              final key = entry.key;
              final name = entry.value.trim();
              final checked = _selectedPropertyTypes.contains(key);

              return CheckboxListTile(
                value: checked,
                onChanged: (_) {
                  setState(() {
                    if (checked) {
                      _selectedPropertyTypes.remove(key);
                    } else {
                      _selectedPropertyTypes.add(key);
                    }
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 12,
                    tablet: 16,
                    largeTablet: 20,
                    desktop: 24,
                  ),
                  vertical: 0,
                ),
                title: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: theme.textTheme.titleMedium?.fontSize ??
                          16.0, // Keep mobile unchanged
                      tablet: 20.0,
                      largeTablet: 24.0,
                      desktop: 28.0,
                    ),
                  ),
                ),
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 4,
                      tablet: 5,
                      largeTablet: 6,
                      desktop: 6,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 2),
          ),
        ),
      ],
    );
  }

  Widget _bedroomsPanel() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        0,
      ),
      child: Column(
        children: [
          TextField(
            controller: _minBedroomsCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Min Bedrooms',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 12,
              tablet: 16,
              largeTablet: 20,
              desktop: 24,
            ),
          ),
          TextField(
            controller: _maxBedroomsCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Max Bedrooms',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricePanel() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        0,
      ),
      child: Column(
        children: [
          TextField(
            controller: _minPriceCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Min Price (₹)',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 12,
              tablet: 16,
              largeTablet: 20,
              desktop: 24,
            ),
          ),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Max Price (₹)',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaPanel() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        0,
      ),
      child: Column(
        children: [
          TextField(
            controller: _minAreaCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Min Area (sqft)',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 12,
              tablet: 16,
              largeTablet: 20,
              desktop: 24,
            ),
          ),
          TextField(
            controller: _maxAreaCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 22.0,
                desktop: 24.0,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Max Area (sqft)',
              labelStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
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
                    mobile: 6,
                    tablet: 8,
                    largeTablet: 10,
                    desktop: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _furnishPanel() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Furnishing Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: theme.textTheme.titleMedium?.fontSize ??
                    16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 24.0,
                desktop: 28.0,
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
          RadioListTile<bool>(
            title: Text(
              'Furnished',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
            value: true,
            groupValue: _isFurnished,
            onChanged: (bool? value) {
              setState(() {
                _isFurnished = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
          ),
          RadioListTile<bool>(
            title: Text(
              'Unfurnished',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
            value: false,
            groupValue: _isFurnished,
            onChanged: (bool? value) {
              setState(() {
                _isFurnished = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parkingPanel() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parking Facility',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: theme.textTheme.titleMedium?.fontSize ??
                    16.0, // Keep mobile unchanged
                tablet: 20.0,
                largeTablet: 24.0,
                desktop: 28.0,
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
          RadioListTile<bool>(
            title: Text(
              'Available',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
            value: true,
            groupValue: _hasParking,
            onChanged: (bool? value) {
              setState(() {
                _hasParking = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
          ),
          RadioListTile<bool>(
            title: Text(
              'Not Available',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 20.0,
                  largeTablet: 24.0,
                  desktop: 28.0,
                ),
              ),
            ),
            value: false,
            groupValue: _hasParking,
            onChanged: (bool? value) {
              setState(() {
                _hasParking = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
