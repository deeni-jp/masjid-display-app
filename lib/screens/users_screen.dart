// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.email.toLowerCase().contains(lowerQuery) ||
            (user.displayName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  Future<void> _showUserManagementDialog(AppUser user) async {
    await showDialog(
      context: context,
      builder: (context) => _UserManagementDialog(
        user: user,
        onRoleChange: () {
          Navigator.pop(context);
          _changeUserRole(user);
        },
        onPasswordReset: () {
          Navigator.pop(context);
          _handlePasswordReset(user);
        },
        onDelete: () {
          Navigator.pop(context);
          _handleDeleteUser(user);
        },
      ),
    );
  }

  Future<void> _changeUserRole(AppUser user) async {
    final currentUser = await UserService.getCurrentUser();

    // Check if trying to change own role
    if (currentUser?.uid == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot change your own role')),
        );
      }
      return;
    }

    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => _RoleSelectionDialog(currentRole: user.role),
    );

    if (newRole == null || newRole == user.role) return;

    try {
      await UserService.updateUserRole(uid: user.uid, newRole: newRole);

      // Update local list
      setState(() {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index != -1) {
          _users[index] = user.copyWith(role: newRole);
        }
        _filterUsers(_searchController.text);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.email} is now ${newRole.displayName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePasswordReset(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        title: Text(
          'Send Password Reset Email?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'A password reset email will be sent to:\n${user.email}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserService.sendPasswordResetEmail(email: user.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(AppUser user) async {
    // Check if user can be deleted
    final errorMessage = await UserService.canDeleteUser(user.uid);

    if (errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show delete confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(user: user),
    );

    if (confirmed != true) return;

    try {
      await UserService.deleteUser(uid: user.uid, email: user.email);

      // Remove from local list
      setState(() {
        _users.removeWhere((u) => u.uid == user.uid);
        _filterUsers(_searchController.text);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.email} deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filterUsers,
            ),
          ),

          // Stats Row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium),
            child: _buildStatsRow(),
          ),
          const SizedBox(height: 8),

          // User List
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final adminCount = _users.where((u) => u.isAdmin).length;
    final modCount = _users.where((u) => u.isModerator).length;
    final publicCount = _users.where((u) => u.isPublic).length;

    return Row(
      children: [
        _buildStatChip('All', _users.length, Colors.grey),
        const SizedBox(width: 8),
        _buildStatChip('Admin', adminCount, Colors.red),
        const SizedBox(width: 8),
        _buildStatChip('Mod', modCount, Colors.orange),
        const SizedBox(width: 8),
        _buildStatChip('Public', publicCount, Colors.green),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load users',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No users found'
                  : 'No users yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _UserCard(
            user: user,
            onManage: () => _showUserManagementDialog(user),
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onManage;

  const _UserCard({
    required this.user,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              child: Text(
                user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.email,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.displayName != null) ...[
                    Text(
                      user.email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRoleBadge(user.role),
                      const SizedBox(width: 8),
                      if (user.lastLogin != null)
                        Text(
                          'Last: ${DateFormat('MMM d').format(user.lastLogin!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Manage User Button
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: onManage,
              tooltip: 'Manage User',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(
          color: _getRoleColor(role).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getRoleColor(role),
        ),
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
}

class _UserManagementDialog extends StatelessWidget {
  final AppUser user;
  final VoidCallback onRoleChange;
  final VoidCallback onPasswordReset;
  final VoidCallback onDelete;

  const _UserManagementDialog({
    required this.user,
    required this.onRoleChange,
    required this.onPasswordReset,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      title: Text(
        'Manage User',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (user.displayName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buildRoleBadge(user.role, context),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Change Role Button
          ElevatedButton.icon(
            onPressed: onRoleChange,
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Change Role'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Send Password Reset Button
          OutlinedButton.icon(
            onPressed: onPasswordReset,
            icon: const Icon(Icons.lock_reset),
            label: const Text('Send Password Reset'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delete User Button
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete User'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(UserRole role, BuildContext context) {
    Color color;
    switch (role) {
      case UserRole.admin:
        color = Colors.red;
        break;
      case UserRole.moderator:
        color = Colors.orange;
        break;
      case UserRole.public:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        role.displayName,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final AppUser user;

  const _DeleteConfirmationDialog({required this.user});

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canDelete {
    return _acknowledged &&
        _emailController.text.trim().toLowerCase() ==
            widget.user.email.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Delete User',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'This action is permanent and cannot be undone. The user will be deleted from both Firebase Authentication and Firestore.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.red.shade900,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // User Email Display
          Text(
            'User to delete:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.email,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Email Confirmation Field
          Text(
            'Type the email address to confirm:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Enter email address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Acknowledgment Checkbox
          CheckboxListTile(
            value: _acknowledged,
            onChanged: (value) => setState(() => _acknowledged = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'I understand this action is permanent',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Delete User'),
        ),
      ],
    );
  }
}

class _RoleSelectionDialog extends StatelessWidget {
  final UserRole currentRole;

  const _RoleSelectionDialog({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
      ),
      title: Text(
        'Select Role',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: UserRole.values.map((role) {
          final isSelected = role == currentRole;
          return ListTile(
            leading: Icon(
              _getRoleIcon(role),
              color: _getRoleColor(role),
            ),
            title: Text(
              role.displayName,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _getRoleDescription(role),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            onTap: () => Navigator.pop(context, role),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
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

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full access, manage users & settings';
      case UserRole.moderator:
        return 'Can create announcements';
      case UserRole.public:
        return 'View only access';
    }
  }
}
