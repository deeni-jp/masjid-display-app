// lib/widgets/prayer_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_time.dart';
import '../utils/constants.dart';

class PrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final bool isNext;
  final bool adminMode;
  final VoidCallback? onEditIqama;

  const PrayerCard({
    super.key,
    required this.prayer,
    this.isNext = false,
    this.adminMode = false,
    this.onEditIqama,
  });

  @override
  Widget build(BuildContext context) {
    final prayerColor = AppColors.getPrayerColor(prayer.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border:
            isNext
                ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
                : null,
        boxShadow: AppStyles.cardShadowLight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Row(
          children: [
            // Prayer Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: prayerColor,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
              child: Icon(
                AppColors.getPrayerIcon(prayer.name),
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Prayer Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        prayer.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(width: 8),
                        _buildNextBadge(context),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTimeChip(
                        context: context,
                        label: 'Waqt',
                        time: PrayerTime.trimTime(prayer.waqt),
                        isSecondary: true,
                      ),
                      const SizedBox(width: 12),
                      _buildTimeChip(
                        context: context,
                        label: 'Iqama',
                        time: PrayerTime.trimTime(prayer.iqama),
                        isSecondary: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit Button (Admin only)
            if (adminMode && onEditIqama != null)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onEditIqama,
                tooltip: 'Edit Iqama',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Text(
        'NEXT',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required BuildContext context,
    required String label,
    required String time,
    required bool isSecondary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w600,
            color:
                isSecondary
                    ? Colors.grey
                    : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

/// Compact prayer row for home tab table view
class CompactPrayerRow extends StatelessWidget {
  final PrayerTime prayer;
  final bool isNext;

  const CompactPrayerRow({
    super.key,
    required this.prayer,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final prayerColor = AppColors.getPrayerColor(prayer.name);

    return Container(
      decoration: BoxDecoration(
        color:
            isNext
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingMedium,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Prayer name with icon
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: prayerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      AppColors.getPrayerIcon(prayer.name),
                      size: 16,
                      color: prayerColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    prayer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Waqt time
            Expanded(
              flex: 2,
              child: Text(
                PrayerTime.trimTime(prayer.waqt),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),

            // Iqama time
            Expanded(
              flex: 2,
              child: Text(
                PrayerTime.trimTime(prayer.iqama),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini prayer chip for quick display
class PrayerChip extends StatelessWidget {
  final PrayerTime prayer;
  final bool isActive;

  const PrayerChip({super.key, required this.prayer, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final prayerColor = AppColors.getPrayerColor(prayer.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? prayerColor : prayerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppColors.getPrayerIcon(prayer.name),
            size: 20,
            color: isActive ? Colors.white : prayerColor,
          ),
          const SizedBox(height: 4),
          Text(
            prayer.name,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : prayerColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            PrayerTime.trimTime(prayer.iqama),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
