double responsiveSheetFraction({
  required String pickup,
  required String dropoff,
  double base = 0.45,
  double maxFraction = 0.78,
  double perLine = 0.05,
  int charsPerLine = 30,
}) {
  int lines(String s) => (s.trim().length / charsPerLine).ceil().clamp(1, 5);
  final extraLines = (lines(pickup) - 1) + (lines(dropoff) - 1);
  return (base + extraLines * perLine).clamp(base, maxFraction);
}
