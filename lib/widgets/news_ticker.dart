// lib/widgets/news_ticker.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

/// A news ticker widget that displays notifications one at a time
/// with fade transitions. Tapping navigates to the notifications tab.
class NewsTicker extends StatefulWidget {
  final List<MosqueNotification> notifications;
  final void Function(MosqueNotification)? onTap;
  final bool darkMode;
  final Duration rotationInterval;

  const NewsTicker({
    super.key,
    required this.notifications,
    this.onTap,
    this.darkMode = false,
    this.rotationInterval = const Duration(seconds: 4),
  });

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _rotationTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startRotation();
  }

  @override
  void didUpdateWidget(NewsTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset index if notifications changed
    if (oldWidget.notifications.length != widget.notifications.length) {
      _currentIndex = 0;
    }

    // Restart rotation if interval changed
    if (oldWidget.rotationInterval != widget.rotationInterval) {
      _startRotation();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  void _startRotation() {
    _rotationTimer?.cancel();

    if (widget.notifications.length <= 1) return;

    _rotationTimer = Timer.periodic(widget.rotationInterval, (_) {
      _nextNotification();
    });
  }

  void _nextNotification() {
    if (widget.notifications.isEmpty) return;

    // Fade out
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.notifications.length;
        });
        // Fade in
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final notification = widget.notifications[_currentIndex];
    final bgColor = widget.darkMode
        ? AppColors.tickerBackground
        : AppColors.tickerBackgroundLight;
    final textColor =
        widget.darkMode ? AppColors.tickerText : AppColors.tickerTextLight;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!(notification);
        }
      },
      child: Container(
        height: AppStyles.tickerHeight,
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Type indicator
            _buildTypeIndicator(notification),

            // Notification content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(notification, textColor),
              ),
            ),

            // Navigation arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textColor.withOpacity(0.5),
                size: 20,
              ),
            ),

            // Pagination dots (if multiple)
            if (widget.notifications.length > 1)
              _buildPaginationDots(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIndicator(MosqueNotification notification) {
    final typeColor = _getTypeColor(notification.type);

    return Container(
      width: 4,
      height: double.infinity,
      color: typeColor,
    );
  }

  Widget _buildContent(MosqueNotification notification, Color textColor) {
    // Build display text: Title + Description
    String displayText;
    if (notification.title.isNotEmpty) {
      final preview = notification.getPreview(maxLength: 60);
      displayText = '${notification.title}: $preview';
    } else {
      displayText = notification.getPreview(maxLength: 80);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Type icon
          Icon(
            notification.type.icon,
            color: _getTypeColor(notification.type),
            size: 18,
          ),
          const SizedBox(width: 8),

          // Priority badge (if not low)
          if (notification.priority != NotificationPriority.low) ...[
            _buildPriorityBadge(notification.priority),
            const SizedBox(width: 8),
          ],

          // Title and description
          Expanded(
            child: Text(
              displayText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Expiry indicator
          if (notification.timeUntilExpiry.inHours < 24)
            _buildExpiryBadge(notification),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(NotificationPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: priority.color,
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(MosqueNotification notification) {
    final isUrgent = notification.timeUntilExpiry.inHours < 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        notification.expiryText,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isUrgent ? Colors.red : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildPaginationDots(Color baseColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.notifications.length.clamp(0, 5), // Max 5 dots
          (index) => Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentIndex
                  ? baseColor
                  : baseColor.withOpacity(0.3),
            ),
          ),
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

/// A minimal version of the ticker for compact spaces
class MiniNewsTicker extends StatefulWidget {
  final List<MosqueNotification> notifications;
  final VoidCallback? onTap;
  final Duration rotationInterval;

  const MiniNewsTicker({
    super.key,
    required this.notifications,
    this.onTap,
    this.rotationInterval = const Duration(seconds: 4),
  });

  @override
  State<MiniNewsTicker> createState() => _MiniNewsTickerState();
}

class _MiniNewsTickerState extends State<MiniNewsTicker> {
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(
              notification.type.icon,
              size: 16,
              color: notification.priority.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  notification.title.isNotEmpty
                      ? notification.title
                      : notification.getPreview(maxLength: 40),
                  key: ValueKey(notification.id),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Scrolling marquee style ticker (alternative style)
class MarqueeNewsTicker extends StatefulWidget {
  final List<MosqueNotification> notifications;
  final VoidCallback? onTap;
  final bool darkMode;

  const MarqueeNewsTicker({
    super.key,
    required this.notifications,
    this.onTap,
    this.darkMode = false,
  });

  @override
  State<MarqueeNewsTicker> createState() => _MarqueeNewsTickerState();
}

class _MarqueeNewsTickerState extends State<MarqueeNewsTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();

    if (!_scrollController.hasClients) return;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final bgColor = widget.darkMode
        ? AppColors.tickerBackground
        : AppColors.tickerBackgroundLight;
    final textColor =
        widget.darkMode ? AppColors.tickerText : AppColors.tickerTextLight;

    // Build combined text
    final combinedText = widget.notifications
        .map((n) =>
            '${n.type.displayName.toUpperCase()}: ${n.title.isNotEmpty ? n.title : n.getPreview(maxLength: 50)}')
        .join('  •  ');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: AppStyles.tickerHeight,
        color: bgColor,
        child: Row(
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).colorScheme.primary,
              child: Center(
                child: Text(
                  'NEWS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Scrolling content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      '$combinedText  •  $combinedText', // Duplicate for seamless loop
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget when no ticker notifications
class EmptyTickerPlaceholder extends StatelessWidget {
  final bool darkMode;

  const EmptyTickerPlaceholder({
    super.key,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppStyles.tickerHeight,
      decoration: BoxDecoration(
        color: darkMode
            ? AppColors.tickerBackground
            : AppColors.tickerBackgroundLight,
      ),
      child: Center(
        child: Text(
          'No announcements',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: (darkMode ? AppColors.tickerText : AppColors.tickerTextLight)
                .withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
