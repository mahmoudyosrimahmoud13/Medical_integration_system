import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/Area/area_cubit.dart';
import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/cubit/authentication/authentication_cubit.dart';
import 'package:healthhub/cubit/booking/booking_cubit.dart';
import 'package:healthhub/cubit/get_appointments/get_appointments_cubit.dart';
import 'package:healthhub/cubit/get_doctor/get_doctor_cubit.dart';
import 'package:healthhub/cubit/get_user_data/get_user_data_cubit.dart';
import 'package:healthhub/cubit/governrate/governrates_cubit.dart';
import 'package:healthhub/cubit/register/register_cubit.dart';
import 'package:healthhub/cubit/search/search_cubit.dart';
import 'package:healthhub/cubit/specialities/specialities_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/login.dart';
import 'package:healthhub/constants/themes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AdressCubit(),
        ),
        BlocProvider(
          create: (context) => RegisterCubit(),
        ),
        BlocProvider(
          create: (context) => AuthenticationCubit(),
        ),
        BlocProvider(
          create: (context) => SpecialitiesCubit(),
        ),
        BlocProvider(
          create: (context) => AreaCubit(),
        ),
        BlocProvider(
          create: (context) => SearchCubit(),
        ),
        BlocProvider(
          create: (context) => GovernratesCubit(),
        ),
        BlocProvider(
          create: (context) => GetUserDataCubit(),
        ),
        BlocProvider(
          create: (context) => GetDoctorCubit(),
        ),
        BlocProvider(
          create: (context) => BookingCubit(),
        ),
        BlocProvider(
          create: (context) => GetAppointmentsCubit(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: mainTheme,
        // darkTheme: darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
