import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:flutter/material.dart';

class PropertyFiltersPage extends StatefulWidget {
  const PropertyFiltersPage({super.key});

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
    final w = MediaQuery.of(context).size.width;
    final leftPaneWidth = w < 500 ? 150.0 : (w < 900 ? 180.0 : 240.0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Property Filters',
          style: AppTextstyle.appbarText,
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
              });
            },
            child: const Text('Clear All'),
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
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => propertyTypeQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search Property Type',
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                title: Text(name, style: theme.textTheme.titleMedium),
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _minBedroomsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min Bedrooms',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxBedroomsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Bedrooms',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricePanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _minPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min Price (₹)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Price (₹)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _minAreaCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min Area (sqft)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxAreaCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Area (sqft)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _furnishPanel() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Furnishing Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            title: const Text('Furnished'),
            value: true,
            groupValue: _isFurnished,
            onChanged: (bool? value) {
              setState(() {
                _isFurnished = value;
              });
            },
            activeColor: AppColors.primaryColor,
          ),
          RadioListTile<bool>(
            title: const Text('Unfurnished'),
            value: false,
            groupValue: _isFurnished,
            onChanged: (bool? value) {
              setState(() {
                _isFurnished = value;
              });
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _parkingPanel() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parking Facility',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            title: const Text('Available'),
            value: true,
            groupValue: _hasParking,
            onChanged: (bool? value) {
              setState(() {
                _hasParking = value;
              });
            },
            activeColor: AppColors.primaryColor,
          ),
          RadioListTile<bool>(
            title: const Text('Not Available'),
            value: false,
            groupValue: _hasParking,
            onChanged: (bool? value) {
              setState(() {
                _hasParking = value;
              });
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}
