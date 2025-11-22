// lib/screens/more_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'users_screen.dart';
import 'profile_screen.dart';

class MoreTab extends StatelessWidget {
  final LocationData? locationData;
  final bool usingRemoteIqama;
  final AppUser currentUser;
  final bool darkMode;
  final Future<void> Function(bool, {bool manual}) onToggleTheme;
  final void Function(AppUser?) onUserChanged;

  const MoreTab({
    super.key,
    required this.locationData,
    required this.usingRemoteIqama,
    required this.currentUser,
    required this.darkMode,
    required this.onToggleTheme,
    required this.onUserChanged,
  });

  bool get isAdmin => currentUser.isAdmin;
  bool get isModerator => currentUser.isModerator;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'More',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // User Card
          _buildUserCard(context),
          const SizedBox(height: 16),

          // Admin Section - Manage Users (Admin only)
          if (isAdmin)
            _buildSettingsCard(
              context,
              icon: Icons.people,
              title: 'Manage Users',
              subtitle: 'View and change user roles',
              onTap: () => _openUsersScreen(context),
              iconColor: Colors.blue,
            ),

          // Account / Profile
          _buildSettingsCard(
            context,
            icon: Icons.person,
            title: 'My Profile',
            subtitle: 'Edit display name & password',
            onTap: () => _openProfileScreen(context),
          ),

          // Settings Section
          _buildSettingsCard(
            context,
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'App preferences',
            onTap: () => _openSettings(context),
          ),

          // Theme Section
          _buildSettingsCard(
            context,
            icon: darkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            subtitle: darkMode ? 'Dark mode' : 'Light mode',
            onTap: () => onToggleTheme(!darkMode, manual: true),
            trailing: darkMode ? 'Light' : 'Dark',
          ),

          // About Section
          _buildSettingsCard(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and info',
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 16),

          // Sign Out Button
          _buildSignOutButton(context),

          const SizedBox(height: 24),

          // Info Card
          _buildInfoCard(context),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return InkWell(
      onTap: () => _openProfileScreen(context),
      borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          boxShadow: AppStyles.cardShadowLight,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: _getRoleColor(currentUser.role).withOpacity(0.2),
              child: Text(
                currentUser.email.isNotEmpty
                    ? currentUser.email[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(currentUser.role),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.displayName ?? currentUser.email,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentUser.displayName != null)
                    Text(
                      currentUser.email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  _buildRoleBadge(currentUser.role),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(
          color: _getRoleColor(role).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 14,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.public:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.moderator:
        return Icons.shield;
      case UserRole.public:
        return Icons.person;
    }
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailing,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            boxShadow: AppStyles.cardShadowLight,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: Text(
                    trailing,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return InkWell(
      onTap: () => _signOut(context),
      borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: darkMode
              ? AppColors.headerGradientDark
              : AppColors.headerGradientLight,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
                child: const Icon(
                  Icons.mosque,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppConstants.appName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on,
            locationData?.formattedLocation ?? 'Unknown',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.cloud_outlined,
            usingRemoteIqama ? 'Connected to server' : 'Using cached data',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            _getRoleIcon(currentUser.role),
            '${currentUser.role.displayName} user',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  void _openUsersScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersScreen()),
    );
  }

  void _openProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          currentUser: currentUser,
          onUserChanged: onUserChanged,
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UserService.signOut();
      onUserChanged(null);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  Future<void> _openSettings(BuildContext context) async {
    final defaultLocation = await StorageService.getDefaultLocation();
    final controller = TextEditingController(text: defaultLocation);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool localDarkMode = darkMode;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(AppStyles.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: Text('Dark Mode', style: GoogleFonts.poppins()),
                      value: localDarkMode,
                      onChanged: (v) {
                        setSheetState(() => localDarkMode = v);
                        onToggleTheme(v, manual: true);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Default Location',
                        hintText: 'Enter city name',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await StorageService.setDefaultLocation(
                                controller.text.trim());
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings saved')),
                              );
                            }
                          },
                          child: Text(
                            'Save',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              child: Icon(
                Icons.mosque,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'About',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version ${AppConstants.appVersion}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Stay connected with accurate prayer times and mosque announcements.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Made with ❤️ for the community',
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
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
