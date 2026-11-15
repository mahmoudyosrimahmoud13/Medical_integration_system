import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhub/core/di.dart';
import 'package:healthhub/features/appointments/presentation/booking_sheet.dart';
import 'package:healthhub/features/auth/presentation/session_cubit.dart';
import 'package:healthhub/features/doctors/presentation/doctor_details_page.dart';
import 'package:healthhub/features/doctors/presentation/find_doctors_page.dart';

import '../fakes.dart';

void main() {
  Widget host(Deps deps, Widget child) => RepositoryProvider<Deps>.value(
        value: deps,
        child: BlocProvider(create: (_) => SessionCubit(deps.auth, deps.tokens), child: MaterialApp(home: child)),
      );

  testWidgets('search lists doctors and opens the details page', (tester) async {
    final deps = fakeDeps();
    await tester.pumpWidget(host(deps, const FindDoctorsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Dr. Ahmed Hassan'), findsOneWidget);
    expect(find.text('1 doctor found'), findsOneWidget);

    await tester.tap(find.text('Dr. Ahmed Hassan'));
    await tester.pumpAndSettle();
    expect(find.byType(DoctorDetailsPage), findsOneWidget);
    expect(find.textContaining('Cairo University'), findsOneWidget);
    expect(find.text('Book an appointment'), findsOneWidget);
  });

  testWidgets('booking picks a day and a slot and saves it', (tester) async {
    final deps = fakeDeps();
    await tester.pumpWidget(host(deps, DoctorDetailsPage(doctorId: 'd1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book an appointment'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingSheet), findsOneWidget);
    expect(find.text('Pick a time'), findsOneWidget);

    await tester.tap(find.text('09:00 AM').first);
    await tester.pumpAndSettle();
    expect(find.text('Book 09:00 AM'), findsOneWidget);

    await tester.tap(find.text('Book 09:00 AM'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You're booked!"), findsOneWidget);
    expect((deps.appointments as FakeAppointments).booked.single.from, '09:00 AM');
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
