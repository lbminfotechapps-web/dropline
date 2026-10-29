import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

static const Color background = Color(0xFF09283A);
  static const Color surface = Color(0xFF0D3046);
  static const Color cardBackground = Color(0xFF0C2D43);
  static const Color inputBackground = Color(0xFF0B2C42);
  static const Color border = Color(0xFF28516B);

  static const Color primary = Color(0xFFB5FF76);
  static const Color primaryText = Color(0xFF09283A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF93B5CC);
  static const Color hintText = Color(0xFF779CB5);
  static const Color iconColor = Color(0xFF86C9F2);

  static const Color error = Color(0xFFFF6B6B);
  static const Color transparent = Colors.transparent;

  static const Color gradientTop = Color(0xFF123D5B);
  static const Color gradientBottom = Color(0xFF09283A);


  static const Color primaryLight = Color(0xFF8C9AAA);

  static const Color primaryDark = Color(0xFF4D5C70);

  // ==========================================
  // BACKGROUND COLORS
  // ==========================================

  static const Color backgroundTop = Color(0xFF8C98A6);

  static const Color backgroundMiddle = Color(0xFF6D7C90);

  static const Color backgroundBottom = Color(0xFF5D687A);

  static const Color scaffoldBackground = Color(0xFF6D7C90);

  // ==========================================
  // GRADIENTS
  // ==========================================

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundMiddle, backgroundBottom],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF526B8B), Color(0xFF465568)],
  );

  // ==========================================
  // CARD / CONTAINER COLORS
  // ==========================================



  static const Color cardBackgroundLight = Color(0xFF718094);

  static const Color cardBorder = Color(0xFF8592A2);


  // ==========================================
  // TEXT COLORS
  // ==========================================


  static const Color textMuted = Color(0xFFB6C0CE);

  static const Color textDark = Color(0xFF344256);

  // ==========================================
  // BUTTON COLORS
  // ==========================================

  static const Color buttonPrimary = Color(0xFF4D6381);

  static const Color buttonSecondary = Color(0xFF64748B);

  static const Color buttonText = Color(0xFFFFFFFF);

  static const Color buttonBorder = Color(0xFF9FACBC);

  // ==========================================
  // ICON COLORS
  // ==========================================

  static const Color iconPrimary = Color(0xFFFFFFFF);

  static const Color iconSecondary = Color(0xFFD2D8E4);

  static const Color iconMuted = Color(0xFFAAB7C6);

  // ==========================================
  // INPUT / TEXTFIELD COLORS
  // ==========================================

  static const Color inputBorder = Color(0xFF8998A9);

  static const Color inputFocusedBorder = Color(0xFFE0E7F0);


  // ==========================================
  // STATUS COLORS
  // ==========================================

  static const Color success = Color(0xFF48B28A);



  static const Color warning = Color(0xFFFFC46B);

  static const Color info = Color(0xFF81B5E8);

  // Event composer palette.
  static const Color eventBackgroundTop = Color(0xFF909EAD);
  static const Color eventBackgroundBottom = Color(0xFF4C586A);
  static const Color eventNoteSurface = Color(0xFF637183);
  static const Color eventTileLight = Color(0xFFF0F3FB);
  static const Color eventTilePeach = Color(0xFFF9E1D3);
  static const Color eventTimeSelected = Color(0xFF51CB71);
  static const Color eventToolBlue = Color(0xFF9ECFFF);
  static const Color eventToolMint = Color(0xFFA3E6C4);
  static const Color eventToolPurple = Color(0xFFC1A4F1);
  static const Color eventToolOrange = Color(0xFFF9BF9D);
  static const Color eventToolCyan = Color(0xFF9EE4E9);

  // Login accents used over the splash artwork.
  static const Color loginNavigationBar = Color(0xFF4B5869);
  static const Color loginHint = Color(0xFFCDD2D8);
  static const Color loginInputBorder = Color(0xFF8A94A2);
  static const Color loginAgreement = Color(0xFF82FF27);
  static const Color loginAgreementIcon = Color(0xFF233D22);
  static const Color loginLink = Color(0xFF49C4E5);
  static const Color loginSliderKnob = Color(0xFF5B6B7C);
  static const Color loginButtonGlow = Color(0xFFDFD6A3);
  static const Color loginKnobGlow = Color(0xFFB9DEEE);
  static const LinearGradient loginButtonGradient = LinearGradient(
    colors: [Color(0xFF496A91), Color(0xFF4D5C6C)],
  );

  // ==========================================
  // COMMON COLORS
  // ==========================================

  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF000000);



  static const Color divider = Color(0xFF8290A1);

  static const Color shadow = Color(0x33000000);


    static const Color certificateBackgroundTop = Color(0xFF8192A8);
  static const Color certificateBackgroundBottom = Color(0xFF53657B);
  static const Color certificateSurface = Color(0xFF586B82);
  static const Color certificateBorder = Color(0xFF9AABBF);
  static const Color certificatePrimary = Color(0xFF65FF45);
  static const Color certificateTextPrimary = Color(0xFFF7F9FF);
  static const Color certificateTextSecondary = Color(0xFFD3DBE8);
  static const Color certificateIcon = Color(0xFFDCE6F1);
  static const Color certificateButtonText = Color(0xFF0B2535);

  static const Color sheetBackground = Color(0xFF0D3046);
static const Color sheetHandle = Color(0xFF93B5CC);
static const Color selectedDate = Color(0xFFB5FF76);
static const Color disabledButton = Color(0xFF355B73);
static const Color disabledText = Color(0xFF93B5CC);
}
