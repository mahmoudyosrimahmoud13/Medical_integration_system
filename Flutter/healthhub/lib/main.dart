import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthhub/cubit/adress/adress_cubit.dart';
import 'package:healthhub/screens/authentication/sign_up.dart';
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: mainTheme,
        // darkTheme: darkTheme,
        home: const SignUpScreen(),
      ),
    );
  }
}
