class ResponsiveHelper {
  ResponsiveHelper._();

  static const double _tabletBreakpoint = 600;
  static const double _largeTabletBreakpoint = 900;
  static const double maxContentWidth = 700;

  static bool isTablet(double width) => width >= _tabletBreakpoint;
  static bool isLargeTablet(double width) => width >= _largeTabletBreakpoint;

  static int gridColumns(double width) {
    if (width >= _largeTabletBreakpoint) return 3;
    if (width >= _tabletBreakpoint) return 2;
    return 1;
  }

  static double imageSize(double width) {
    if (width >= _largeTabletBreakpoint) return 72;
    if (width >= _tabletBreakpoint) return 64;
    return 56;
  }

  static double cardPadding(double width) {
    if (width >= _tabletBreakpoint) return 16;
    return 12;
  }

  static double fontSize(double width, {required double base}) {
    if (width >= _largeTabletBreakpoint) return base + 2;
    if (width >= _tabletBreakpoint) return base + 1;
    return base;
  }
}
