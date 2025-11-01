import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemCategory extends StatelessWidget {
  const ItemCategory({super.key});

  @override
  Widget build(BuildContext context) {
    // Filter out showroom category
    final filteredCategories =
        categories.where((cat) => cat.categoryId != 'showroom').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 30,
              largeTablet: 32,
              desktop: 36,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Category',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: AppTextstyle.appbarText.fontSize ?? 20,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 10,
            tablet: 16,
            largeTablet: 22,
            desktop: 28,
          ),
        ),
        itemCount: filteredCategories.length,
        itemBuilder: (BuildContext context, int index) {
          final category = filteredCategories[index];
          return Column(
            children: [
              SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 10,
                  tablet: 16,
                  largeTablet: 22,
                  desktop: 28,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 20,
                    tablet: 28,
                    largeTablet: 36,
                    desktop: 44,
                  ),
                ),
                child: GestureDetector(
                  // onTap: () {
                  //   if (category.name == "Real Estate") {
                  //     context.push('/property-category-selection');
                  //   } else {
                  //     context.push(
                  //         '/advertisement-form1?category=${Uri.encodeComponent(category.name)}');
                  //   }
                  // },
                  onTap: () {
                    final Map<String, String> payload = {
                      'categoryTitle': category.name,
                      'categoryId': category.categoryId,
                    };

                    switch (category.categoryId) {
                      case 'two_wheeler':
                        context.push('/add-two-wheeler-form', extra: payload);
                        break;
                      case 'private_vehicle':
                        context.push('/add-private-vehicle-form',
                            extra: payload);
                        break;
                      case 'commercial_vehicle':
                        context.push('/add-commercial-vehicle-form',
                            extra: payload);
                        break;
                      case 'property':
                        context.push('/add-property-form', extra: payload);
                        break;
                    }
                  },

                  child: Card(
                    color: AppColors.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GetResponsiveSize.getResponsiveBorderRadius(
                          context,
                          mobile: 12,
                          tablet: 16,
                          largeTablet: 20,
                          desktop: 24,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 100,
                        tablet: 140,
                        largeTablet: 170,
                        desktop: 200,
                      ),
                      child: Center(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 24,
                              largeTablet: 32,
                              desktop: 40,
                            ),
                          ),
                          leading: Container(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 50,
                              tablet: 80,
                              largeTablet: 100,
                              desktop: 120,
                            ),
                            width: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 50,
                              tablet: 80,
                              largeTablet: 100,
                              desktop: 120,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greyColor.withValues(alpha: 1.6),
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(
                                  context,
                                  mobile: 10,
                                  tablet: 14,
                                  largeTablet: 18,
                                  desktop: 22,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  largeTablet: 16,
                                  desktop: 20,
                                ),
                              ),
                              child: Image.asset(category.image),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: AppTextstyle.appbarText.copyWith(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: AppTextstyle.appbarText.fontSize ?? 16,
                                tablet: 22,
                                largeTablet: 28,
                                desktop: 34,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Image.asset(
                            'assets/images/category-select-arrow.png',
                            width: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 24,
                              tablet: 32,
                              largeTablet: 40,
                              desktop: 48,
                            ),
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 24,
                              tablet: 32,
                              largeTablet: 40,
                              desktop: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
