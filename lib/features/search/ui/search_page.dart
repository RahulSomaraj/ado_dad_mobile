import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/data/dummy_data.dart';
import 'package:ado_dad_user/models/advertisement/vehicle_model.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<Vehicle> allVehicles = DummyData.vehicles;
  List<Vehicle> filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    filteredVehicles = allVehicles; // Initially, show all vehicles
  }

  // Function to filter the vehicles based on the search term
  void _filterVehicles(String query) {
    final filteredList = allVehicles.where((vehicle) {
      // Convert the modelType to lowercase and check if query is a substring
      return vehicle.modelType.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredVehicles = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        backgroundColor: AppColors.whiteColor,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            fillColor: Colors.grey[50],
            hintText: "Search...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            prefixIcon: Image.asset(
              'assets/images/search-icon.png',
              color: AppColors.greyColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _filterVehicles('');
                      setState(() {});
                    },
                    child: Image.asset('assets/images/close.png'),
                  )
                : null,
          ),
          onChanged: (value) {
            _filterVehicles(value);
            setState(() {});
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                GestureDetector(
                  child: Image.asset('assets/images/location.png'),
                ),
                SizedBox(width: 15),
                GestureDetector(
                  child: Image.asset('assets/images/filter.png'),
                )
              ],
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: filteredVehicles.length,
        itemBuilder: (BuildContext context, int index) {
          final vehicle = filteredVehicles[index];
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: GestureDetector(
                  child: Card(
                      color: AppColors.whiteColor,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                // 'assets/images/car 2.png',
                                vehicle.imageUrls.isNotEmpty
                                    ? vehicle.imageUrls[0]
                                    : '',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '₹ ${vehicle.price}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Spacer(),
                                      if (vehicle.isPremium)
                                        Image.asset(
                                            'assets/images/card-premium-icon.png'),
                                      SizedBox(width: 10),
                                      if (vehicle.isFavorite)
                                        Image.asset(
                                            'assets/images/card-whishlist-icon.png')
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '${vehicle.vehicleDetails.modelName}(${vehicle.vehicleDetails.details.modelYear})',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '${vehicle.kmDriven.toString()}KM/${vehicle.vehicleDetails.vehicleModel.fuelType}',
                                    style: AppTextstyle.categoryLabelTextStyle,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '${vehicle.city},${vehicle.district}',
                                    style: AppTextstyle.categoryLabelTextStyle,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
