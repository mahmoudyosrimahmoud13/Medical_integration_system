import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/network/api_exception.dart';
import 'package:healthhub/features/doctors/domain/doctors.dart';
import 'package:healthhub/features/doctors/presentation/doctor_search_cubit.dart';

DoctorSummary doc(String id) => DoctorSummary(id: id, name: 'Dr $id', specialty: 'Cardiology', area: 'Maadi', governorate: 'Cairo');

class FakeDoctorRepository implements DoctorRepository {
  FakeDoctorRepository({this.pages = const {}, this.fail = false});

  final Map<int, DoctorPage> pages;
  final bool fail;
  final calls = <(DoctorFilter, int)>[];

  @override
  Future<DoctorPage> search(DoctorFilter filter, {int page = 0}) async {
    calls.add((filter, page));
    if (fail) throw const ApiException('Server down', statusCode: 500);
    return pages[page] ?? const DoctorPage(items: [], total: 0, page: 0);
  }

  @override
  Future<Doctor> details(String id) => throw UnimplementedError();
  @override
  Future<List<Review>> reviews(String doctorId) => throw UnimplementedError();
  @override
  Future<void> addReview(String doctorId, double rate, String message) => throw UnimplementedError();
}

void main() {
  final page0 = DoctorPage(items: [doc('a'), doc('b')], total: 3, page: 0);
  final page1 = DoctorPage(items: [doc('c')], total: 3, page: 1);

  blocTest<DoctorSearchCubit, DoctorSearchState>(
    'search loads the first page',
    build: () => DoctorSearchCubit(FakeDoctorRepository(pages: {0: page0})),
    act: (c) => c.search(),
    expect: () => [
      const DoctorSearchState(loading: true),
      DoctorSearchState(items: page0.items, total: 3),
    ],
  );

  blocTest<DoctorSearchCubit, DoctorSearchState>(
    'loadMore appends the next page and stops when everything is loaded',
    build: () => DoctorSearchCubit(FakeDoctorRepository(pages: {0: page0, 1: page1})),
    act: (c) async {
      await c.search();
      await c.loadMore();
      await c.loadMore(); // nothing left: no request, no state change
    },
    verify: (c) {
      expect(c.state.items.map((d) => d.id), ['a', 'b', 'c']);
      expect(c.state.hasMore, isFalse);
      expect(c.state.page, 1);
    },
  );

  blocTest<DoctorSearchCubit, DoctorSearchState>(
    'errors keep the old items and expose a message',
    build: () => DoctorSearchCubit(FakeDoctorRepository(fail: true)),
    act: (c) => c.search(),
    expect: () => [
      const DoctorSearchState(loading: true),
      const DoctorSearchState(error: 'Server down'),
    ],
  );

  test('setName waits before searching, and only the last name is used', () async {
    final repo = FakeDoctorRepository(pages: {0: page0});
    final cubit = DoctorSearchCubit(repo, debounce: const Duration(milliseconds: 20));
    cubit.setName('A');
    cubit.setName('Ah');
    cubit.setName('Ahm');
    expect(repo.calls, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.calls.length, 1);
    expect(repo.calls.single.$1.name, 'Ahm');
    await cubit.close();
  });

  test('changing a filter searches right away with the new filter', () async {
    final repo = FakeDoctorRepository(pages: {0: page0});
    final cubit = DoctorSearchCubit(repo);
    cubit.setSpecialty('spec-1');
    cubit.setLocation('gov-1', null);
    cubit.setSort(DoctorSort.rate);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.length, 3);
    final last = repo.calls.last.$1;
    expect(last.specialtyId, 'spec-1');
    expect(last.governorateId, 'gov-1');
    expect(last.sort, DoctorSort.rate);
    await cubit.close();
  });
}
