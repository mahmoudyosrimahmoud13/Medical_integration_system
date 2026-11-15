import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../../doctor_portal/data/doctor_portal_repository_impl.dart';
import '../../doctor_portal/domain/doctor_portal.dart';
import '../../records/data/records_repository_impl.dart';
import '../domain/pharmacy.dart';

StockItem stockFromJson(Map<String, dynamic> j) => StockItem(
      drugId: str(j['drug_id']),
      drugName: str(j['drug_name']),
      quantity: integer(j['quantity']),
      price: number(j['price']),
    );

Pharmacy pharmacyFromJson(Map<String, dynamic> j) => Pharmacy(
      id: str(j['id']),
      name: str(j['name']),
      area: str(map(j['area'])['key']),
      governorate: str(map(j['governorate'])['key']),
      address: str(j['address_description']),
      phone: strOrNull(j['phone']),
      status: str(j['status'], 'accepted'),
      item: j['item'] == null ? null : stockFromJson(map(j['item'])),
      ownerId: str(j['owner_id']),
    );

class PharmacyRepositoryImpl implements PharmacyRepository {
  PharmacyRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<(ApplicationStatus, Pharmacy?)> mine() async {
    final j = map(await _api.get('/pharmacies/me'));
    return (statusFromJson(j), j['pharmacy'] == null ? null : pharmacyFromJson(map(j['pharmacy'])));
  }

  @override
  Future<void> apply(FacilityApplication a) => _api.post('/pharmacies/apply', body: a.toJson());

  @override
  Future<List<StockItem>> stock() async => list(await _api.get('/pharmacies/me/stock')).map(stockFromJson).toList();

  @override
  Future<StockItem> setStock(String drugId, int quantity, double price) async =>
      stockFromJson(map(await _api.put('/pharmacies/me/stock', body: {'drug_id': drugId, 'quantity': quantity, 'price': price})));

  @override
  Future<void> removeStock(String drugId) => _api.delete('/pharmacies/me/stock/$drugId');

  @override
  Future<SharedPrescriptions> prescriptionsByCode(String code) async {
    final j = map(await _api.get('/pharmacies/me/prescriptions', query: {'code': code.trim().toUpperCase()}));
    return SharedPrescriptions(
      patientName: str(j['patient_name']),
      prescriptions: list(j['prescriptions']).map(prescriptionFromJson).toList(),
    );
  }

  @override
  Future<List<Pharmacy>> find({String? drugId, String? governorateId, String? areaId}) async =>
      list(await _api.get('/pharmacies', query: {'drug_id': drugId, 'governorate_id': governorateId, 'area_id': areaId}))
          .map(pharmacyFromJson)
          .toList();
}
