import 'package:flutter/material.dart';

class AppColors {
  static const Color forestGreen = Color(0xFF1B5E3C);
  static const Color ecoGreen = Color(0xFF2E8B57);
  static const Color mintGreen = Color(0xFFDFF3E6);
  static const Color offWhite = Color(0xFFF7FAF8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkCharcoal = Color(0xFF26332D);
  static const Color slateGray = Color(0xFF66736C);
  static const Color rewardGold = Color(0xFFF4C95D);
  static const Color errorRed = Color(0xFFD9534F);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forestGreen,
        secondary: AppColors.ecoGreen,
        surface: AppColors.white,
        background: AppColors.offWhite,
        error: AppColors.errorRed,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkCharcoal,
        onBackground: AppColors.darkCharcoal,
        onError: AppColors.white,
        surfaceTint: Colors.transparent, // Removes tint on Material 3 cards
      ),
      scaffoldBackgroundColor: AppColors.offWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkCharcoal,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkCharcoal),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.forestGreen,
        unselectedItemColor: AppColors.slateGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.darkCharcoal),
        bodyMedium: TextStyle(color: AppColors.darkCharcoal),
        bodySmall: TextStyle(color: AppColors.slateGray),
        labelLarge: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColors.slateGray),
        labelSmall: TextStyle(color: AppColors.slateGray),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.slateGray.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mintGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mintGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.forestGreen),
        ),
        hintStyle: const TextStyle(color: AppColors.slateGray),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
