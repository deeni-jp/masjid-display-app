// lib/screens/notifications_tab.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/fcm_notification_sender.dart';
import '../utils/constants.dart';
import '../widgets/notification_card.dart';

class NotificationsTab extends StatefulWidget {
  final List<MosqueNotification> notifications;
  final bool notifLoaded;
  final bool adminMode; // True for Admin AND Moderator
  final void Function(List<MosqueNotification> notifications)
      onNotificationsUpdated;

  const NotificationsTab({
    super.key,
    required this.notifications,
    required this.notifLoaded,
    required this.adminMode,
    required this.onNotificationsUpdated,
  });

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  NotificationFilter _currentFilter = NotificationFilter.all;

  List<MosqueNotification> get _filteredNotifications {
    // For admin/moderator, show all (including inactive)
    // For public users, show only active
    final baseList = widget.adminMode
        ? widget.notifications.where((n) => !n.isExpired).toList()
        : widget.notifications.activeOnly;

    switch (_currentFilter) {
      case NotificationFilter.all:
        return baseList.sortedByPriorityThenExpiry;
      case NotificationFilter.announcements:
        return baseList
            .where((n) => n.type == NotificationType.announcement)
            .toList()
            .sortedByExpiry;
      case NotificationFilter.events:
        return baseList
            .where((n) => n.type == NotificationType.event)
            .toList()
            .sortedByExpiry;
      case NotificationFilter.alerts:
        return baseList
            .where((n) => n.type == NotificationType.alert)
            .toList()
            .sortedByExpiry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(context),

        // Filter chips
        _buildFilterChips(context),

        // Notifications list
        Expanded(
          child: _buildNotificationsList(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final activeCount = widget.notifications.activeOnly.length;
    final totalCount = widget.notifications.where((n) => !n.isExpired).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        0,
      ),
      child: Row(
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
                  widget.adminMode
                      ? '$activeCount active, ${totalCount - activeCount} inactive'
                      : '$activeCount notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (widget.adminMode)
            FloatingActionButton.small(
              heroTag: 'add_notification',
              onPressed: () => _showCreateEditDialog(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          final count = _getFilterCount(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(
                count > 0
                    ? '${filter.displayName} ($count)'
                    : filter.displayName,
              ),
              avatar: Icon(
                filter.icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
              onSelected: (_) {
                setState(() => _currentFilter = filter);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getFilterCount(NotificationFilter filter) {
    final baseList = widget.adminMode
        ? widget.notifications.where((n) => !n.isExpired).toList()
        : widget.notifications.activeOnly;

    switch (filter) {
      case NotificationFilter.all:
        return baseList.length;
      case NotificationFilter.announcements:
        return baseList
            .where((n) => n.type == NotificationType.announcement)
            .length;
      case NotificationFilter.events:
        return baseList.where((n) => n.type == NotificationType.event).length;
      case NotificationFilter.alerts:
        return baseList.where((n) => n.type == NotificationType.alert).length;
    }
  }

  Widget _buildNotificationsList(BuildContext context) {
    if (!widget.notifLoaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return EmptyNotificationState(
        adminMode: widget.adminMode,
        onAddNotification: () => _showCreateEditDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NotificationCard(
              notification: notification,
              adminMode: widget.adminMode,
              onTap: (n) => _showNotificationDetail(context, n),
              onEdit: () =>
                  _showCreateEditDialog(context, notification: notification),
              onDelete: () => _confirmDelete(context, notification),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    try {
      final notifications = await FirebaseService.getNotifications();
      widget.onNotificationsUpdated(notifications);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  void _showNotificationDetail(
      BuildContext context, MosqueNotification notification) {
    NotificationDetailSheet.show(
      context,
      notification,
      adminMode: widget.adminMode,
      onEdit: () => _showCreateEditDialog(context, notification: notification),
      onDelete: () => _confirmDelete(context, notification),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, MosqueNotification notification) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        title: Text(
          'Delete Notification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${notification.title.isNotEmpty ? notification.title : 'this notification'}"?\n\nThis action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Firestore
      await FirebaseService.deleteNotification(notification.id);

      // Update local list
      final updatedList = List<MosqueNotification>.from(widget.notifications)
        ..removeWhere((n) => n.id == notification.id);
      widget.onNotificationsUpdated(updatedList);

      // Update cache
      await StorageService.removeNotification(notification.id);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _showCreateEditDialog(
    BuildContext context, {
    MosqueNotification? notification,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isEditing = notification != null;

    // Controllers
    final titleController =
        TextEditingController(text: notification?.title ?? '');
    final messageController =
        TextEditingController(text: notification?.message ?? '');

    // State
    NotificationType selectedType =
        notification?.type ?? NotificationType.announcement;
    NotificationPriority selectedPriority =
        notification?.priority ?? NotificationPriority.regular;
    bool isActive = notification?.active ?? true;
    DateTime? eventTime = notification?.eventTime;
    DateTime expiresAt = notification?.expiresAt ??
        DateTime.now().add(AppConstants.defaultAnnouncementExpiry);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: MediaQuery.of(dialogContext).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit : Icons.add_circle,
                            color: Theme.of(dialogContext).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing
                                ? 'Edit Notification'
                                : 'New Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content - Scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type selector
                            Text(
                              'Type',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTypeSelector(
                              dialogContext,
                              selectedType,
                              (type) => setDialogState(() {
                                selectedType = type;
                                // Auto-adjust expiry based on type
                                if (type == NotificationType.alert) {
                                  expiresAt = DateTime.now()
                                      .add(AppConstants.defaultAlertExpiry);
                                } else if (type == NotificationType.event) {
                                  expiresAt = DateTime.now()
                                      .add(AppConstants.defaultEventExpiry);
                                } else {
                                  expiresAt = DateTime.now().add(
                                      AppConstants.defaultAnnouncementExpiry);
                                }
                              }),
                            ),
                            const SizedBox(height: 16),

                            // Priority selector
                            Text(
                              'Priority',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPrioritySelector(
                              dialogContext,
                              selectedPriority,
                              (priority) => setDialogState(
                                  () => selectedPriority = priority),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                hintText: 'Enter notification title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppStyles.radiusMedium),
                                ),
                                prefixIcon: const Icon(Icons.title),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Message
                            TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                labelText: 'Message *',
                                hintText: 'Enter notification message',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppStyles.radiusMedium),
                                ),
                                prefixIcon: const Icon(Icons.message),
                                alignLabelWithHint: true,
                              ),
                              minLines: 3,
                              maxLines: 6,
                              maxLength: 500,
                            ),
                            const SizedBox(height: 8),

                            // Event Time (for event type)
                            if (selectedType == NotificationType.event) ...[
                              _buildDateTimePicker(
                                dialogContext,
                                label: 'Event Time',
                                icon: Icons.event,
                                value: eventTime,
                                onChanged: (dt) => setDialogState(() {
                                  eventTime = dt;
                                  // Set expiry to event time
                                  if (dt != null) {
                                    expiresAt = dt;
                                  }
                                }),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Expiration Date
                            _buildDateTimePicker(
                              dialogContext,
                              label: 'Expires At',
                              icon: Icons.timer_off,
                              value: expiresAt,
                              onChanged: (dt) {
                                if (dt != null) {
                                  setDialogState(() => expiresAt = dt);
                                }
                              },
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),

                            // Active toggle
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(
                                    AppStyles.radiusMedium),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  'Visible to Users',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  isActive
                                      ? 'Active - shown to everyone'
                                      : 'Inactive - hidden from public',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color:
                                        isActive ? Colors.green : Colors.orange,
                                  ),
                                ),
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppStyles.radiusMedium),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (messageController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text('Message is required')),
                                );
                                return;
                              }
                              Navigator.pop(dialogContext, true);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppStyles.radiusMedium),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Update' : 'Create',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      // Dispose controllers after dialog closes
      titleController.dispose();
      messageController.dispose();
      return;
    }

    // Get current user info
    String postedBy = notification?.postedBy ?? '';
    String postedByRole = notification?.postedByRole ?? 'Staff';
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser != null) {
        postedBy = currentUser.email; // Store email in database
        postedByRole =
            currentUser.role.displayName; // Store role (Admin/Moderator)
      }
    } catch (_) {}

    // Create notification object
    final newNotification = MosqueNotification(
      id: notification?.id ?? '',
      title: titleController.text.trim(),
      message: messageController.text.trim(),
      type: selectedType,
      priority: selectedPriority,
      active: isActive,
      postedBy: postedBy,
      postedByRole: postedByRole,
      createdAt: notification?.createdAt ?? DateTime.now(),
      eventTime: selectedType == NotificationType.event ? eventTime : null,
      expiresAt: expiresAt,
    );

    // Save
    try {
      MosqueNotification savedNotification;

      if (isEditing) {
        await FirebaseService.updateNotification(newNotification);
        savedNotification = newNotification;
      } else {
        savedNotification =
            await FirebaseService.createNotification(newNotification);
      }

      // Send push notification if the notification is active
      if (savedNotification.active && !savedNotification.isExpired) {
        if (kDebugMode) {
          print('Sending push notification for: ${savedNotification.title}');
        }

        // Send push notification to all users
        final sent = await FCMNotificationSender.sendNotificationToTopic(
          notification: savedNotification,
        );

        if (kDebugMode) {
          print(sent
              ? '✅ Push notification sent successfully'
              : '❌ Failed to send push notification');
        }
      }

      // Check if still mounted after async operation
      if (!mounted) {
        titleController.dispose();
        messageController.dispose();
        return;
      }

      // Update local list
      final updatedList = List<MosqueNotification>.from(widget.notifications);
      if (isEditing) {
        final index =
            updatedList.indexWhere((n) => n.id == savedNotification.id);
        if (index >= 0) {
          updatedList[index] = savedNotification;
        }
      } else {
        // Check if notification already exists (to prevent duplicates from Firestore listener)
        final exists = updatedList.any((n) => n.id == savedNotification.id);
        if (!exists) {
          updatedList.add(savedNotification);
        }
      }
      widget.onNotificationsUpdated(updatedList);

      // Update cache
      await StorageService.saveNotifications(updatedList);

      // Check if still mounted before showing snackbar
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                isEditing ? 'Notification updated' : 'Notification created'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      // Check if still mounted before showing error
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      // Dispose controllers at the very end
      titleController.dispose();
      messageController.dispose();
    }
  }

  Widget _buildTypeSelector(
    BuildContext context,
    NotificationType selected,
    void Function(NotificationType) onSelected,
  ) {
    return Row(
      children: NotificationType.values.map((type) {
        final isSelected = type == selected;
        final color = _getTypeColor(type);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != NotificationType.values.last ? 6 : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(type),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected ? color : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector(
    BuildContext context,
    NotificationPriority selected,
    void Function(NotificationPriority) onSelected,
  ) {
    return Row(
      children: NotificationPriority.values.map((priority) {
        final isSelected = priority == selected;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority != NotificationPriority.values.last ? 6 : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(priority),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? priority.backgroundColor
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  border: Border.all(
                    color: isSelected ? priority.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    priority.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? priority.color : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context, {
    required String label,
    required IconData icon,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
    bool isRequired = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (date == null) return;

        if (!context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );

        if (time == null) return;

        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        onChanged(dateTime);
      },
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label${isRequired ? ' *' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value != null
                        ? DateFormat('MMM d, yyyy • hh:mm a').format(value)
                        : 'Tap to select',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return AppColors.typeAnnouncement;
      case NotificationType.event:
        return AppColors.typeEvent;
      case NotificationType.alert:
        return AppColors.typeAlert;
    }
  }
}
