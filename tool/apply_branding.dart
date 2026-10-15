// tool/apply_branding.dart
//
// Copies the masjid name and app ID from .env into the platform project
// files, which can't read .env themselves:
//   MASJID_NAME        Android label, iOS display name, web title, Windows title
//   MASJID_SHORT_NAME  iOS bundle name, web short name / home-screen title
//   APP_ID             Android applicationId, iOS/macOS bundle identifier
//
// Usage (from the project root, after editing .env):
//   dart run tool/apply_branding.dart
//
// The logo and icons are separate: replace assets/images/mosque.png, then
//   dart run tool/generate_icons.dart
//   dart run flutter_launcher_icons
import 'dart:io';

void main() {
  final env = _readEnv('.env');
  final name = _require(env, 'MASJID_NAME');
  final shortName =
      env['MASJID_SHORT_NAME']?.isNotEmpty == true
          ? env['MASJID_SHORT_NAME']!
          : name;
  final appId = _require(env, 'APP_ID');

  // Valid for both Android and iOS: letters/digits, at least two parts,
  // each starting with a letter (no underscores: iOS doesn't allow them).
  if (!RegExp(
    r'^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$',
  ).hasMatch(appId)) {
    _fail(
      'APP_ID "$appId" is not valid. Use something like org.yourmasjid.app '
      '(letters, digits and dots; each part starts with a letter).',
    );
  }
  if (shortName.length > 12) {
    stdout.writeln(
      'Note: MASJID_SHORT_NAME is longer than 12 characters and '
      'may be cut off under the app icon.',
    );
  }

  final description = 'Prayer times, iqamah and notices for $name.';
  final xmlName = _xml(name);

  _edit('android/app/build.gradle.kts', [
    (RegExp(r'applicationId = "[^"]*"'), 'applicationId = "$appId"'),
  ]);
  _edit('android/app/src/main/AndroidManifest.xml', [
    (RegExp(r'android:label="[^"]*"'), 'android:label="$xmlName"'),
  ]);
  _edit('ios/Runner/Info.plist', [
    (
      RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
      '\$1$xmlName\$2',
    ),
    (
      RegExp(r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)'),
      '\$1${_xml(shortName)}\$2',
    ),
  ]);
  _edit('ios/Runner.xcodeproj/project.pbxproj', [
    (
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*?(\.RunnerTests)?;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $appId\$1;',
    ),
  ]);
  _edit('macos/Runner/Configs/AppInfo.xcconfig', [
    (
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = .*'),
      'PRODUCT_BUNDLE_IDENTIFIER = $appId',
    ),
  ]);
  _edit('web/index.html', [
    (
      RegExp(r'<meta name="description" content="[^"]*">'),
      '<meta name="description" content="${_xml(description)}">',
    ),
    (
      RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
      '<meta name="apple-mobile-web-app-title" content="${_xml(shortName)}">',
    ),
    (RegExp(r'<title>[^<]*</title>'), '<title>$xmlName</title>'),
  ]);
  _edit('web/manifest.json', [
    (RegExp(r'"name": "[^"]*"'), '"name": "${_json(name)}"'),
    (RegExp(r'"short_name": "[^"]*"'), '"short_name": "${_json(shortName)}"'),
    (
      RegExp(r'"description": "[^"]*"'),
      '"description": "${_json(description)}"',
    ),
  ]);
  _edit('windows/runner/main.cpp', [
    (RegExp(r'window\.Create\(L"[^"]*"'), 'window.Create(L"${_json(name)}"'),
  ]);

  stdout.writeln('\nApplied "$name" ($shortName), app ID $appId.');
  stdout.writeln(
    'Logo and icons: replace assets/images/mosque.png, then run\n'
    '  dart run tool/generate_icons.dart\n'
    '  dart run flutter_launcher_icons',
  );
}

/// Minimal .env reader: KEY=value lines, # comments, optional quotes.
Map<String, String> _readEnv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    _fail('$path not found. Copy .env.example to .env and fill it in first.');
  }
  final values = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^\s*([A-Z0-9_]+)\s*=(.*)$').firstMatch(line);
    if (match == null) continue;
    var value = match.group(2)!.trim();
    if (value.length >= 2 &&
        (value.startsWith('"') && value.endsWith('"') ||
            value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    values[match.group(1)!] = value;
  }
  return values;
}

String _require(Map<String, String> env, String key) {
  final value = env[key] ?? '';
  if (value.isEmpty) _fail('$key is empty in .env');
  return value;
}

/// Applies each (pattern, replacement) to [path]; replacement may use $1, $2.
void _edit(String path, List<(RegExp, String)> edits) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip  $path (not found)');
    return;
  }
  final original = file.readAsStringSync();
  var text = original;
  for (final (pattern, replacement) in edits) {
    if (!pattern.hasMatch(text)) {
      stdout.writeln('warn  $path: "${pattern.pattern}" not found');
      continue;
    }
    text = text.replaceAllMapped(
      pattern,
      (m) => replacement.replaceAllMapped(
        RegExp(r'\$(\d)'),
        (g) => m.group(int.parse(g.group(1)!)) ?? '',
      ),
    );
  }
  if (text == original) {
    stdout.writeln('ok    $path (unchanged)');
  } else {
    file.writeAsStringSync(text);
    stdout.writeln('done  $path');
  }
}

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _json(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

Never _fail(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}
