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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          decoration:
              CommonDecoration.textFieldDecoration(labelText: labelText),
          value: selectedValue,
          dropdownColor: Colors.white,
          items: items.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(
                value.toString(),
                // style: AppTextStyle.labelText
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? errorMsg : null,
        ),
      ],
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
