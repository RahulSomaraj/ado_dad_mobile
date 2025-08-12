import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

enum FieldType { phone, password }

class _LoginWidgetState extends State<LoginWidget> {
  String _selectedCountryCode = "+1";
  String _selectedFlag = "🇺🇸";
  String _phoneNumber = "";
  String _password = "";
  bool _isPasswordVisible = false; // 🔹 Password visibility state

  void _onPhoneChanged(String phone) {
    setState(() => _phoneNumber = phone);
  }

  void _onPasswordChanged(String password) {
    setState(() => _password = password);
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
          _selectedFlag = country.flagEmoji;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/Ado-dad.png'),
              const SizedBox(height: 30),
              Text(
                'Login to your Account',
                style: AppTextstyle.title1,
              ),
              const Text(
                  'Securely log in and enjoy a seamless experience\nwith us!'),
              const SizedBox(height: 20),
              _buildPhoneNumberField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildButton(),
              const SizedBox(height: 30),
              Center(
                  child: Text(
                'Or',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blackColor1),
              )),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Login with Email',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blackColor1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New User?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blackColor)),
                  GestureDetector(
                    child: Text('Signup',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor)),
                  )
                ],
              ),
              const SizedBox(height: 100),
              Center(
                child: GestureDetector(
                  child: Text(
                    'Terms & Conditions',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: AppColors.primaryColor),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return _buildFormField(
      label: "Phone Number",
      initialValue: _phoneNumber,
      fieldType: FieldType.phone,
      onSaved: (value) => _onPhoneChanged(value ?? ""),
      prefixWidget: GestureDetector(
        onTap: _showCountryPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedFlag, style: const TextStyle(fontSize: 25)),
            const SizedBox(width: 10),
            SizedBox(
              height: 25,
              child: const VerticalDivider(
                  width: 10, thickness: 1.5, color: AppColors.greyColor),
            ),
            const SizedBox(width: 10),
            Text(_selectedCountryCode,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.greyColor)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildFormField(
      label: "Password",
      initialValue: _password,
      fieldType: FieldType.password,
      isPasswordVisible: _isPasswordVisible,
      onTogglePassword: _togglePasswordVisibility,
      onSaved: (value) => _onPasswordChanged(value ?? ""),
    );
  }

  Widget _buildFormField({
    required String label,
    required String initialValue,
    required Function(String?) onSaved,
    required FieldType fieldType,
    Widget? prefixWidget,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        prefixIcon: prefixWidget != null
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 5),
                child: prefixWidget,
              )
            : null,
        suffixIcon: fieldType == FieldType.password
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
      obscureText: fieldType == FieldType.password && !isPasswordVisible,
      keyboardType: fieldType == FieldType.phone
          ? TextInputType.phone
          : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }
        if (fieldType == FieldType.phone &&
            !RegExp(r"^[0-9]{10,}$").hasMatch(value)) {
          return "Enter a valid phone number (10+ digits)";
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.whiteColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        onPressed: () {},
        child: Text(
          'Login',
          style: AppTextstyle.buttonText,
        ),
      ),
    );
  }
}
