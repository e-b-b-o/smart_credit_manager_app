import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient Start: #4F46E5
  static const Color primary = Color(0xFF4F46E5);
  // Primary Gradient End: #9333EA
  static const Color primaryDark = Color(0xFF9333EA);
  
  // Secondary/Success: #10B981
  static const Color success = Color(0xFF10B981);
  // Secondary (legacy fallback for compatibility)
  static const Color secondary = Color(0xFF10B981);

  // Background: #F8FAFC
  static const Color background = Color(0xFFF8FAFC);
  
  // Cards: #FFFFFF
  static const Color card = Color(0xFFFFFFFF);

  // Text Primary: #111827
  static const Color text = Color(0xFF111827);
  // Text Secondary: #6B7280
  static const Color textLight = Color(0xFF6B7280);

  // Accents
  // Warning (Pending/Partial): #F59E0B
  static const Color warning = Color(0xFFF59E0B);
  // Error/Danger (Overdue/Debt): #EF4444
  static const Color error = Color(0xFFEF4444);
  // Info: #3B82F6
  static const Color info = Color(0xFF3B82F6);

  static const Color white = Colors.white;

  // Primary Gradient for cards, headers, buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF9333EA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
