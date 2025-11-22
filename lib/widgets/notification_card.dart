// lib/widgets/notification_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Full notification card for notifications tab
class NotificationCard extends StatelessWidget {
  final MosqueNotification notification;
  final bool adminMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const NotificationCard({
    super.key,
    required this.notification,
    this.adminMode = false,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title.isNotEmpty) ...[
                        Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        DateFormat('MMM d, yyyy • hh:mm a')
                            .format(notification.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (adminMode && onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Message Body
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Read More
            if (notification.message.length > 200) ...[
              const SizedBox(height: 12),
              Text(
                'Tap to read more',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Posted By
            if (notification.postedBy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    notification.postedBy,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Icon(
        Icons.campaign,
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
    );
  }
}

/// Compact notification banner for home tab
class NotificationBanner extends StatelessWidget {
  final MosqueNotification notification;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!notification.shouldShow) return const SizedBox.shrink();

    final preview = notification.getPreview();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.title.isNotEmpty)
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      preview,
                      style: GoogleFonts.poppins(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small notification chip/badge
class NotificationChip extends StatelessWidget {
  final MosqueNotification notification;
  final VoidCallback? onTap;

  const NotificationChip({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!notification.shouldShow) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              notification.title.isNotEmpty
                  ? notification.title
                  : 'New Announcement',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty notification state widget
class EmptyNotificationState extends StatelessWidget {
  final bool adminMode;
  final VoidCallback? onAddNotification;

  const EmptyNotificationState({
    super.key,
    this.adminMode = false,
    this.onAddNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No announcements',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates\nfrom the mosque',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (adminMode && onAddNotification != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddNotification,
                icon: const Icon(Icons.add),
                label: Text(
                  'Add Announcement',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Notification detail bottom sheet
class NotificationDetailSheet extends StatelessWidget {
  final MosqueNotification notification;

  const NotificationDetailSheet({
    super.key,
    required this.notification,
  });

  static void show(BuildContext context, MosqueNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NotificationDetailSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.title.isNotEmpty)
                          Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy • hh:mm a')
                              .format(notification.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Footer
              if (notification.postedBy.isNotEmpty)
                Text(
                  'Posted by ${notification.postedBy}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
