// lib/screens/prayers_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_time.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/prayer_card.dart';

class PrayersTab extends StatelessWidget {
  final PrayerSchedule? prayerSchedule;
  final PrayerTime? nextPrayer;
  final bool adminMode;
  final Future<void> Function() onRefresh;
  final void Function(String prayerName, String newIqama) onIqamaUpdated;

  const PrayersTab({
    super.key,
    required this.prayerSchedule,
    required this.nextPrayer,
    required this.adminMode,
    required this.onRefresh,
    required this.onIqamaUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Sunrise has no iqamah to edit, so it isn't listed here.
    final prayers =
        (prayerSchedule?.getPrayersInOrder() ?? [])
            .where((p) => p.name != 'Sunrise')
            .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Prayer Schedule',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today\'s prayer times',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (prayers.isEmpty)
              _buildEmptyState(context)
            else
              ...prayers.map((prayer) {
                return PrayerCard(
                  prayer: prayer,
                  isNext: nextPrayer?.name == prayer.name,
                  adminMode: adminMode,
                  onEditIqama: () => _showEditIqamaDialog(context, prayer),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No prayer times',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditIqamaDialog(
    BuildContext context,
    PrayerTime prayer,
  ) async {
    if (!adminMode) return;

    // Parse current iqama time to get initial values
    TimeOfDay initialTime = _parseTimeString(prayer.iqama);
    TimeOfDay? selectedTime = initialTime;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.getPrayerColor(
                        prayer.name,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      AppColors.getPrayerIcon(prayer.name),
                      color: AppColors.getPrayerColor(prayer.name),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit ${prayer.name} Iqama',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Waqt: ${PrayerTime.trimTime(prayer.waqt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? initialTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              timePickerTheme: TimePickerThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppStyles.radiusLarge,
                                  ),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(
                          AppStyles.radiusMedium,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Iqama Time (24-hour format)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimeOfDay(selectedTime ?? initialTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select time using the picker',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final formattedTime = _formatTimeOfDay(
                      selectedTime ?? initialTime,
                    );
                    Navigator.pop(context, formattedTime);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusMedium,
                      ),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // If cancelled (result is null), return early
    if (result == null) {
      return;
    }

    // If result is empty, return early
    if (result.trim().isEmpty) {
      return;
    }

    // Update locally
    onIqamaUpdated(prayer.name, result.trim());

    // Save to local storage
    try {
      final cachedIqama = await StorageService.getIqamaTimes();
      cachedIqama[prayer.name] = result.trim();
      await StorageService.saveIqamaTimes(cachedIqama);
    } catch (e) {
      debugPrint('Failed to save iqama locally: $e');
    }

    // Save to Firestore
    try {
      final cachedIqama = await StorageService.getIqamaTimes();
      await FirebaseService.saveIqamaTimes(cachedIqama);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${prayer.name} iqama updated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally. Failed to sync: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  // Helper method to parse time string to TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    try {
      // Remove any extra whitespace
      timeStr = timeStr.trim();

      // Handle 12-hour format (e.g., "12:15 PM" or "1:30 pm")
      if (timeStr.toUpperCase().contains('AM') ||
          timeStr.toUpperCase().contains('PM')) {
        final isPM = timeStr.toUpperCase().contains('PM');
        final timePart = timeStr.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();
        final parts = timePart.split(':');

        if (parts.length == 2) {
          int hour = int.parse(parts[0].trim());
          final minute = int.parse(parts[1].trim());

          // Convert to 24-hour format
          if (isPM && hour != 12) {
            hour += 12;
          } else if (!isPM && hour == 12) {
            hour = 0;
          }

          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Handle 24-hour format (e.g., "14:30")
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }

    // Default to current time if parsing fails
    return TimeOfDay.now();
  }

  // Helper method to format TimeOfDay to string (24-hour format)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
