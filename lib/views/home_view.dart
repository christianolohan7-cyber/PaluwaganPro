import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../models/paluwagan_group.dart';
import '../services/quote_service.dart';
import 'group_detail_view.dart';
import 'notifications_view.dart';
import 'create_group_view.dart';
import 'join_group_view.dart';
import 'profile_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user});
  final dynamic user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeContent();
      case 1:
        return const NotificationsScreen();
      case 2:
        return const CreateGroupScreen();
      case 3:
        return const JoinGroupScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeContent();
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
        centerTitle: false,
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.savings_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF2563EB),
                ),
                children: [
                  TextSpan(text: 'Paluwagan'),
                  TextSpan(
                    text: 'Pro',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home_rounded, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _NotificationBadge(
                count: notifVm.unreadCount,
                child: const Icon(Icons.notifications_none_rounded, size: 22),
              ),
              activeIcon: _NotificationBadge(
                count: notifVm.unreadCount,
                child: const Icon(Icons.notifications_rounded, size: 22),
              ),
              label: 'Notif',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded, size: 22),
              activeIcon: Icon(Icons.add_circle_rounded, size: 22),
              label: 'Create',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.group_add_outlined, size: 22),
              activeIcon: Icon(Icons.group_add_rounded, size: 22),
              label: 'Join',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              activeIcon: Icon(Icons.person_rounded, size: 22),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
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
        final groups = snapshot.data?.map((g) => PaluwaganGroup.fromMap(g)).toList() ?? groupsVm.groups;
        final activeVisibleGroups = groups.where((g) => g.groupStatus == 'active').toList();
        final pendingGroups = groups.where((g) => g.groupStatus == 'pending').toList();
        final completedGroups = groups.where((g) => g.groupStatus == 'completed').toList();

        final activeGroupsCount = activeVisibleGroups.length;
        final nextPayout = activeVisibleGroups.isNotEmpty
            ? activeVisibleGroups.map((g) => g.nextPayoutDate).reduce((a, b) => a.isBefore(b) ? a : b)
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: RefreshIndicator(
            onRefresh: () async {
              await _fetchQuote();
              await _refreshData();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kumusta, ${authVm.currentUser?.fullName.split(' ').first ?? 'Saver'}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMMM d').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: authVm.currentUser?.profilePicture != null
                              ? NetworkImage(authVm.currentUser!.profilePicture!)
                              : null,
                          child: authVm.currentUser?.profilePicture == null
                              ? Text(
                                  authVm.currentUser?.fullName[0].toUpperCase() ?? '?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildQuoteCard(colorScheme),
                  const SizedBox(height: 16),

                  _buildHighlightedSummaryCards(
                    context,
                    activeGroupsCount,
                    activeVisibleGroups,
                    nextPayout,
                    colorScheme,
                  ),
                  const SizedBox(height: 24),

                  // Filter Groups Title
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF1E293B)),
                        SizedBox(width: 8),
                        Text(
                          'Filter Groups',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Browser-style Tabs Row
                  SizedBox(
                    height: 54,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBrowserTab(
                          icon: Icons.grid_view_rounded,
                          label: 'All',
                          isSelected: _selectedGroupTab == _HomeGroupTab.all,
                          color: const Color(0xFF6366F1),
                          onTap: () => setState(() => _selectedGroupTab = _HomeGroupTab.all),
                        ),
                        _buildBrowserTab(
                          icon: Icons.bolt_rounded,
                          label: 'Active',
                          count: activeVisibleGroups.length,
                          isSelected: _selectedGroupTab == _HomeGroupTab.active,
                          color: colorScheme.primary,
                          onTap: () => setState(() => _selectedGroupTab = _HomeGroupTab.active),
                        ),
                        _buildBrowserTab(
                          icon: Icons.hourglass_top_rounded,
                          label: 'Pending',
                          count: pendingGroups.length,
                          isSelected: _selectedGroupTab == _HomeGroupTab.pending,
                          color: const Color(0xFFF59E0B),
                          onTap: () => setState(() => _selectedGroupTab = _HomeGroupTab.pending),
                        ),
                        _buildBrowserTab(
                          icon: Icons.task_alt_rounded,
                          label: 'History',
                          count: completedGroups.length,
                          isSelected: _selectedGroupTab == _HomeGroupTab.completed,
                          color: const Color(0xFF10B981),
                          onTap: () => setState(() => _selectedGroupTab = _HomeGroupTab.completed),
                        ),
                      ],
                    ),
                  ),

                  // Content Container - Merged with Tabs
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(0),
                      ),
                      border: Border.all(
                        color: _getTabColor(_selectedGroupTab, colorScheme).withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getTabColor(_selectedGroupTab, colorScheme).withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getTabColor(_selectedGroupTab, colorScheme).withValues(alpha: 0.02),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                        ),
                      ),
                      child: _buildCurrentTabContent(
                        context,
                        colorScheme,
                        groupsVm,
                        activeVisibleGroups: activeVisibleGroups,
                        pendingGroups: pendingGroups,
                        completedGroups: completedGroups,
                      ),
                    ),
                  ),                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrowserTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    int? count,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: isSelected ? 54 : 46,
          decoration: isSelected 
            ? ShapeDecoration(
                color: color,
                shape: const _BrowserTabShape(),
                shadows: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              )
            : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSelected ? 18 : 16,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              if (count != null && isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.format_quote_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAILY MOTIVATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _quote,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF475569),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    final startedGroups = groups.where((g) => g.groupStatus == 'active').toList();

    if (startedGroups.isNotEmpty) {
      final minDate = startedGroups.map((g) => g.nextPayoutDate).reduce((a, b) => a.isBefore(b) ? a : b);
      nearestGroup = startedGroups.firstWhere((g) => g.nextPayoutDate == minDate, orElse: () => startedGroups.first);
      nextPayout = minDate;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeGroups.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Associations',
                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT PAYOUT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                if (nearestGroup != null && nextPayout != null) ...[
                  Text(
                    DateFormat('MMM d').format(nextPayout),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _getDaysUntil(nextPayout),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'None',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const Text(
                    'Waiting...',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTabColor(_HomeGroupTab tab, ColorScheme colorScheme) {
    switch (tab) {
      case _HomeGroupTab.active:
        return colorScheme.primary;
      case _HomeGroupTab.pending:
        return const Color(0xFFF59E0B);
      case _HomeGroupTab.completed:
        return const Color(0xFF10B981);
      case _HomeGroupTab.all:
        return const Color(0xFF6366F1);
    }
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

    if (groupsVm.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (currentGroups.isEmpty) {
      return _buildEmptyState(_selectedGroupTab, colorScheme);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentGroups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(context, currentGroups[index], colorScheme);
      },
    );
  }

  Widget _buildEmptyState(_HomeGroupTab tab, ColorScheme colorScheme) {
    IconData icon;
    String title;
    String subtitle;
    Color color;

    switch (tab) {
      case _HomeGroupTab.active:
        icon = Icons.bolt_rounded;
        title = 'No Active Groups';
        subtitle = 'No associations running.';
        color = colorScheme.primary;
        break;
      case _HomeGroupTab.pending:
        icon = Icons.hourglass_empty_rounded;
        title = 'No Pending Groups';
        subtitle = 'Waiting-to-start groups.';
        color = const Color(0xFFF59E0B);
        break;
      case _HomeGroupTab.completed:
        icon = Icons.task_alt_rounded;
        title = 'No History';
        subtitle = 'Finished cycles.';
        color = const Color(0xFF10B981);
        break;
      case _HomeGroupTab.all:
        icon = Icons.group_off_rounded;
        title = 'No Associations';
        subtitle = 'Get started today!';
        color = const Color(0xFF6366F1);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    PaluwaganGroup group,
    ColorScheme colorScheme,
  ) {
    final progress = group.maxMembers > 0 ? (group.currentRound / group.maxMembers) : 0.0;
    final isPending = group.groupStatus == 'pending';
    final isCompleted = group.groupStatus == 'completed';
    
    Color statusColor = isPending ? const Color(0xFFF59E0B) : (isCompleted ? const Color(0xFF10B981) : colorScheme.primary);
    String statusLabel = isPending ? 'Pending' : (isCompleted ? 'Completed' : 'Active');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)))
                .then((_) => _refreshData());
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuickStat(Icons.payments_outlined, '₱${group.contribution.toStringAsFixed(0)}'),
                    const SizedBox(width: 12),
                    _buildQuickStat(Icons.people_outline, '${group.currentMembers}/${group.maxMembers}'),
                    const SizedBox(width: 12),
                    _buildQuickStat(Icons.calendar_today_outlined, group.frequency),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPending ? 'Waiting to start' : 'Round ${group.currentRound} of ${group.maxMembers}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.event_available_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${DateFormat('MMM d').format(group.nextPayoutDate)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade300),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  String _getDaysUntil(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days left';
  }
}

enum _HomeGroupTab { active, pending, completed, all }

// Custom shape for Browser Tabs
class _BrowserTabShape extends ShapeBorder {
  const _BrowserTabShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {ui.TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {ui.TextDirection? textDirection}) {
    final double radius = 12.0;
    final double shoulderRadius = 14.0;
    
    return Path()
      ..moveTo(rect.left - 4, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left + 2, rect.bottom - 4)
      ..lineTo(rect.left + radius, rect.top + radius)
      ..quadraticBezierTo(rect.left + radius + 4, rect.top, rect.left + radius + shoulderRadius, rect.top)
      ..lineTo(rect.right - radius - shoulderRadius, rect.top)
      ..quadraticBezierTo(rect.right - radius - 4, rect.top, rect.right - radius, rect.top + radius)
      ..lineTo(rect.right - 2, rect.bottom - 4)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right + 4, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {ui.TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
