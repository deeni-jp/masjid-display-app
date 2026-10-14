// test/helpers/display_fonts.dart
//
// Tests normally draw every glyph as a wide square, which makes layout
// overflow checks meaningless. This loads the display's real fonts (Manrope,
// Noto Sans Arabic; test/fixtures/fonts, SIL Open Font License) under the
// family names google_fonts asks for, e.g. 'Manrope_600'.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const _dir = 'test/fixtures/fonts';

Future<void> loadDisplayFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  ByteData font(String file) =>
      ByteData.sublistView(File('$_dir/$file').readAsBytesSync());

  // google_fonts' family suffix for each weight -> nearest bundled file
  const manrope = {
    '100': 'Manrope-500.ttf',
    '200': 'Manrope-500.ttf',
    '300': 'Manrope-500.ttf',
    'regular': 'Manrope-500.ttf',
    '500': 'Manrope-500.ttf',
    '600': 'Manrope-600.ttf',
    '700': 'Manrope-700.ttf',
    '800': 'Manrope-800.ttf',
    '900': 'Manrope-800.ttf',
  };
  for (final MapEntry(key: weight, value: file) in manrope.entries) {
    await (FontLoader('Manrope_$weight')
      ..addFont(Future.value(font(file)))).load();
  }
  for (final weight in manrope.keys) {
    await (FontLoader('NotoSansArabic_$weight')
      ..addFont(Future.value(font('NotoSansArabic-500.ttf')))).load();
  }
}
