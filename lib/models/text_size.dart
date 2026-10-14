// lib/models/text_size.dart

/// The user's text size choice, applied on top of the device's own font
/// size setting (whole app, including the masjid display).
enum TextSize {
  small(0.9, 'Small'),
  normal(1.0, 'Normal'),
  large(1.2, 'Large'),
  extraLarge(1.4, 'Extra large');

  final double factor;
  final String label;

  const TextSize(this.factor, this.label);

  /// Parses a stored [name] (also the `?textSize=` value from the display
  /// setup); null if it isn't one of the values.
  static TextSize? fromName(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// The text size the display setup asks for (`?textSize=` in the URL), if it
/// should be applied: only when it's valid and differs from the last setup
/// value already applied ([lastApplied]). So re-running setup with a new
/// choice wins, but a size picked later in the app isn't reset on restart.
TextSize? textSizeFromSetup({
  required String? requested,
  required String? lastApplied,
}) {
  final size = TextSize.fromName(requested);
  if (size == null || requested == lastApplied) return null;
  return size;
}
