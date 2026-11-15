import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../domain/catalog.dart';

Governorate governorateFromJson(Map<String, dynamic> j) =>
    Governorate(id: str(j['id']), name: str(j['key']), nameAr: strOrNull(j['name_ar']));

Area areaFromJson(Map<String, dynamic> j) =>
    Area(id: str(j['id']), name: str(j['key']), governorateId: str(j['governorate_id']), nameAr: strOrNull(j['name_ar']));

Specialty specialtyFromJson(Map<String, dynamic> j) => Specialty(id: str(j['id']), name: str(j['name']));

Drug drugFromJson(Map<String, dynamic> j) => Drug(id: str(j['id']), name: str(j['name']));

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._api);

  final ApiClient _api;

  // Reference data rarely changes, so it's cached for the app session.
  List<Governorate>? _governorates;
  List<Specialty>? _specialties;
  final Map<String, List<Area>> _areas = {};

  @override
  Future<List<Governorate>> governorates() async =>
      _governorates ??= list(await _api.get('/governorates')).map(governorateFromJson).toList();

  @override
  Future<List<Area>> areas(String governorateId) async =>
      _areas[governorateId] ??= list(await _api.get('/governorates/$governorateId/areas')).map(areaFromJson).toList();

  @override
  Future<List<Specialty>> specialties() async =>
      _specialties ??= list(await _api.get('/specialties')).map(specialtyFromJson).toList();

  @override
  Future<List<Drug>> searchDrugs(String query) async {
    if (query.trim().length < 2) return const [];
    return list(await _api.get('/drugs', query: {'q': query.trim()})).map(drugFromJson).toList();
  }
}
