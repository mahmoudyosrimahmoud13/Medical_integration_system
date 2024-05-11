import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthhub/constants/colors.dart';

ThemeData mainTheme = ThemeData().copyWith(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
      seedColor: LightColors.blue, brightness: Brightness.light),
  textTheme: GoogleFonts.exoTextTheme(),
);
ThemeData darkTheme = ThemeData.dark().copyWith(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
      seedColor: LightColors.blue, brightness: Brightness.dark),
  textTheme: GoogleFonts.exoTextTheme(),
);
