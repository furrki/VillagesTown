import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LayoutConstants {
  static bool isPhone(BuildContext context) => MediaQuery.of(context).size.width < 600;

  static bool isPad(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;

  static double villageNodeSize(BuildContext context) => isPhone(context) ? 44 : 60;

  static double panelWidth(BuildContext context) => isPhone(context) ? double.infinity : 320;

  static EdgeInsets padding(BuildContext context) => EdgeInsets.all(isPhone(context) ? 12 : 20);

  static double fontSize(BuildContext context, double base) => isPhone(context) ? base * 0.85 : base;

  static void impactFeedback({HapticStyle style = HapticStyle.light}) {
    if (Platform.isIOS) {
      switch (style) {
        case HapticStyle.light:
          HapticFeedback.lightImpact();
        case HapticStyle.medium:
          HapticFeedback.mediumImpact();
        case HapticStyle.heavy:
          HapticFeedback.heavyImpact();
      }
    }
  }

  static void selectionFeedback() {
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    }
  }
}

enum HapticStyle { light, medium, heavy }
