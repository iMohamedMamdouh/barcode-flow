/// Physical label size for TSPL Bluetooth printing and PDF labels — must stay in sync.
///
/// Width drives horizontal centering (`labelWidthDots`). Must match the installed roll/tag.
class LabelDimensions {
  LabelDimensions._();

  static const double widthMm = 75;
  static const double heightMm = 130;
}
