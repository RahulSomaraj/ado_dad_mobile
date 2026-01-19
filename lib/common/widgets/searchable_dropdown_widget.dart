import 'dart:async';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:flutter/material.dart';

class SearchableDropdownWidget<T> extends StatefulWidget {
  final String labelText;
  final String errorMsg;
  final List<T> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String Function(T) getDisplayText;
  final bool enabled;
  final Future<List<T>> Function(String query)? onSearch;
  final bool useCategoryFilter;
  final Map<String, String>? vehicleCategories;
  final Future<List<T>> Function(String category)? onCategoryFilter;

  const SearchableDropdownWidget({
    super.key,
    required this.labelText,
    required this.errorMsg,
    required this.items,
    this.selectedValue,
    required this.onChanged,
    required this.getDisplayText,
    this.enabled = true,
    this.onSearch,
    this.useCategoryFilter = false,
    this.vehicleCategories,
    this.onCategoryFilter,
  });

  @override
  State<SearchableDropdownWidget<T>> createState() =>
      _SearchableDropdownWidgetState<T>();
}

class _SearchableDropdownWidgetState<T>
    extends State<SearchableDropdownWidget<T>> {
  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
      readOnly: true,
      enabled: widget.enabled,
      controller: TextEditingController(
        text: widget.selectedValue != null
            ? widget.getDisplayText(widget.selectedValue as T)
            : '',
      ),
      decoration: CommonDecoration.textFieldDecoration(
        labelText: widget.labelText,
      ).copyWith(
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
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          size: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 24,
            tablet: 28,
            largeTablet: 32,
            desktop: 36,
          ),
        ),
      ),
      style: TextStyle(
        color: Colors.black,
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
      ),
      validator: (value) =>
          widget.selectedValue == null ? widget.errorMsg : null,
      onTap: widget.enabled ? () => _showSearchableDialog(context) : null,
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
            child: textField,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [textField],
    );
  }

  void _showSearchableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SearchableDialog<T>(
          title: widget.labelText,
          items: widget.items,
          selectedValue: widget.selectedValue,
          getDisplayText: widget.getDisplayText,
          onItemSelected: (item) {
            Navigator.of(dialogContext).pop();
            widget.onChanged(item);
          },
          onSearch: widget.onSearch,
          useCategoryFilter: widget.useCategoryFilter,
          vehicleCategories: widget.vehicleCategories,
          onCategoryFilter: widget.onCategoryFilter,
        );
      },
    );
  }
}

class _SearchableDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) getDisplayText;
  final ValueChanged<T?> onItemSelected;
  final Future<List<T>> Function(String query)? onSearch;
  final bool useCategoryFilter;
  final Map<String, String>? vehicleCategories;
  final Future<List<T>> Function(String category)? onCategoryFilter;

  const _SearchableDialog({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.getDisplayText,
    required this.onItemSelected,
    this.onSearch,
    this.useCategoryFilter = false,
    this.vehicleCategories,
    this.onCategoryFilter,
  });

  @override
  State<_SearchableDialog<T>> createState() => _SearchableDialogState<T>();
}

class _SearchableDialogState<T> extends State<_SearchableDialog<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];
  bool _isLoading = false;
  Timer? _searchTimer;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Show all items initially, even when using category filter
    _filteredItems = widget.items;
    if (!widget.useCategoryFilter) {
      _searchController.addListener(_onSearchChanged);
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    if (!widget.useCategoryFilter) {
      _searchController.removeListener(_onSearchChanged);
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    // Cancel previous timer
    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
        _isLoading = false;
      });
      return;
    }

    // If API search is provided, use it with debouncing
    if (widget.onSearch != null) {
      setState(() {
        _isLoading = true;
      });

      _searchTimer = Timer(const Duration(milliseconds: 500), () async {
        if (!mounted) return;
        try {
          final results = await widget.onSearch!(query);
          if (mounted) {
            setState(() {
              _filteredItems = results;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              // On error, fallback to local filtering
              _filteredItems = widget.items
                  .where((item) => widget
                      .getDisplayText(item)
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                  .toList();
            });
          }
        }
      });
    } else {
      // Local filtering (original behavior)
      final queryLower = query.toLowerCase();
      setState(() {
        _filteredItems = widget.items
            .where((item) =>
                widget.getDisplayText(item).toLowerCase().contains(queryLower))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width > 600
            ? 500
            : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 22,
                          largeTablet: 26,
                          desktop: 30,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      largeTablet: 32,
                      desktop: 36,
                    ),
                  ),
                ],
              ),
            ),
            // Category dropdown or Search box
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
              ),
              child: widget.useCategoryFilter &&
                      widget.vehicleCategories != null
                  ? DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Select vehicle category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                            mobile: 12,
                            tablet: 16,
                            largeTablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'All Categories',
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 20,
                                largeTablet: 22,
                                desktop: 24,
                              ),
                            ),
                          ),
                        ),
                        ...widget.vehicleCategories!.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  largeTablet: 22,
                                  desktop: 24,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? category) async {
                        setState(() {
                          _selectedCategory = category;
                        });

                        if (category == null) {
                          // Show all items when "All Categories" is selected
                          setState(() {
                            _filteredItems = widget.items;
                            _isLoading = false;
                          });
                        } else if (widget.onCategoryFilter != null) {
                          setState(() {
                            _isLoading = true;
                            _filteredItems = [];
                          });
                          try {
                            final results =
                                await widget.onCategoryFilter!(category);
                            if (mounted) {
                              setState(() {
                                _filteredItems = results;
                                _isLoading = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                // On error, fallback to all items
                                _filteredItems = widget.items;
                              });
                            }
                          }
                        }
                      },
                    )
                  : TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.title.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                            mobile: 12,
                            tablet: 16,
                            largeTablet: 18,
                            desktop: 20,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 22,
                          desktop: 24,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // List of items
            Flexible(
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(
                        GetResponsiveSize.getResponsivePadding(
                          context,
                          mobile: 16,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 28,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _filteredItems.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(
                            GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 20,
                              largeTablet: 24,
                              desktop: 28,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.useCategoryFilter &&
                                      _selectedCategory == null
                                  ? 'Please select a vehicle category first'
                                  : 'No items found',
                              style: TextStyle(
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 18,
                                  largeTablet: 20,
                                  desktop: 24,
                                ),
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = item == widget.selectedValue;
                            return InkWell(
                              onTap: () => widget.onItemSelected(item),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      GetResponsiveSize.getResponsivePadding(
                                    context,
                                    mobile: 16,
                                    tablet: 20,
                                    largeTablet: 24,
                                    desktop: 28,
                                  ),
                                  vertical:
                                      GetResponsiveSize.getResponsivePadding(
                                    context,
                                    mobile: 12,
                                    tablet: 16,
                                    largeTablet: 18,
                                    desktop: 20,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.getDisplayText(item),
                                        style: TextStyle(
                                          fontSize: GetResponsiveSize
                                              .getResponsiveFontSize(
                                            context,
                                            mobile: 16,
                                            tablet: 20,
                                            largeTablet: 24,
                                            desktop: 28,
                                          ),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                        size:
                                            GetResponsiveSize.getResponsiveSize(
                                          context,
                                          mobile: 20,
                                          tablet: 24,
                                          largeTablet: 28,
                                          desktop: 32,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to build searchable dropdown with dynamic type
Widget buildSearchableDropdown<T>({
  required String labelText,
  required List<T> items,
  required T? selectedValue,
  required ValueChanged<T?> onChanged,
  required String errorMsg,
  required String Function(T) getDisplayText,
  bool enabled = true,
  Future<List<T>> Function(String query)? onSearch,
  bool useCategoryFilter = false,
  Map<String, String>? vehicleCategories,
  Future<List<T>> Function(String category)? onCategoryFilter,
}) {
  return SearchableDropdownWidget<T>(
    labelText: labelText,
    items: items,
    selectedValue: selectedValue,
    onChanged: onChanged,
    errorMsg: errorMsg,
    getDisplayText: getDisplayText,
    enabled: enabled,
    onSearch: onSearch,
    useCategoryFilter: useCategoryFilter,
    vehicleCategories: vehicleCategories,
    onCategoryFilter: onCategoryFilter,
  );
}
