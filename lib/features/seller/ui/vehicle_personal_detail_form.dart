import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/seller/bloc/seller_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class VehiclePersonalDetailForm extends StatefulWidget {
  final String addId;
  const VehiclePersonalDetailForm({super.key, required this.addId});

  @override
  State<VehiclePersonalDetailForm> createState() =>
      _VehiclePersonalDetailFormState();
}

class _VehiclePersonalDetailFormState extends State<VehiclePersonalDetailForm> {
  final GlobalKey<FormState> _sellerFormKey1 = GlobalKey<FormState>();
  String? _selectedState;
  String? _fullName;
  String? _phoneNumber;
  String? _city;
  String? _district = '';

  List<String> getStates() {
    return [
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
    ];
  }

  @override
  Widget build(BuildContext context) {
    print("Advertisement ID received: ${widget.addId}");
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0),
        child: AppBar(
          backgroundColor: AppColors.whiteColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // context
              //     .read<AddItemBloc>()
              //     .add(const AddItemEvent.navigateEssentialDetail());
            },
          ),
          title: Text(
            'Post your Ad',
            style: AppTextstyle.appbarText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _sellerFormKey1,
          child: Column(
            children: [
              Divider(thickness: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text(
                      'Personal Information',
                      style: AppTextstyle.sectionTitleTextStyle,
                    ),
                    SizedBox(height: 20),
                    GetInput(
                      label: 'Full Name *',
                      initialValue: _fullName,
                      onSaved: (value) => _fullName = value!,
                    ),
                    SizedBox(height: 10),
                    GetInput(
                      label: "Phone Number *",
                      initialValue: _phoneNumber,
                      onSaved: (value) => _phoneNumber = value!,
                      isPhone: true,
                    ),
                    SizedBox(height: 10),
                    DropdownWidget(
                      labelText: 'State *',
                      items: getStates(),
                      selectedValue: _selectedState,
                      onChanged: (value) => setState(() {
                        _selectedState = value;
                      }),
                      errorMsg: 'Select State',
                    ),
                    SizedBox(height: 10),
                    GetInput(
                      label: 'City *',
                      initialValue: _city,
                      onSaved: (value) => _city = value!,
                    ),
                    SizedBox(height: 10),
                    GetInput(
                      label: 'District *',
                      initialValue: _district,
                      onSaved: (value) => _district = value!,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_sellerFormKey1.currentState!.validate()) {
                            _sellerFormKey1.currentState!.save();

                            context
                                .read<SellerBloc>()
                                .add(SellerEvent.updatePersonalInfo(
                                  adId: widget.addId,
                                  fullName: _fullName!,
                                  phoneNumber: _phoneNumber!,
                                  state: _selectedState!,
                                  city: _city!,
                                  district: _district!,
                                ));

                            // Show success dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text("Success"),
                                  content: const Text(
                                      "Your advertisement have been submitted."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop(); // Close dialog
                                        context.go(
                                            '/home'); // Navigate to home using GoRouter
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.whiteColor,
                          // minimumSize: const Size(158, 27),
                          // fixedSize: const Size(316, 54),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            " Submit",
                            style: AppTextstyle.buttonText,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 60)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
