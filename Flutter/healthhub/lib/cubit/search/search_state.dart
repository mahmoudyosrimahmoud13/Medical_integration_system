part of 'search_cubit.dart';

@immutable
sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSuccess extends SearchState {
  final Map<String, dynamic> data;
  List cards = [
    SizedBox(
        height: 350,
        width: double.infinity,
        child:
            SvgPicture(SvgAssetLoader('assets/placeholders/faild_search.svg'))),
    Text(
      'Sorry,We couldn\'t find any result.',
      style: TextStyle(color: Colors.blue, fontSize: 25),
    )
  ];

  SearchSuccess({required this.data}) {
    print('ssssssssssssssssssssssssss');

    if (data['doctors'].length != 0) {
      cards = data['doctors'].map(
        (e) {
          return DoctorCard(
              id: e['id'],
              area: e['area'],
              image: e['drImg'],
              name: e['name'],
              phone: e['phone'],
              adress: e['addressDescrption'],
              rate: e['rate'] + 0.0);
        },
      ).toList();
    }
  }
}

final class SearchError extends SearchState {
  final String message;

  SearchError({required this.message});
}
