// lib/widgets/notification_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Full notification card for notifications tab
class NotificationCard extends StatelessWidget {
  final MosqueNotification notification;
  final bool adminMode;
  final void Function(MosqueNotification)? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.adminMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!(notification);
        }
      },
      borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          border: Border.all(
            color: notification.priority.color.withOpacity(0.3),
            width: notification.isHighPriority ? 2 : 1,
          ),
          boxShadow: AppStyles.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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
                      // Badges row
                      _buildBadgesRow(context),
                    ],
                  ),
                ),
                // Admin actions
                if (adminMode) _buildAdminActions(context),
              ],
            ),
            const SizedBox(height: 12),

            // Message Body
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Read More
            if (notification.message.length > 150) ...[
              const SizedBox(height: 8),
              Text(
                'Tap to read more',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Icon(
        notification.type.icon,
        color: _getTypeColor(),
        size: 24,
      ),
    );
  }

  Widget _buildBadgesRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Type badge
        _buildTypeBadge(),
        // Priority badge
        _buildPriorityBadge(),
        // Expiry badge
        _buildExpiryBadge(),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            notification.type.icon,
            size: 12,
            color: _getTypeColor(),
          ),
          const SizedBox(width: 4),
          Text(
            notification.type.displayName,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getTypeColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    // Use effective color (red only for high-priority alerts)
    final color = notification.effectivePriorityColor;
    final bgColor = notification.effectivePriorityBgColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notification.isHighPriority) ...[
            Icon(
              Icons.priority_high,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            notification.priority.displayName,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBadge() {
    final isUrgent = notification.timeUntilExpiry.inHours < 6;
    final color = isUrgent ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            notification.expiryText,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      onSelected: (value) {
        if (value == 'edit' && onEdit != null) {
          onEdit!();
        } else if (value == 'delete' && onDelete != null) {
          onDelete!();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.poppins()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Event time (if event type)
        if (notification.isEvent && notification.eventTime != null) ...[
          Icon(Icons.event, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d, yyyy â€¢ hh:mm a')
                .format(notification.eventTime!),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
        ] else ...[
          // Created date
          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d, yyyy').format(notification.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
        ],

        // Posted by - show role (Admin/Moderator)
        if (notification.postedByRole.isNotEmpty) ...[
          Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            notification.postedByRole,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.announcement:
        return AppColors.typeAnnouncement;
      case NotificationType.event:
        return AppColors.typeEvent;
      case NotificationType.alert:
        return AppColors.typeAlert;
    }
  }
}

/// Compact notification card for home tab (high priority only)
class HighPriorityNotificationCard extends StatelessWidget {
  final MosqueNotification notification;
  final void Function(MosqueNotification)? onTap;
  final bool darkMode;

  const HighPriorityNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        0,
      ),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(notification);
          }
        },
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                notification.priority.color.withOpacity(0.15),
                notification.priority.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            border: Border.all(
              color: notification.priority.color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.priority.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  notification.type.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: notification.priority.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.priority.displayName.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.type.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Expiry
                        Text(
                          notification.expiryText,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: notification.timeUntilExpiry.inHours < 6
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
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

                    // Preview
                    Text(
                      notification.getPreview(maxLength: 60),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.announcement:
        return AppColors.typeAnnouncement;
      case NotificationType.event:
        return AppColors.typeEvent;
      case NotificationType.alert:
        return AppColors.typeAlert;
    }
  }
}

/// Rotating high priority notification card for multiple notifications
class RotatingHighPriorityCard extends StatefulWidget {
  final List<MosqueNotification> notifications;
  final void Function(MosqueNotification)? onTap;
  final bool darkMode;
  final Duration rotationInterval;

  const RotatingHighPriorityCard({
    super.key,
    required this.notifications,
    this.onTap,
    this.darkMode = false,
    this.rotationInterval = const Duration(seconds: 5),
  });

  @override
  State<RotatingHighPriorityCard> createState() =>
      _RotatingHighPriorityCardState();
}

class _RotatingHighPriorityCardState extends State<RotatingHighPriorityCard> {
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotation() {
    _rotationTimer?.cancel();

    if (widget.notifications.length <= 1) return;

    _rotationTimer = Timer.periodic(widget.rotationInterval, (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.notifications.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final notification = widget.notifications[_currentIndex];

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: HighPriorityNotificationCard(
            key: ValueKey(notification.id),
            notification: notification,
            onTap: widget.onTap,
            darkMode: widget.darkMode,
          ),
        ),

        // Pagination indicators
        if (widget.notifications.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.notifications.length,
                (index) => Container(
                  width: index == _currentIndex ? 16 : 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: index == _currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Need to import Timer - already imported at top

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
  final bool adminMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NotificationDetailSheet({
    super.key,
    required this.notification,
    this.adminMode = false,
    this.onEdit,
    this.onDelete,
  });

  static void show(
    BuildContext context,
    MosqueNotification notification, {
    bool adminMode = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NotificationDetailSheet(
        notification: notification,
        adminMode: adminMode,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
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
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child: Icon(
                      notification.type.icon,
                      color: _getTypeColor(),
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
                        // Badges
                        Wrap(
                          spacing: 6,
                          children: [
                            _buildSmallBadge(
                              notification.type.displayName,
                              _getTypeColor(),
                            ),
                            _buildSmallBadge(
                              notification.priority.displayName,
                              notification.priority.color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (adminMode)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        Navigator.pop(context);
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text('Edit', style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Delete',
                                  style:
                                      GoogleFonts.poppins(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Meta info
              _buildMetaInfo(context),
              const SizedBox(height: 16),

              // Divider
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 12),

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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Column(
        children: [
          _buildMetaRow(
            context,
            Icons.access_time,
            'Created',
            DateFormat('EEEE, MMM d, yyyy â€¢ hh:mm a')
                .format(notification.createdAt),
          ),
          if (notification.isEvent && notification.eventTime != null) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              context,
              Icons.event,
              'Event Time',
              DateFormat('EEEE, MMM d, yyyy â€¢ hh:mm a')
                  .format(notification.eventTime!),
            ),
          ],
          const SizedBox(height: 8),
          _buildMetaRow(
            context,
            Icons.timer,
            'Expires',
            DateFormat('MMM d, yyyy â€¢ hh:mm a')
                .format(notification.expiresAt),
            valueColor:
                notification.timeUntilExpiry.inHours < 6 ? Colors.red : null,
          ),
          if (notification.postedByRole.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMetaRow(
              context,
              Icons.person_outline,
              'Posted by',
              notification.postedByRole,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Row(
      children: [
        Icon(icon, size: 16, color: labelColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: labelColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? (isDark ? Colors.white : null),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.announcement:
        return AppColors.typeAnnouncement;
      case NotificationType.event:
        return AppColors.typeEvent;
      case NotificationType.alert:
        return AppColors.typeAlert;
    }
  }
}

/// Quick notification banner for home tab (legacy support)
class NotificationBanner extends StatelessWidget {
  final MosqueNotification notification;
  final void Function(MosqueNotification)? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!notification.shouldShow) return const SizedBox.shrink();

    return HighPriorityNotificationCard(
      notification: notification,
      onTap: onTap,
    );
  }
}

/// Notification chip for quick display
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
          color: notification.priority.backgroundColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(
            color: notification.priority.color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notification.type.icon,
              size: 16,
              color: notification.priority.color,
            ),
            const SizedBox(width: 6),
            Text(
              notification.title.isNotEmpty
                  ? notification.title
                  : 'New ${notification.type.displayName}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: notification.priority.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
