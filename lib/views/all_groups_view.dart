import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/paluwagan_group.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../utils/ui_utils.dart';
import 'group_detail_view.dart';

class AllGroupsPage extends StatelessWidget {
  const AllGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GroupsCollectionPage(
      title: 'My Paluwagan Groups',
      showCompletedOnly: false,
      emptyTitle: 'No Groups Found',
      emptySubtitle: 'Create or join a group to get started',
    );
  }
}

class CompletedGroupsPage extends StatelessWidget {
  const CompletedGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GroupsCollectionPage(
      title: 'Completed Groups',
      showCompletedOnly: true,
      emptyTitle: 'No Completed Groups',
      emptySubtitle: 'Completed paluwagan cycles will appear here.',
    );
  }
}

class _GroupsCollectionPage extends StatelessWidget {
  const _GroupsCollectionPage({
    required this.title,
    required this.showCompletedOnly,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final bool showCompletedOnly;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();
    final groupsVm = context.watch<GroupsViewModel>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupsVm.streamGroups(authVm.currentUser!.id),
      builder: (context, snapshot) {
        final allGroups =
            snapshot.data?.map((g) => PaluwaganGroup.fromMap(g)).toList() ??
            groupsVm.groups;
        final groups = allGroups
            .where(
              (g) => showCompletedOnly
                  ? g.groupStatus == 'completed'
                  : g.groupStatus != 'completed',
            )
            .toList();
        final hasCompletedGroups = allGroups.any(
          (g) => g.groupStatus == 'completed',
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            actions: showCompletedOnly
                ? null
                : [
                    IconButton(
                      tooltip: 'Completed Groups',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CompletedGroupsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.inventory_2_outlined, size: 20),
                    ),
                  ],
            bottom: groups.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 1,
                    ),
                  )
                : null,
          ),
          body: groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.group_off,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptySubtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (!showCompletedOnly) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/create-group');
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/join-group');
                              },
                              icon: const Icon(Icons.group_add, size: 18),
                              label: const Text('Join', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        if (hasCompletedGroups) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CompletedGroupsPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                            label: const Text('View Completed Groups', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    final isCreator = g.createdBy == authVm.currentUser?.id;
                    final progress = g.currentRound / g.maxMembers;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Group Name
                            Text(
                              g.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Text(
                              g.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 10),

                            // Creator/Member & Status Badges
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCreator
                                        ? colorScheme.primary.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isCreator ? 'Creator' : 'Member',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isCreator
                                          ? colorScheme.primary
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: g.groupStatus == 'active'
                                        ? colorScheme.primary.withValues(alpha: 0.08)
                                        : (g.groupStatus == 'completed'
                                            ? Colors.green.withValues(alpha: 0.08)
                                            : Colors.grey.withValues(alpha: 0.08)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    g.groupStatus == 'active'
                                        ? 'Active'
                                        : (g.groupStatus == 'completed' ? 'Completed' : 'Pending'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: g.groupStatus == 'active'
                                          ? colorScheme.primary
                                          : (g.groupStatus == 'completed' ? Colors.green : Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      g.groupStatus == 'pending'
                                          ? 'Waiting to Start'
                                          : 'Round ${g.currentRound}/${g.maxMembers}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.primary,
                                  ),
                                  minHeight: 5,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Stats in 2x2 grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStat(
                                    label: 'Contribution',
                                    value:
                                        '₱${g.contribution.toStringAsFixed(0)}',
                                  ),
                                ),
                                Expanded(
                                  child: _buildStat(
                                    label: 'Members',
                                    value: '${g.currentMembers}/${g.maxMembers}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStat(
                                    label: 'Frequency',
                                    value: g.frequency,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStat(
                                    label: 'Next Payout',
                                    value: _formatDateShort(g.nextPayoutDate),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Join Code (if creator)
                            if (isCreator) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.key,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Join Code: ${g.joinCode}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: g.joinCode),
                                        );
                                        if (!context.mounted) return;
                                        UIUtils.showFloatingBanner(context, 'Code copied to clipboard');
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // View Details Button
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GroupDetailScreen(groupId: g.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'VIEW DETAILS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
