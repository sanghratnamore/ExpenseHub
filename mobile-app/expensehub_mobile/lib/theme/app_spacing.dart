import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 32;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    20,
    0,
    20,
    32,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(18);

  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 28;

  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius input = BorderRadius.circular(md);
  static final BorderRadius chip = BorderRadius.circular(30);
}