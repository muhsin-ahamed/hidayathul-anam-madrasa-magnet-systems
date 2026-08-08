import 'package:flutter/material.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 720;
  static const double desktop = 1100;
}

class Responsive {
  const Responsive._();

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
  }

  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktop) return 28;
    if (width >= AppBreakpoints.tablet) return 22;
    return 16;
  }

  static int columns(BuildContext context, {int desktop = 4, int tablet = 2}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return 1;
  }
}
