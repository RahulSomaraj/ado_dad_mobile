import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/dropdown_widget.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VehicleEssentialDetails extends StatefulWidget {
  final String categoryTitle;
  const VehicleEssentialDetails({super.key, required this.categoryTitle});

  @override
  State<VehicleEssentialDetails> createState() =>
      _VehicleEssentialDetailsState();
}

class _VehicleEssentialDetailsState extends State<VehicleEssentialDetails> {
  List<String> generateYears() {
    int currentYear = DateTime.now().year;
    return List.generate(50, (index) => (currentYear - index).toString());
  }

  @override
  Widget build(BuildContext context) {
    final years = generateYears();
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
              //     .add(const AddItemEvent.navigateCategory());
              context.pop();
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
          child: Column(
            children: [
              Column(
                children: [
                  Divider(thickness: 2),
                  SizedBox(
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Sell your ${widget.categoryTitle}",
                              style: AppTextstyle.sellCategoryText,
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              context.go('/item-category');
                            },
                            child: Container(
                              height: 35,
                              width: 135,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Change Category",
                                  style: AppTextstyle
                                      .changeCategoryButtonTextStyle,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  Container(
                    width: double.infinity,
                    color: AppColors.whiteColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Essential Details',
                            style: AppTextstyle.sectionTitleTextStyle,
                          ),
                          SizedBox(height: 20),
                          DropdownWidget(
                            labelText: 'Brand Name *',
                            items: const ['Brand 1', 'Brand 2', 'Brand 3'],
                            // selectedValue: _selectedBrand,
                            onChanged: (value) => setState(() {
                              // _selectedBrand = value;
                            }),
                            errorMsg: 'Select Brand Name',
                          ),
                          SizedBox(height: 10),
                          DropdownWidget(
                            labelText: 'Model Name *',
                            items: const ['Model 1', 'Model 2', 'Model 3'],
                            // selectedValue: _selectedModel,
                            onChanged: (value) => setState(() {
                              // _selectedModel = value;
                            }),
                            errorMsg: 'Select Model Name',
                          ),
                          SizedBox(height: 10),
                          DropdownWidget(
                            labelText: 'Transmission *',
                            items: const [
                              'Transmission 1',
                              'Transmission 2',
                              'Transmission 3'
                            ],
                            // selectedValue: _selectedTransmission,
                            onChanged: (value) => setState(() {
                              // _selectedTransmission = value;
                            }),
                            errorMsg: 'Select Transmission',
                          ),
                          SizedBox(height: 10),
                          DropdownWidget(
                            labelText: 'Fuel Type *',
                            items: const ['Fuel 1', 'Fuel 2', 'Fuel 3'],
                            // selectedValue: _selectedFuelType,
                            onChanged: (value) => setState(() {
                              // _selectedFuelType = value;
                            }),
                            errorMsg: 'Select Fuel Type',
                          ),
                          SizedBox(height: 10),
                          DropdownWidget(
                            labelText: 'Registration Year *',
                            items: years,
                            // selectedValue: _selectedYear,
                            onChanged: (value) => setState(() {
                              // _selectedYear = value;
                            }),
                            errorMsg: 'Select Year',
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'KM Driven *',
                            initialValue: '',
                            // onSaved: (value) => _name = value!,
                            isNumberField: true,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'No.of Owners *',
                            initialValue: '',
                            // onSaved: (value) => _name = value!,
                            isNumberField: true,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Add Title *',
                            initialValue: '',
                            // onSaved: (value) => _name = value!,
                          ),
                          SizedBox(height: 10),
                          GetInput(
                            label: 'Description',
                            initialValue: '',
                            // onSaved: (value) => _name = value!,
                            maxLines: 5,
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a Price',
                      style: AppTextstyle.sectionTitleTextStyle,
                    ),
                    SizedBox(height: 20),
                    GetInput(
                      label: 'Price *',
                      initialValue: '',
                      // onSaved: (value) => _name = value!,
                      isNumberField: true,
                      isPrice: true,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/vehicle-more-detail');
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
                            " Continue",
                            style: AppTextstyle.buttonText,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
