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

/// Reference data used by forms and filters.
abstract class CatalogRepository {
  Future<List<Governorate>> governorates();
  Future<List<Area>> areas(String governorateId);
  Future<List<Specialty>> specialties();
  Future<List<Drug>> searchDrugs(String query);
}
