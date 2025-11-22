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
    final prayers = prayerSchedule?.getPrayersInOrder() ?? [];

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
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
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
              }).toList(),
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
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditIqamaDialog(
      BuildContext context, PrayerTime prayer) async {
    if (!adminMode) return;

    final controller = TextEditingController(text: prayer.iqama);
    String newValue = prayer.iqama;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getPrayerColor(prayer.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
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
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Iqama Time',
                  hintText: 'e.g. 12:15 PM or 14:30',
                  helperText: 'Enter time in HH:mm format',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                onChanged: (v) => newValue = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, newValue),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && result.trim().isNotEmpty) {
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
  }
}
