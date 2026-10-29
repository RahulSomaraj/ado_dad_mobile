class CategoryModel {
  final int id;
  final String name;
  final String image;
  final String categoryId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.categoryId,
  });
}

final List<CategoryModel> categories = [
  CategoryModel(
    id: 1,
    name: 'Bike',
    image: 'assets/images/cat_bike.png',
    categoryId: 'two_wheeler',
  ),
  CategoryModel(
    id: 2,
    name: 'Car',
    image: 'assets/images/cat_car.png',
    categoryId: 'private_vehicle',
  ),
  CategoryModel(
    id: 3,
    name: 'Premium Vehicles',
    image: 'assets/images/cat_premium.png',
    categoryId: 'private_vehicle',
  ),
  CategoryModel(
    id: 4,
    name: 'Commercial Vehicles',
    image: 'assets/images/cat_truck.png',
    categoryId: 'commercial_vehicle',
  ),
  CategoryModel(
      id: 5,
      name: 'Real Estate',
      image: 'assets/images/cat_property.png',
      categoryId: 'property'),
  CategoryModel(
      id: 6,
      name: 'Showroom',
      image: 'assets/images/cat_showroom.png',
      categoryId: 'showroom'),
];
