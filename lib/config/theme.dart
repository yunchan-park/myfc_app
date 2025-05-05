import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CupertinoColors.systemBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: CupertinoColors.systemBackground,
        foregroundColor: CupertinoColors.label,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: CupertinoColors.label,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: CupertinoColors.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CupertinoColors.systemGrey6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CupertinoColors.activeBlue,
          foregroundColor: CupertinoColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CupertinoColors.activeBlue,
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ),
    );
  }
  
  static CupertinoThemeData getCupertinoTheme(Brightness brightness) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: CupertinoColors.activeBlue,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? CupertinoColors.systemBackground
          : CupertinoColors.systemBackground.darkColor,
      barBackgroundColor: brightness == Brightness.light
          ? CupertinoColors.systemBackground
          : CupertinoColors.systemBackground.darkColor,
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.light
              ? CupertinoColors.label
              : CupertinoColors.label.darkColor,
        ),
      ),
    );
  }
} 