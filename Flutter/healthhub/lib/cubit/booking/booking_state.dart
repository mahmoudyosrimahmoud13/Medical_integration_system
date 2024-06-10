part of 'booking_cubit.dart';

@immutable
sealed class BookingState {}

final class BookingInitial extends BookingState {}

final class BookingLoading extends BookingState {}

final class BookingSucces extends BookingState {
  final String response;

  BookingSucces({required this.response}) {
    if (response == 'Save.') {
      showMessage(message: 'Booked successfully.');
      Navigator.of(navigatorKey.currentState!.context).pop();
    } else {
      showMessage(message: response, type: MessageType.faild);
    }
  }
}

final class BookingError extends BookingState {
  final String message;

  BookingError({required this.message}) {
    showMessage(message: message, type: MessageType.faild);
  }
}
