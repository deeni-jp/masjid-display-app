// lib/widgets/masjid_logo.dart
import 'package:flutter/material.dart';

/// The masjid's emblem (assets/images/masjid_logo.png, generated from
/// mosque.png by tool/generate_icons.dart).
class MasjidLogo extends StatelessWidget {
  /// Height of the logo; the width follows its proportions.
  final double size;

  const MasjidLogo({super.key, this.size = 64});

  static const String asset = 'assets/images/masjid_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Darut Tauhid Masjid logo',
      // Fall back to a generic icon if the asset is missing.
      errorBuilder:
          (context, error, stack) => Icon(Icons.mosque, size: size * 0.8),
    );
  }
}
