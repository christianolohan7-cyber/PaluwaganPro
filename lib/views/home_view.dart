import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/paluwagan_group.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../services/quote_service.dart';
import 'group_detail_view.dart';
import 'profile_view.dart';
import 'notifications_view.dart';
import 'all_groups_view.dart';
import 'create_group_view.dart';
import 'join_group_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user});

  final User user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotifications();
      _loadUserGroups();
    });
  }

  Future<void> _startNotifications() async {
    final authVm = context.read<AuthViewModel>();
    final notifVm = context.read<NotificationViewModel>();

    if (authVm.currentUser != null &&
        notifVm.activeUserId != authVm.currentUser!.id) {
      await notifVm.loadUserNotifications(authVm.currentUser!.id);
      await notifVm.startNotificationsStream(authVm.currentUser!.id);
    }
  }

  Future<void> _loadUserGroups() async {
    final groupsVm = context.read<GroupsViewModel>();
    final authVm = context.read<AuthViewModel>();

    if (authVm.currentUser != null) {
      await groupsVm.loadUserGroups(authVm.currentUser!.id);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'PaluwaganPro';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifVm = context.watch<NotificationViewModel>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        toolbarHeight: _getAppBarTitle().isEmpty ? 0 : kToolbarHeight,
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _NotificationNavIcon(
              icon: Icons.notifications_outlined,
              unreadCount: notifVm.unreadCount,
            ),
            activeIcon: _NotificationNavIcon(
              icon: Icons.notifications,
              unreadCount: notifVm.unreadCount,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add_outlined),
            activeIcon: Icon(Icons.group_add),
            label: 'Join',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeContent();
      case 1:
        return const NotificationsScreenWrapper();
      case 2:
        return const CreateGroupScreenWrapper();
      case 3:
        return const JoinGroupScreenWrapper();
      case 4:
        return const ProfileScreenWrapper();
      default:
        return const HomeContent();
    }
  }
}

class NotificationsScreenWrapper extends StatelessWidget {
  const NotificationsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsScreen();
  }
}

class _NotificationNavIcon extends StatelessWidget {
  const _NotificationNavIcon({required this.icon, required this.unreadCount});

  final IconData icon;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (unreadCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CreateGroupScreenWrapper extends StatelessWidget {
  const CreateGroupScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateGroupScreen();
  }
}

class JoinGroupScreenWrapper extends StatelessWidget {
  const JoinGroupScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const JoinGroupScreen();
  }
}

class ProfileScreenWrapper extends StatelessWidget {
  const ProfileScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _quote = "Loading daily motivation...";
  final _quoteService = QuoteService();
  _HomeGroupTab _selectedGroupTab = _HomeGroupTab.active;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _fetchQuote() async {
    final q = await _quoteService.getRandomQuote();
    if (mounted) {
      setState(() {
        _quote = q;
      });
    }
  }

  Future<void> _refreshData() async {
    final groupsVm = context.read<GroupsViewModel>();
    final authVm = context.read<AuthViewModel>();
    final notifVm = context.read<NotificationViewModel>();

    if (authVm.currentUser != null) {
      await groupsVm.loadUserGroups(authVm.currentUser!.id);
      await notifVm.loadUserNotifications(authVm.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsVm = context.watch<GroupsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupsVm.streamGroups(authVm.currentUser!.id),
      builder: (context, snapshot) {
        final groups =
            snapshot.data?.map((g) => PaluwaganGroup.fromMap(g)).toList() ??
            groupsVm.groups;
        final visibleGroups = groups
            .where((g) => g.groupStatus != 'completed')
            .toList();
        final activeVisibleGroups = visibleGroups
            .where((g) => g.groupStatus == 'active')
            .toList();
        final pendingGroups = visibleGroups
            .where((g) => g.groupStatus == 'pending')
            .toList();
        final completedGroups = groups
            .where((g) => g.groupStatus == 'completed')
            .toList();

        final activeGroups = activeVisibleGroups.length;
        final nextPayout = activeVisibleGroups.isNotEmpty
            ? activeVisibleGroups
                  .map((g) => g.nextPayoutDate)
                  .reduce((a, b) => a.isBefore(b) ? a : b)
            : null;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchQuote();
              await _refreshData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuoteCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildHighlightedSummaryCards(
                    context,
                    activeGroups,
                    activeVisibleGroups,
                    nextPayout,
                    colorScheme,
                  ),
                  const SizedBox(height: 24),
                  _buildGroupNavbar(
                    context,
                    activeCount: activeVisibleGroups.length,
                    pendingCount: pendingGroups.length,
                    completedCount: completedGroups.length,
                    hasVisibleGroups: visibleGroups.isNotEmpty,
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentTabContent(
                    context,
                    colorScheme,
                    groupsVm,
                    activeVisibleGroups: activeVisibleGroups,
                    pendingGroups: pendingGroups,
                    completedGroups: completedGroups,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuoteCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Daily Motivation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _quote,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedSummaryCards(
    BuildContext context,
    int activeGroups,
    List<PaluwaganGroup> groups,
    DateTime? nextPayout,
    ColorScheme colorScheme,
  ) {
    PaluwaganGroup? nearestGroup;

    // Only show next payment for groups that have actually started (active status)
    final startedGroups = groups
        .where((g) => g.groupStatus == 'active')
        .toList();

    if (startedGroups.isNotEmpty) {
      // Find the group with the earliest payout date among started groups
      final minDate = startedGroups
          .map((g) => g.nextPayoutDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      nearestGroup = startedGroups.firstWhere(
        (g) => g.nextPayoutDate == minDate,
        orElse: () => startedGroups.first,
      );

      // Update nextPayout to use the date from started groups
      nextPayout = minDate;
    } else {
      nearestGroup = null;
      nextPayout = null;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Groups',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeGroups.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total groups',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6),
                const Color(0xFF8B5CF6).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Next Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (nearestGroup != null) ...[
                Text(
                  nearestGroup.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateWithYear(nextPayout!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDaysUntil(nextPayout),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                const Text(
                  'No upcoming payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGroupsState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_off,
              size: 48,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Groups Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new group or join an existing one to start your paluwagan journey!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCurrentGroupsState(
    ColorScheme colorScheme, {
    bool hasPendingGroups = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Current Groups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasPendingGroups
                ? 'Your waiting-to-start groups are listed below, and completed cycles are in the Completed page.'
                : 'Your completed paluwagan cycles are available in the Completed page.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEmptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE59F1C).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color: Color(0xFFB77900),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Groups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Groups that are waiting to start will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedEmptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Completed Groups',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed paluwagan cycles will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    List<_HeaderAction> actions = const [],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Wrap(
            spacing: 8,
            children: actions
                .map(
                  (action) => InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.icon, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupNavbar(
    BuildContext context, {
    required int activeCount,
    required int pendingCount,
    required int completedCount,
    required bool hasVisibleGroups,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildNavChip(
            icon: Icons.bolt_rounded,
            label: 'Active',
            count: activeCount,
            isSelected: _selectedGroupTab == _HomeGroupTab.active,
            onTap: () {
              setState(() {
                _selectedGroupTab = _HomeGroupTab.active;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildNavChip(
            icon: Icons.hourglass_top_rounded,
            label: 'Pending',
            count: pendingCount,
            isSelected: _selectedGroupTab == _HomeGroupTab.pending,
            onTap: () {
              setState(() {
                _selectedGroupTab = _HomeGroupTab.pending;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildNavChip(
            icon: Icons.inventory_2_outlined,
            label: 'Completed',
            count: completedCount,
            isSelected: _selectedGroupTab == _HomeGroupTab.completed,
            onTap: () {
              setState(() {
                _selectedGroupTab = _HomeGroupTab.completed;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildNavChip(
            icon: Icons.grid_view_rounded,
            label: 'All',
            count: null,
            isSelected: _selectedGroupTab == _HomeGroupTab.all,
            onTap: () {
              setState(() {
                _selectedGroupTab = _HomeGroupTab.all;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    int? count,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? Colors.grey
                  : (isSelected ? colorScheme.primary : Colors.grey.shade700),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onTap == null
                    ? Colors.grey
                    : (isSelected ? colorScheme.primary : Colors.grey.shade800),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.14)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: onTap == null
                        ? Colors.grey
                        : (isSelected
                              ? colorScheme.primary
                              : Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(
    BuildContext context,
    ColorScheme colorScheme,
    GroupsViewModel groupsVm, {
    required List<PaluwaganGroup> activeVisibleGroups,
    required List<PaluwaganGroup> pendingGroups,
    required List<PaluwaganGroup> completedGroups,
  }) {
    final currentGroups = switch (_selectedGroupTab) {
      _HomeGroupTab.active => activeVisibleGroups,
      _HomeGroupTab.pending => pendingGroups,
      _HomeGroupTab.completed => completedGroups,
      _HomeGroupTab.all => [...activeVisibleGroups, ...pendingGroups, ...completedGroups],
    };

    if (currentGroups.isEmpty) {
      if (_selectedGroupTab == _HomeGroupTab.pending) {
        return _buildPendingEmptyState(colorScheme);
      }

      if (_selectedGroupTab == _HomeGroupTab.completed) {
        return _buildCompletedEmptyState(colorScheme);
      }

      if (_selectedGroupTab == _HomeGroupTab.all) {
        return _buildEmptyGroupsState(colorScheme);
      }

      return completedGroups.isNotEmpty
          ? _buildNoCurrentGroupsState(
              colorScheme,
              hasPendingGroups: pendingGroups.isNotEmpty,
            )
          : _buildEmptyGroupsState(colorScheme);
    }

    if (groupsVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedGroupTab == _HomeGroupTab.active) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC8D5F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'These groups are currently active and already running their payment cycle.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF314A86),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: currentGroups
                  .map((g) => _buildGroupCard(context, g, colorScheme))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (_selectedGroupTab == _HomeGroupTab.pending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1D48C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE59F1C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFFB77900),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'These groups are waiting to start or still need the creator to begin the cycle.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F4E00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: currentGroups
                  .map((g) => _buildGroupCard(context, g, colorScheme))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (_selectedGroupTab == _HomeGroupTab.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F7F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBEDDC4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'These paluwagan cycles are already completed and kept here for reference.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF285B34),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: currentGroups
                  .map((g) => _buildGroupCard(context, g, colorScheme))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (_selectedGroupTab == _HomeGroupTab.all) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9DCE4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Colors.grey.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'This view combines your active, pending, and completed groups in one place.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4E5565),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: currentGroups
                  .map((g) => _buildGroupCard(context, g, colorScheme))
                  .toList(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: currentGroups
          .map((g) => _buildGroupCard(context, g, colorScheme))
          .toList(),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    PaluwaganGroup group,
    ColorScheme colorScheme,
  ) {
    final progress = group.currentRound / group.maxMembers;
    final authVm = context.read<AuthViewModel>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(groupId: group.id),
                ),
              )
              .then((_) {
                _refreshData();
              });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                group.description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: group.groupStatus == 'active'
                          ? colorScheme.primary.withOpacity(0.08)
                          : (group.groupStatus == 'completed'
                                ? Colors.green.withOpacity(0.08)
                                : Colors.grey.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      group.groupStatus == 'active'
                          ? 'Active'
                          : (group.groupStatus == 'completed'
                                ? 'Completed'
                                : 'Pending'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: group.groupStatus == 'active'
                            ? colorScheme.primary
                            : (group.groupStatus == 'completed'
                                  ? Colors.green
                                  : Colors.grey),
                      ),
                    ),
                  ),
                  Text(
                    group.groupStatus == 'pending'
                        ? 'Waiting to Start'
                        : 'Round ${group.currentRound}/${group.maxMembers}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                minHeight: 6,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGroupStat(
                      label: 'Contribution',
                      value: '₱${group.contribution.toStringAsFixed(0)}',
                    ),
                  ),
                  Expanded(
                    child: _buildGroupStat(
                      label: 'Members',
                      value: '${group.currentMembers}/${group.maxMembers}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildGroupStat(
                      label: 'Frequency',
                      value: group.frequency,
                    ),
                  ),
                  Expanded(
                    child: _buildGroupStat(
                      label: 'Next Payout',
                      value: _formatDateShort(group.nextPayoutDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (group.createdBy == authVm.currentUser?.id)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.key, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Join Code: ${group.joinCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: group.joinCode),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupDetailScreen(groupId: group.id),
                          ),
                        )
                        .then((_) {
                          _refreshData();
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'VIEW DETAILS',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatDateWithYear(DateTime date) {
    return '${date.month} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDaysUntil(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days left';
  }
}

class _HeaderAction {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

enum _HomeGroupTab { active, pending, completed, all }
