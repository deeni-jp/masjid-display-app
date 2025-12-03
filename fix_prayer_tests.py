import re

# Read the file
with open('test/unit/models/prayer_time_test.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to match PrayerTime.fromMaps with positional arguments
# Matches: PrayerTime.fromMaps(\n          'Name',\n          {...},\n          {...},\n        )
pattern = r"PrayerTime\.fromMaps\(\s*'([^']+)',\s*(\{[^}]+\}),\s*(\{[^}]+\}),\s*\)"

def replace_func(match):
    name = match.group(1)
    timings = match.group(2)
    iqama_map = match.group(3)
    return f"PrayerTime.fromMaps(\n          name: '{name}',\n          timings: {timings},\n          iqamaMap: {iqama_map},\n        )"

# Replace all occurrences
content = re.sub(pattern, replace_func, content)

# Write back
with open('test/unit/models/prayer_time_test.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed all PrayerTime.fromMaps calls")
