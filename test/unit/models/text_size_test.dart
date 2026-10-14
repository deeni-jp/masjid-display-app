import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/models/text_size.dart';

void main() {
  group('TextSize', () {
    test('factors grow from small to extra large', () {
      final factors = TextSize.values.map((s) => s.factor).toList();
      expect(factors, [0.9, 1.0, 1.2, 1.4]);
    });

    test('fromName parses stored names and rejects others', () {
      for (final value in TextSize.values) {
        expect(TextSize.fromName(value.name), value);
      }
      expect(TextSize.fromName('huge'), isNull);
      expect(TextSize.fromName(null), isNull);
    });
  });

  group('textSizeFromSetup', () {
    test('no ?textSize= -> nothing to apply', () {
      expect(textSizeFromSetup(requested: null, lastApplied: null), isNull);
    });

    test('first setup value is applied', () {
      expect(
        textSizeFromSetup(requested: 'large', lastApplied: null),
        TextSize.large,
      );
    });

    test('same setup value again -> keep the in-app choice', () {
      expect(
        textSizeFromSetup(requested: 'large', lastApplied: 'large'),
        isNull,
      );
    });

    test('setup re-run with a new value -> applied', () {
      expect(
        textSizeFromSetup(requested: 'extraLarge', lastApplied: 'large'),
        TextSize.extraLarge,
      );
    });

    test('unknown value -> ignored', () {
      expect(textSizeFromSetup(requested: 'huge', lastApplied: null), isNull);
    });
  });
}
