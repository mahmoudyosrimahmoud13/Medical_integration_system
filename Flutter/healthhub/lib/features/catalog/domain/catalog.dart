import 'package:equatable/equatable.dart';

class Governorate extends Equatable {
  const Governorate({required this.id, required this.name, this.nameAr});

  final String id;
  final String name;
  final String? nameAr;

  @override
  List<Object?> get props => [id];
}

class Area extends Equatable {
  const Area({required this.id, required this.name, required this.governorateId, this.nameAr});

  final String id;
  final String name;
  final String governorateId;
  final String? nameAr;

  @override
  List<Object?> get props => [id];
}

class Specialty extends Equatable {
  const Specialty({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id];
}

class Drug extends Equatable {
  const Drug({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id];
}

/// A branded medicine on the Egyptian market (Panadol, Concor, ...), linked to its active ingredient.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.brand,
    required this.drugId,
    required this.activeIngredient,
    this.strength = '',
    this.form = '',
    this.pack = '',
    this.manufacturer = '',
    this.category = '',
    this.price = 0,
    this.prescriptionOnly = true,
  });

  final int id;
  final String brand;
  final String drugId;
  final String activeIngredient;
  final String strength;
  final String form;
  final String pack;
  final String manufacturer;
  final String category;
  final double price;
  final bool prescriptionOnly;

  String get title => [brand, strength].where((s) => s.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id];
}

/// Reference data used by forms and filters.
abstract class CatalogRepository {
  Future<List<Governorate>> governorates();
  Future<List<Area>> areas(String governorateId);
  Future<List<Specialty>> specialties();
  Future<List<Drug>> searchDrugs(String query);
  Future<List<Product>> searchProducts(String query);
}
