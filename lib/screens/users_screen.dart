// lib/screens/users_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/deletion_log.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Active users
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];

  // Deleted users
  List<DeletionLog> _deletedUsers = [];
  List<DeletionLog> _filteredDeletedUsers = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _searchController.clear();
        _loadUsers();
      }
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_tabController.index == 0) {
        // Load active users
        final users = await UserService.getAllUsers();
        setState(() {
          _users = users;
          _filteredUsers = users;
          _loading = false;
        });
      } else {
        // Load deleted users
        await _loadDeletedUsers();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadDeletedUsers() async {
    try {
      final logs = await UserService.getDeletionLogs();
      setState(() {
        _deletedUsers = logs.map((log) => DeletionLog.fromMap(log)).toList();
        _filteredDeletedUsers = _deletedUsers;
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
      setState(() {
        _filteredUsers = _users;
        _filteredDeletedUsers = _deletedUsers;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    if (_tabController.index == 0) {
      // Filter active users
      setState(() {
        _filteredUsers =
            _users.where((user) {
              return user.email.toLowerCase().contains(lowerQuery) ||
                  (user.displayName?.toLowerCase().contains(lowerQuery) ??
                      false);
            }).toList();
      });
    } else {
      // Filter deleted users
      setState(() {
        _filteredDeletedUsers =
            _deletedUsers.where((log) {
              return log.email.toLowerCase().contains(lowerQuery) ||
                  log.displayName.toLowerCase().contains(lowerQuery);
            }).toList();
      });
    }
  }

  Future<void> _showUserManagementDialog(AppUser user) async {
    await showDialog(
      context: context,
      builder:
          (context) => _UserManagementDialog(
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
    if (!mounted) return;

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
      builder:
          (context) => AlertDialog(
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

    if (!mounted) return;

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

  Future<void> _handlePermanentlyDeleteLog(DeletionLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            ),
            title: Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Forever',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Permanently delete this deletion log? This will remove all audit records for ${log.email}. This action cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Forever'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await UserService.permanentlyDeleteLog(log.logId);

      // Remove from local list
      setState(() {
        _deletedUsers.removeWhere((l) => l.logId == log.logId);
        _filteredDeletedUsers.removeWhere((l) => l.logId == log.logId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion log for ${log.email} removed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete log: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFullUserData(DeletionLog log) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(log.userData);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            ),
            title: Text(
              'Full User Data',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: GoogleFonts.sourceCodePro(fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Active Users'),
            Tab(icon: Icon(Icons.history), text: 'Deleted Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Users Tab
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppStyles.paddingMedium),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterUsers('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: _filterUsers,
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.paddingMedium,
                ),
                child: _buildStatsRow(),
              ),
              const SizedBox(height: 8),

              // User List
              Expanded(child: _buildUserList()),
            ],
          ),

          // Deleted Users Tab
          _buildDeletedUsersTab(),
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
        color: color.withValues(alpha: 0.1),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color)),
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

  Widget _buildDeletedUsersTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search deleted users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
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

        // Deleted Users Count
        if (!_loading)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.paddingMedium,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_deletedUsers.length}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deleted',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Deleted Users List
        Expanded(child: _buildDeletedUserList()),
      ],
    );
  }

  Widget _buildDeletedUserList() {
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
              'Failed to load deleted users',
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

    if (_filteredDeletedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No deleted users found'
                  : 'No deleted users yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Deleted users will appear here',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        itemCount: _filteredDeletedUsers.length,
        itemBuilder: (context, index) {
          final log = _filteredDeletedUsers[index];
          return _DeletedUserCard(
            log: log,
            onPermanentlyDelete: () => _handlePermanentlyDeleteLog(log),
            onViewFullData: () => _showFullUserData(log),
          );
        },
      ),
    );
  }
}

class _DeletedUserCard extends StatefulWidget {
  final DeletionLog log;
  final VoidCallback onPermanentlyDelete;
  final VoidCallback onViewFullData;

  const _DeletedUserCard({
    required this.log,
    required this.onPermanentlyDelete,
    required this.onViewFullData,
  });

  @override
  State<_DeletedUserCard> createState() => _DeletedUserCardState();
}

class _DeletedUserCardState extends State<_DeletedUserCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.withValues(alpha: 0.2),
            child: const Icon(Icons.person_off, color: Colors.red, size: 20),
          ),
          title: Text(
            widget.log.email,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppStyles.radiusSmall,
                      ),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.log.role.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Deleted ${widget.log.formattedDate}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: widget.onPermanentlyDelete,
            tooltip: 'Delete Forever',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('UID', widget.log.uid),
                  _buildDetailRow('Email', widget.log.email),
                  _buildDetailRow('Display Name', widget.log.displayName),
                  _buildDetailRow('Role', widget.log.role),
                  _buildDetailRow('Deleted By', widget.log.deletedByEmail),
                  _buildDetailRow(
                    'Deleted At',
                    DateFormat(
                      'MMM d, yyyy \'at\' h:mm a',
                    ).format(widget.log.deletedAt),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: widget.onViewFullData,
                    icon: const Icon(Icons.data_object),
                    label: const Text('View Full User Data'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onManage;

  const _UserCard({required this.user, required this.onManage});

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
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
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
        color: _getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(
          color: _getRoleColor(role).withValues(alpha: 0.5),
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
              border: Border.all(color: Colors.grey.shade300, width: 1),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
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
      // Add inset padding to prevent edge overflow
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
      // Wrap content in scrollable container
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
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
                  'This will prevent the user from accessing the app. Their account will be marked as deleted and logged for audit purposes. Note: The user will not be able to sign up again with the same email.',
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
                scrollPadding: const EdgeInsets.all(
                  20,
                ), // Auto-scroll when focused
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
                onChanged:
                    (value) => setState(() => _acknowledged = value ?? false),
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
        ),
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
        children:
            UserRole.values.map((role) {
              final isSelected = role == currentRole;
              return ListTile(
                leading: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                title: Text(
                  role.displayName,
                  style: GoogleFonts.poppins(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _getRoleDescription(role),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing:
                    isSelected
                        ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
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
