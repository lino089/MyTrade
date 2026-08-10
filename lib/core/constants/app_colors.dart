import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF121824);
  static const Color surfaceLight = Color(0xFF1C2537);
  static const Color border = Color(0xFF1E293B);
  
  static const Color primary = Color(0xFF6366F1); // Indigo Accent
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color accent = Color(0xFF06B6D4); // Cyan Accent

  // Trade States
  static const Color profit = Color(0xFF10B981); // Emerald Green
  static const Color loss = Color(0xFFEF4444); // Crimson Red
  static const Color neutral = Color(0xFF64748B); // Muted Slate (Break Even)

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class AppConstants {
  static const double borderRadius = 12.0;
  static const double padding = 16.0;

  static const List<String> defaultPairs = [
    'EURUSD',
    'GBPUSD',
    'AUDUSD',
    'USDCAD',
    'USDJPY',
    'USDCHF',
    'NZDUSD',
    'XAUUSD',
    'BTCUSD',
    'ETHUSD',
    'EURJPY',
    'GBPJPY',
  ];

  static const List<String> defaultSetups = [
    'Breakout',
    'Support Resistance',
    'Liquidity Sweep',
    'Trend Following',
    'Pullback',
    'Scalping',
    'News',
    'Custom',
  ];

  static const List<String> defaultChecklist = [
    'Trend sesuai',
    'Support & Resistance valid',
    'RSI sesuai aturan',
    'Momentum Candle muncul',
    'Sesuai trading plan',
    'Entry pada jam trading favorit',
    'Risk Management sesuai aturan',
  ];
}
