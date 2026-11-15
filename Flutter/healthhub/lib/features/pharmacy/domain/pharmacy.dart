import 'package:equatable/equatable.dart';

import '../../doctor_portal/domain/doctor_portal.dart';
import '../../records/domain/records.dart';

class StockItem extends Equatable {
  const StockItem({required this.drugId, required this.drugName, required this.quantity, required this.price});

  final String drugId;
  final String drugName;
  final int quantity;
  final double price;

  bool get lowStock => quantity > 0 && quantity < 10;
  bool get outOfStock => quantity == 0;

  @override
  List<Object?> get props => [drugId, quantity, price];
}

class Pharmacy extends Equatable {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.area,
    required this.governorate,
    this.address = '',
    this.phone,
    this.status = 'accepted',
    this.item,
    this.ownerId = '',
  });

  final String ownerId; // the pharmacy's account, used to start a chat
  final String id;
  final String name;
  final String area;
  final String governorate;
  final String address;
  final String? phone;
  final String status;
  final StockItem? item; // the searched drug, when searching

  @override
  List<Object?> get props => [id, status, item];
}

class FacilityApplication {
  const FacilityApplication({required this.name, required this.areaId, this.address = '', this.phone, this.description = ''});

  final String name;
  final String areaId;
  final String address;
  final String? phone;
  final String description;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'area_id': areaId,
        'address_description': address.trim(),
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'description': description.trim(),
      };
}

class SharedPrescriptions extends Equatable {
  const SharedPrescriptions({required this.patientName, required this.prescriptions});

  final String patientName;
  final List<Prescription> prescriptions;

  @override
  List<Object?> get props => [patientName, prescriptions];
}

abstract class PharmacyRepository {
  Future<(ApplicationStatus, Pharmacy?)> mine();
  Future<void> apply(FacilityApplication application);
  Future<List<StockItem>> stock();
  Future<StockItem> setStock(String drugId, int quantity, double price);
  Future<void> removeStock(String drugId);
  Future<SharedPrescriptions> prescriptionsByCode(String code);
  Future<List<Pharmacy>> find({String? drugId, String? governorateId, String? areaId});
}
