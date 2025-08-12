import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CarFiltersPage extends StatefulWidget {
  const CarFiltersPage({super.key});

  @override
  State<CarFiltersPage> createState() => _CarFiltersPageState();
}

class _CarFiltersPageState extends State<CarFiltersPage> {
  final List<String> categories = const [
    'Brands',
    'Model',
    'Price',
    'Fuel Type',
    'Transmission',
    'Year',
    'KM Driven',
  ];

  final List<String> allBrands = const [
    'Toyota',
    'Mahindra',
    'Hyundai',
    'Tata Motors',
    'Maruti Suzuki',
    'Nissan',
    'MG (Morris Garages)',
    'Lexus',
    'Volkswagen',
    'Land Rover',
  ];

  int selectedCategoryIndex = 0;
  final Set<String> selectedBrands = {};
  String brandQuery = '';
  int? minYear;
  int? maxYear;

  final _minYearCtrl = TextEditingController();
  final _maxYearCtrl = TextEditingController();

  @override
  void dispose() {
    _minYearCtrl.dispose();
    _maxYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final leftPaneWidth = w < 500 ? 150.0 : (w < 900 ? 180.0 : 240.0);

    final filteredBrands = allBrands
        .where((b) => b.toLowerCase().contains(brandQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Filters (Car)'),
        centerTitle: false,
        elevation: 0.5,
      ),
      body: Row(
        children: [
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
                  child: Container(
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
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: Builder(
                builder: (_) {
                  final yearIndex = categories.indexOf('Year');

                  if (selectedCategoryIndex == yearIndex) {
                    return _yearPanel();
                  }
                  if (selectedCategoryIndex != 0) {
                    return Center(
                      child: Text(
                        'Select "${categories[selectedCategoryIndex]}" filters here',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // search
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: TextField(
                          onChanged: (v) => setState(() => brandQuery = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: 'Search Brand',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // list
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                          itemBuilder: (_, i) {
                            final brand = filteredBrands[i];
                            final checked = selectedBrands.contains(brand);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) {
                                setState(() {
                                  if (checked) {
                                    selectedBrands.remove(brand);
                                  } else {
                                    selectedBrands.add(brand);
                                  }
                                });
                              },
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              title: Text(
                                brand,
                                style: theme.textTheme.titleMedium,
                              ),
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemCount: filteredBrands.length,
                        ),
                      ),
                    ],
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
                // Collect all selected filters
                final min = _minYearCtrl.text.isNotEmpty
                    ? int.tryParse(_minYearCtrl.text)
                    : null;
                final max = _maxYearCtrl.text.isNotEmpty
                    ? int.tryParse(_maxYearCtrl.text)
                    : null;

                if (min != null && max != null && min > max) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Min Year cannot be greater than Max Year')),
                  );
                  return;
                }

                final filters = {
                  'brands': selectedBrands.toList(),
                  'minYear': min,
                  'maxYear': max,
                };

                debugPrint('Applied Filters: $filters');

                Navigator.pop(context, filters);
              },
              child: Text(
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

  Widget _yearPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _minYearCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Min Year',
              // hintText: 'e.g. 2010',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxYearCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Year',
              // hintText: 'e.g. 2025',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
