import 'package:flutter/material.dart';

/// The four things a seller can post. [apiValue] is the backend `category`,
/// [slug] is the route segment (`/sell/car`).
enum SellCategory {
  car(
    apiValue: 'private_vehicle',
    slug: 'car',
    label: 'Car',
    subtitle: 'Hatchback, sedan, SUV',
    noun: 'car',
    icon: Icons.directions_car_filled_outlined,
  ),
  bike(
    apiValue: 'two_wheeler',
    slug: 'bike',
    label: 'Bike or scooter',
    subtitle: 'Motorcycles, scooters',
    noun: 'bike',
    icon: Icons.two_wheeler_outlined,
  ),
  commercial(
    apiValue: 'commercial_vehicle',
    slug: 'commercial',
    label: 'Commercial',
    subtitle: 'Autos, taxis, trucks, buses',
    noun: 'vehicle',
    icon: Icons.local_shipping_outlined,
  ),
  property(
    apiValue: 'property',
    slug: 'property',
    label: 'Property',
    subtitle: 'Sell or rent · land in cents',
    noun: 'property',
    icon: Icons.home_work_outlined,
  );

  const SellCategory({
    required this.apiValue,
    required this.slug,
    required this.label,
    required this.subtitle,
    required this.noun,
    required this.icon,
  });

  final String apiValue;
  final String slug;
  final String label;
  final String subtitle;

  /// Used in copy: "About the car".
  final String noun;
  final IconData icon;

  bool get isVehicle => this != SellCategory.property;

  /// `vehicleType` sent inside `vehicle`/`commercial`.
  String get vehicleType =>
      this == SellCategory.bike ? 'two_wheeler' : 'four_wheeler';

  /// Default when the config call has not answered yet.
  String get defaultManufacturerCategory {
    switch (this) {
      case SellCategory.car:
        return 'passenger_car';
      case SellCategory.bike:
        return 'two_wheeler';
      case SellCategory.commercial:
        return 'commercial_vehicle';
      case SellCategory.property:
        return '';
    }
  }

  static SellCategory? fromSlug(String? value) {
    if (value == null) return null;
    for (final c in SellCategory.values) {
      if (c.slug == value || c.apiValue == value) return c;
    }
    return null;
  }
}

/// Steps of the flow, in order.
enum SellStep {
  photos('Photos'),
  details('About'),
  pricePlace('Price & place'),
  review('Review');

  const SellStep(this.shortLabel);
  final String shortLabel;

  String titleFor(SellCategory c) {
    switch (this) {
      case SellStep.photos:
        return 'Photos';
      case SellStep.details:
        return 'About the ${c.noun}';
      case SellStep.pricePlace:
        return 'Price & place';
      case SellStep.review:
        return 'Review';
    }
  }
}
