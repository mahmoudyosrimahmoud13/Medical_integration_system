import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/cubit/authentication/authentication_cubit.dart';
import 'package:healthhub/cubit/register/register_cubit.dart';
import 'package:healthhub/helpers/helper_methods.dart';
import 'package:healthhub/screens/authentication/login.dart';
import 'package:healthhub/constants/themes.dart';
import 'package:healthhub/screens/home/home_screen.dart';
import 'package:healthhub/screens/prescription_details.dart';

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
        )
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: mainTheme,
        // darkTheme: darkTheme,
        home: const PrescriptionDetails(),
      ),
    );
  }
}
