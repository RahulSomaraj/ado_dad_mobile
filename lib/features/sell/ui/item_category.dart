import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/models/cayegory_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItemCategory extends StatelessWidget {
  const ItemCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        title: Text(
          'Select Category',
          style: AppTextstyle.appbarText,
        ),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final category = categories[index];
          return Column(
            children: [
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    child: SizedBox(
                      height: 100,
                      child: Center(
                        child: ListTile(
                          leading: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppColors.greyColor.withValues(alpha: 1.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(category.image),
                          ),
                          title: Text(category.name),
                          trailing: Image.asset(
                              'assets/images/category-select-arrow.png'),
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
