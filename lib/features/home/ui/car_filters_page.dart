import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/home/fuelType_filter_bloc/fuel_type_filter_bloc.dart';

import 'package:ado_dad_user/features/home/manufacturer_bloc/manufacturer_bloc.dart';
import 'package:ado_dad_user/features/home/model_filter_bloc/model_filter_bloc.dart';
import 'package:ado_dad_user/features/home/transmissionType_filter_bloc/transmission_type_filter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    // 'KM Driven',
  ];

  int selectedCategoryIndex = 0;
  String brandQuery = '';
  String modelQuery = '';
  final Set<String> _selectedManufacturerIds = {};
  final Set<String> _selectedFuelTypeIds = {};
  final Set<String> _selectedTransmissionTypeIds = {};
  final Set<String> _selectedModelIds = {};
  final _minYearCtrl = TextEditingController();
  final _maxYearCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  @override
  void dispose() {
    _minYearCtrl.dispose();
    _maxYearCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
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
          'Filters',
          style: AppTextstyle.appbarText,
        ),
        elevation: 0.5,
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
                  final yearIndex = categories.indexOf('Year');
                  final priceIndex = categories.indexOf('Price');

                  if (selectedCategoryIndex == yearIndex) {
                    return _yearPanel();
                  }

                  if (selectedCategoryIndex == priceIndex) {
                    return _pricePanel();
                  }

                  if (selectedCategoryIndex == 0) {
                    return BlocBuilder<ManufacturerBloc, ManufacturerState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () => const SizedBox.shrink(),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (msg) => Center(child: Text(msg)),
                          loaded: (items) {
                            final filtered = items.where((m) {
                              final name = m.displayName.toLowerCase();
                              return brandQuery.isEmpty ||
                                  name.contains(brandQuery.toLowerCase());
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => brandQuery = v),
                                    decoration: InputDecoration(
                                      prefixIcon:
                                          const Icon(Icons.search_rounded),
                                      hintText: 'Search Brand',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      final id = m.id;
                                      final name = m.displayName.trim();
                                      final checked =
                                          _selectedManufacturerIds.contains(id);

                                      return CheckboxListTile(
                                        value: checked,
                                        onChanged: (_) {
                                          setState(() {
                                            if (checked) {
                                              _selectedManufacturerIds
                                                  .remove(id);
                                            } else {
                                              _selectedManufacturerIds.add(id);
                                            }
                                          });
                                        },
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        title: Text(name,
                                            style: theme.textTheme.titleMedium),
                                        checkboxShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 2),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }

                  //Model Filters

                  if (selectedCategoryIndex == 1) {
                    return BlocBuilder<ModelFilterBloc, ModelFilterState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () => const SizedBox.shrink(),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (msg) => Center(child: Text(msg)),
                          loaded: (items) {
                            final filtered = items.where((m) {
                              final name = m.displayName.toLowerCase();
                              return modelQuery.isEmpty ||
                                  name.contains(modelQuery.toLowerCase());
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => modelQuery = v),
                                    decoration: InputDecoration(
                                      prefixIcon:
                                          const Icon(Icons.search_rounded),
                                      hintText: 'Search Model',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      final id = m.id;
                                      final name = m.displayName.trim();
                                      final checked =
                                          _selectedModelIds.contains(id);

                                      return CheckboxListTile(
                                        value: checked,
                                        onChanged: (_) {
                                          setState(() {
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        title: Text(name,
                                            style: theme.textTheme.titleMedium),
                                        checkboxShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 2),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }

                  //Fuel Type Filters
                  if (selectedCategoryIndex == 3) {
                    return BlocBuilder<FuelTypeFilterBloc, FuelTypeFilterState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () => const SizedBox.shrink(),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (msg) => Center(child: Text(msg)),
                          loaded: (items) {
                            final filtered = items.where((m) {
                              final name = m.displayName.toLowerCase();
                              return brandQuery.isEmpty ||
                                  name.contains(brandQuery.toLowerCase());
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Padding(
                                //   padding:
                                //       const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                //   child: TextField(
                                //     onChanged: (v) =>
                                //         setState(() => brandQuery = v),
                                //     decoration: InputDecoration(
                                //       prefixIcon:
                                //           const Icon(Icons.search_rounded),
                                //       hintText: 'Search Brand',
                                //       contentPadding:
                                //           const EdgeInsets.symmetric(
                                //               vertical: 14, horizontal: 12),
                                //       border: OutlineInputBorder(
                                //         borderRadius: BorderRadius.circular(6),
                                //       ),
                                //     ),
                                //   ),
                                // ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      final id = m.id;
                                      final name = m.displayName.trim();
                                      final checked =
                                          _selectedFuelTypeIds.contains(id);

                                      return CheckboxListTile(
                                        value: checked,
                                        onChanged: (_) {
                                          setState(() {
                                            if (checked) {
                                              _selectedFuelTypeIds.remove(id);
                                            } else {
                                              _selectedFuelTypeIds.add(id);
                                            }
                                          });
                                        },
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        title: Text(name,
                                            style: theme.textTheme.titleMedium),
                                        checkboxShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 2),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }

                  //Transmission Type Filters
                  if (selectedCategoryIndex == 4) {
                    return BlocBuilder<TransmissionTypeFilterBloc,
                        TransmissionTypeFilterState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () => const SizedBox.shrink(),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (msg) => Center(child: Text(msg)),
                          loaded: (items) {
                            final filtered = items.where((m) {
                              final name = m.displayName.toLowerCase();
                              return brandQuery.isEmpty ||
                                  name.contains(brandQuery.toLowerCase());
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Padding(
                                //   padding:
                                //       const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                //   child: TextField(
                                //     onChanged: (v) =>
                                //         setState(() => brandQuery = v),
                                //     decoration: InputDecoration(
                                //       prefixIcon:
                                //           const Icon(Icons.search_rounded),
                                //       hintText: 'Search Brand',
                                //       contentPadding:
                                //           const EdgeInsets.symmetric(
                                //               vertical: 14, horizontal: 12),
                                //       border: OutlineInputBorder(
                                //         borderRadius: BorderRadius.circular(6),
                                //       ),
                                //     ),
                                //   ),
                                // ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 20),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final m = filtered[i];
                                      final id = m.id;
                                      final name = m.displayName.trim();
                                      final checked =
                                          _selectedTransmissionTypeIds
                                              .contains(id);

                                      return CheckboxListTile(
                                        value: checked,
                                        onChanged: (_) {
                                          setState(() {
                                            if (checked) {
                                              _selectedTransmissionTypeIds
                                                  .remove(id);
                                            } else {
                                              _selectedTransmissionTypeIds
                                                  .add(id);
                                            }
                                          });
                                        },
                                        dense: true,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 0),
                                        title: Text(name,
                                            style: theme.textTheme.titleMedium),
                                        checkboxShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 2),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
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
                final min = _minYearCtrl.text.isNotEmpty
                    ? int.tryParse(_minYearCtrl.text)
                    : null;
                final max = _maxYearCtrl.text.isNotEmpty
                    ? int.tryParse(_maxYearCtrl.text)
                    : null;

                final minP = _minPriceCtrl.text.isNotEmpty
                    ? int.tryParse(_minPriceCtrl.text)
                    : null;
                final maxP = _maxPriceCtrl.text.isNotEmpty
                    ? int.tryParse(_maxPriceCtrl.text)
                    : null;

                if (min != null && max != null && min > max) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Min Year cannot be greater than Max Year')),
                  );
                  return;
                }

                if (minP != null && maxP != null && minP > maxP) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Min Price cannot be greater than Max Price')),
                  );
                  return;
                }

                Navigator.pop<Map<String, dynamic>>(context, {
                  'manufacturerIds': _selectedManufacturerIds.toList(),
                  'fuelTypeIds': _selectedFuelTypeIds.toList(),
                  'transmissionTypeIds': _selectedTransmissionTypeIds.toList(),
                  'modelIds': _selectedModelIds.toList(),
                  'minYear': min,
                  'maxYear': max,
                  'minPrice': minP,
                  'maxPrice': maxP
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxYearCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Year',
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
              labelText: 'Min Price',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxPriceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max Price',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
