import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:flutter/material.dart';

class DropdownWidget<T> extends StatelessWidget {
  final String labelText;
  final String errorMsg;
  final List<T> items;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;

  const DropdownWidget({
    super.key,
    required this.labelText,
    required this.errorMsg,
    required this.items,
    this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<T>(
      decoration:
          CommonDecoration.textFieldDecoration(labelText: labelText).copyWith(
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
      value: selectedValue,
      dropdownColor: Colors.white,
      isExpanded: true,
      iconSize: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 24,
        tablet: 28,
        largeTablet: 32,
        desktop: 36,
      ),
      items: items.map((T value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(
            value.toString(),
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
      onChanged: onChanged,
      validator: (value) => value == null ? errorMsg : null,
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
}

// 🔹 Helper function to build dropdown with dynamic type
Widget buildDropdown<T>({
  required String labelText,
  required List<T> items,
  required T? selectedValue,
  required ValueChanged<T?> onChanged,
  required String errorMsg,
}) {
  return DropdownWidget<T>(
    labelText: labelText,
    items: items,
    selectedValue: selectedValue,
    onChanged: onChanged,
    errorMsg: errorMsg,
  );
}

class DividerWidget extends StatelessWidget {
  const DividerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Colors.grey,
      thickness: 0.2,
      indent: 0,
      endIndent: 0,
    );
  }
}
