import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthhub/constants/colors.dart';

ThemeData mainTheme = ThemeData().copyWith(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0000FF))
      .copyWith(primary: Color.fromARGB(255, 82, 98, 245)),
  textTheme: GoogleFonts.exoTextTheme(),
);
ThemeData darkTheme = ThemeData.dark().copyWith(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
          seedColor: LightColors.blue, brightness: Brightness.dark)
      .copyWith(primary: LightColors.blue),
  textTheme: GoogleFonts.exoTextTheme(),
);
