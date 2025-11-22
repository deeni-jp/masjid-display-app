// lib/screens/notifications_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class NotificationsTab extends StatelessWidget {
  final MosqueNotification notification;
  final bool notifLoaded;
  final bool adminMode; // True for Admin AND Moderator
  final void Function(MosqueNotification notification) onNotificationUpdated;

  const NotificationsTab({
    super.key,
    required this.notification,
    required this.notifLoaded,
    required this.adminMode,
    required this.onNotificationUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcements',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stay updated with mosque news',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (adminMode)
                IconButton(
                  icon: Icon(
                    notification.active ? Icons.edit : Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  iconSize: 32,
                  onPressed: () => _showEditNotificationDialog(context),
                  tooltip: notification.active
                      ? 'Edit Notification'
                      : 'Add Notification',
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!notifLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (notification.shouldShow)
            _buildNotificationCard(context)
          else
            _buildEmptyState(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context) {
    return InkWell(
      onTap: () => _showFullNotification(context),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                ),
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
                if (adminMode)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditNotificationDialog(context),
                    tooltip: 'Edit',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildEmptyState(BuildContext context) {
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
            if (adminMode) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showEditNotificationDialog(context),
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

  void _showFullNotification(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                      if (adminMode)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditNotificationDialog(context);
                          },
                          tooltip: 'Edit',
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
      },
    );
  }

  Future<void> _showEditNotificationDialog(BuildContext context) async {
    final titleController = TextEditingController(text: notification.title);
    final messageController = TextEditingController(text: notification.message);
    bool isActive = notification.active;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              title: Text(
                notification.active ? 'Edit Announcement' : 'New Announcement',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title (optional)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                        ),
                        prefixIcon: const Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Show to users',
                        style: GoogleFonts.poppins(),
                      ),
                      subtitle: Text(
                        isActive ? 'Visible to everyone' : 'Hidden from users',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
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
      },
    );

    if (result == true) {
      // Get current user email for postedBy
      String postedBy = notification.postedBy;
      try {
        final currentUser = await UserService.getCurrentUser();
        if (currentUser != null) {
          postedBy = currentUser.email;
        }
      } catch (_) {}

      final newNotification = MosqueNotification(
        title: titleController.text.trim(),
        message: messageController.text.trim(),
        active: isActive,
        postedBy: postedBy,
        timestamp: DateTime.now(),
      );

      // Update UI
      onNotificationUpdated(newNotification);

      // Save locally
      await StorageService.saveNotification(newNotification);

      // Save to Firestore
      try {
        await FirebaseService.saveNotification(newNotification);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Announcement saved'),
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
              content: Text('Saved locally. Sync failed: $e'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
          );
        }
      }
    }

    titleController.dispose();
    messageController.dispose();
  }
}
