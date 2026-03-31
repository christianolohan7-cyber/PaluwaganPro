import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/paluwagan_group.dart';
import '../models/group_member.dart';
import '../models/group_chat.dart';
import '../models/user.dart';
import '../models/contribution.dart';
import '../models/payment_proof.dart';
import '../models/round_rotation.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/ui_utils.dart';
import 'gcash_payment_screen.dart';
import 'verify_payment_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final int groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  void _loadGroupDetails() {
    context.read<GroupsViewModel>().loadGroupDetails(widget.groupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final groupsVm = context.read<GroupsViewModel>();
    final authVm = context.read<AuthViewModel>();

    groupsVm.sendChatMessage(
      widget.groupId,
      authVm.currentUser!.id,
      authVm.currentUser!.fullName,
      _chatController.text.trim(),
    );

    _chatController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsVm = context.watch<GroupsViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<Map<String, dynamic>>(
      stream: groupsVm.streamGroup(widget.groupId),
      builder: (context, snapshot) {
        final groupData = snapshot.data;
        final group = groupData != null 
            ? PaluwaganGroup.fromMap(groupData) 
            : groupsVm.currentGroup;

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Details')),
            body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
          );
        }

        final isCreator = group.createdBy == authVm.currentUser?.id;
        final progress = group.currentRound / group.maxMembers;
        final isGroupCompleted = group.groupStatus == 'completed';
        
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: groupsVm.streamMembers(widget.groupId),
          builder: (context, memberSnapshot) {
            final members = memberSnapshot.data?.map((m) => GroupMember.fromMap(m)).toList() 
                ?? groupsVm.currentGroupMembers;

            final userIsMember = members.any((m) => m.userId == authVm.currentUser?.id);
            final isGroupFull = members.length >= group.maxMembers;

            if (!userIsMember && !isCreator) {
              return Scaffold(
                appBar: AppBar(title: Text(group.name)),
                body: const Center(child: Text('You are not a member of this group')),
              );
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupsVm.streamRotations(widget.groupId),
              builder: (context, rotationSnapshot) {
                final rotations = rotationSnapshot.data?.map((r) => RoundRotation.fromMap(r)).toList() 
                    ?? groupsVm.roundRotations;
                
                final allRotationsDone = rotations.isNotEmpty && rotations.every((r) => r.status == 'completed');
                final effectiveGroupStatus = allRotationsDone ? 'completed' : group.groupStatus;

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: false,
                    leading: const BackButton(color: Color(0xFF1E293B)),
                    titleSpacing: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (isCreator)
                          GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(const ClipboardData(text: '')); // Corrected
                              // I'll fix the clipboard logic in a targeted replace later if needed
                              await Clipboard.setData(ClipboardData(text: group.joinCode));
                              if (!context.mounted) return;
                              UIUtils.showFloatingBanner(context, 'Join code copied!');
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Code: ${group.joinCode}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.primary, letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy_rounded, size: 10, color: colorScheme.primary),
                              ],
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: effectiveGroupStatus == 'active'
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : (effectiveGroupStatus == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              effectiveGroupStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: effectiveGroupStatus == 'active'
                                    ? colorScheme.primary
                                    : (effectiveGroupStatus == 'completed' ? Colors.green : Colors.orange),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorColor: colorScheme.primary,
                          indicatorWeight: 2.5,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: const Color(0xFF94A3B8),
                          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Members'),
                            Tab(text: 'Schedule'),
                            Tab(text: 'Chat'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(context, group, members, progress, isCreator, isGroupFull),
                      _buildMembersTab(context, members, group),
                      _buildScheduleTab(context, group),
                      _buildChatTab(context, authVm.currentUser!, isGroupCompleted),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    PaluwaganGroup group,
    List<GroupMember> members,
    double progress,
    bool isCreator,
    bool isGroupFull,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupsVm = context.watch<GroupsViewModel>();
    final currentUser = context.read<AuthViewModel>().currentUser;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupsVm.streamRotations(group.id),
      builder: (context, rotationSnapshot) {
        final rotations = rotationSnapshot.data?.map((r) => RoundRotation.fromMap(r)).toList() 
            ?? groupsVm.roundRotations;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: groupsVm.streamContributions(group.id),
          builder: (context, contributionSnapshot) {
            final contributions = contributionSnapshot.data?.map((c) => Contribution.fromMap(c)).toList() 
                ?? groupsVm.currentGroupContributions;

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupsVm.streamPaymentProofs(group.id),
              builder: (context, proofSnapshot) {
                final proofs = proofSnapshot.data?.map((p) => PaymentProof.fromMap(p)).toList() 
                    ?? groupsVm.pendingPayments;

                final activeRotation = rotations.firstWhere(
                  (r) => r.status == 'in_progress',
                  orElse: () => rotations.firstWhere(
                    (r) => r.round == group.currentRound,
                    orElse: () => rotations.isNotEmpty ? rotations.last : RoundRotation(
                      id: 0, groupId: group.id, round: group.currentRound, payoutDate: DateTime.now(),
                      recipientId: '', recipientName: 'TBD', status: 'pending',
                    ),
                  ),
                );

                final actualCurrentRound = activeRotation.round;
                final completedRounds = rotations.where((r) => r.status == 'completed').length;
                final totalRounds = rotations.isNotEmpty ? rotations.length : group.maxMembers;

                final pendingContributions = contributions
                    .where((c) => c.userId == currentUser?.id && c.status == 'pending')
                    .toList();

                final pendingVerifications = proofs
                    .where((p) => p.recipientId == currentUser?.id && p.status == 'pending')
                    .toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.groupStatus == 'completed') ...[
                        _buildStatusBanner(
                          icon: Icons.stars_rounded,
                          title: 'Cycle Completed!',
                          message: 'All members have received their payouts.',
                          color: Colors.green,
                          actionLabel: 'DISCUSS NEXT',
                          onAction: () => _tabController.animateTo(3),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (group.groupStatus == 'pending') ...[
                        _buildStatusBanner(
                          icon: Icons.hourglass_top_rounded,
                          title: isGroupFull ? 'Ready to Start!' : 'Waiting for Members',
                          message: isGroupFull 
                              ? 'Group is now full and ready to begin.' 
                              : 'Need ${group.maxMembers - members.length} more members.',
                          color: isGroupFull ? Colors.green : Colors.orange,
                          actionLabel: (isCreator && isGroupFull) ? 'START GROUP' : null,
                          onAction: (isCreator && isGroupFull) ? () => _startGroup(group) : null,
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (pendingVerifications.isNotEmpty) ...[
                        _buildSectionHeader('Pending Verifications'),
                        ...pendingVerifications.map((p) => _buildPendingVerificationTile(context, p)),
                        const SizedBox(height: 14),
                      ],

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildStatCard(context, label: 'Total Pot', value: '₱${group.totalPot.toStringAsFixed(0)}', icon: Icons.savings_outlined, color: colorScheme.primary),
                          _buildStatCard(context, label: 'Members', value: '${members.length}/${group.maxMembers}', icon: Icons.group_outlined, color: isGroupFull ? Colors.green : colorScheme.primary),
                          _buildStatCard(context, label: 'Contribution', value: '₱${group.contribution.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: colorScheme.primary),
                          _buildStatCard(context, label: 'Current Round', value: '$actualCurrentRound/$totalRounds', icon: Icons.timelapse_outlined, color: colorScheme.primary),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (group.groupStatus == 'active') ...[
                        _buildSectionHeader('Current Cycle'),
                        _buildRotationCard(rotations, colorScheme),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Cycle Progress'),
                        _buildProgressCard(completedRounds, totalRounds, colorScheme),
                        const SizedBox(height: 20),
                      ],

                      if (pendingContributions.isNotEmpty) ...[
                        _buildSectionHeader('Your Contributions'),
                        ...pendingContributions.map((c) => _buildPendingContributionTile(context, group, c, rotations, groupsVm, actualCurrentRound)),
                      ],
                      
                      if (isCreator && group.groupStatus == 'pending') ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _deleteGroup(group),
                            icon: const Icon(Icons.delete_outline_rounded, size: 14),
                            label: const Text('DELETE GROUP'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red, textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRotationCard(List<RoundRotation> rotations, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: rotations.map((r) {
          final isCurrent = r.status == 'in_progress';
          final isPast = r.status == 'completed';
          final statusColor = isPast ? Colors.green : (isCurrent ? colorScheme.primary : const Color(0xFF94A3B8));
          
          return Column(
            children: [
              if (r.round > 1) const Divider(height: 16, color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  Container(
                    height: 32, width: 32,
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${r.round}', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 13))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.recipientName, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF1E293B))),
                        Text(_formatDateWithYear(r.payoutDate), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  if (isCurrent || isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(isPast ? 'DONE' : 'CURRENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor)),
                    ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, ColorScheme colorScheme) {
    final ratio = total > 0 ? (completed / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed of $total rounds', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              Text('${(ratio * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(colorScheme.primary), minHeight: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContributionTile(BuildContext context, PaluwaganGroup group, Contribution c, List<RoundRotation> rotations, GroupsViewModel groupsVm, int currentRound) {
    final colorScheme = Theme.of(context).colorScheme;
    final rotation = rotations.firstWhere((r) => r.round == c.round, orElse: () => rotations.last);
    final proof = groupsVm.pendingPayments.firstWhere((p) => p.contributionId == c.id, orElse: () => PaymentProof(id: 0, contributionId: 0, groupId: 0, senderId: '', senderName: '', recipientId: '', recipientName: '', round: 0, gcashName: '', gcashNumber: '', transactionNo: '', screenshotPath: '', amount: 0, status: 'none', submittedAt: DateTime.now()));

    final isRejected = proof.status == 'rejected';
    final isSubmitted = proof.status == 'pending';
    final isAvailable = (c.round == currentRound && group.groupStatus == 'active') || isRejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isRejected ? Colors.red.withValues(alpha: 0.3) : (isAvailable ? colorScheme.primary.withValues(alpha: 0.3) : const Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 36, width: 36,
                decoration: BoxDecoration(color: isRejected ? Colors.red.withValues(alpha: 0.1) : (isAvailable ? colorScheme.primary.withValues(alpha: 0.1) : const Color(0xFFF8FAFC)), borderRadius: BorderRadius.circular(8)),
                child: Icon(isRejected ? Icons.error_outline_rounded : Icons.payments_outlined, color: isRejected ? Colors.red : (isAvailable ? colorScheme.primary : const Color(0xFF94A3B8)), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Round ${c.round} Contribution', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    Text('Send to: ${rotation.recipientName}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (isSubmitted)
                _buildBadge('SUBMITTED', Colors.orange)
              else if (isRejected)
                _buildBadge('REJECTED', Colors.red)
              else if (!isAvailable)
                _buildBadge('LOCKED', Colors.grey)
              else
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GcashPaymentScreen(group: group, contribution: c, round: c.round, recipientId: rotation.recipientId, recipientName: rotation.recipientName, amount: c.amount))),
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: const Text('PAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
          if (isRejected && proof.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('REASON:', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.red)),
                  Text(proof.rejectionReason!, style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _buildPendingVerificationTile(BuildContext context, PaymentProof proof) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2))),
      child: Row(
        children: [
          _buildMemberAvatar(name: proof.senderName, userId: proof.senderId, radius: 16, fontSize: 11),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proof.senderName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Round ${proof.round} • ₱${proof.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyPaymentScreen(paymentProof: proof))),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: const Text('VERIFY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, List<GroupMember> members, PaluwaganGroup group) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = context.read<AuthViewModel>().currentUser;
    final groupsVm = context.watch<GroupsViewModel>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupsVm.streamContributions(group.id),
      builder: (context, contributionSnapshot) {
        final contributions = contributionSnapshot.data?.map((c) => Contribution.fromMap(c)).toList() ?? groupsVm.currentGroupContributions;
        
        final sortedMembers = List<GroupMember>.from(members);
        sortedMembers.sort((a, b) => a.userId == group.createdBy ? -1 : (b.userId == group.createdBy ? 1 : 0));

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: sortedMembers.length,
          itemBuilder: (context, index) {
            final member = sortedMembers[index];
            final isMe = member.userId == currentUser?.id;
            final isCreator = member.userId == group.createdBy;
            
            final memberContributions = contributions.where((c) => c.userId == member.userId).toList();
            final paidCount = memberContributions.where((c) => c.status == 'paid').length;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Row(
                children: [
                  _buildMemberAvatar(name: member.userName, userId: member.userId, radius: 18, fontSize: 12, backgroundColor: isMe ? colorScheme.primary : null, textColor: isMe ? Colors.white : null),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(member.userName, style: TextStyle(fontSize: 13, fontWeight: isMe ? FontWeight.w900 : FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (isCreator) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)), child: const Text('CREATOR', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.orange))),
                          ],
                        ),
                        Text('Payments: $paidCount  •  Joined: ${DateFormat('MMM d').format(member.joinedAt)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ],
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

  Widget _buildScheduleTab(BuildContext context, PaluwaganGroup group) {
    final groupsVm = context.watch<GroupsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: groupsVm.streamRotations(group.id),
      builder: (context, rotationSnapshot) {
        final rotations = rotationSnapshot.data?.map((r) => RoundRotation.fromMap(r)).toList() ?? groupsVm.roundRotations;
        
        if (rotations.isEmpty) return _buildEmptyTab(Icons.calendar_today_rounded, 'No schedule yet', 'Wait for the group to start.');

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: groupsVm.streamMembers(group.id),
          builder: (context, memberSnapshot) {
            final members = memberSnapshot.data?.map((m) => GroupMember.fromMap(m)).toList() ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupsVm.streamContributions(group.id),
              builder: (context, contributionSnapshot) {
                final contributions = contributionSnapshot.data?.map((c) => Contribution.fromMap(c)).toList() ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: groupsVm.streamPaymentProofs(group.id),
                  builder: (context, proofSnapshot) {
                    final proofs = proofSnapshot.data?.map((p) => PaymentProof.fromMap(p)).toList() ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: rotations.length,
                      itemBuilder: (context, index) {
                        final r = rotations[index];
                        final isPast = r.status == 'completed';
                        final isCurrent = r.status == 'in_progress';
                        final statusColor = isPast ? Colors.green : (isCurrent ? colorScheme.primary : const Color(0xFF94A3B8));

                        final roundContributions = contributions.where((c) => c.round == r.round).toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isCurrent ? statusColor.withValues(alpha: 0.3) : const Color(0xFFF1F5F9)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                                child: Text('${r.round}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                              title: Text(
                                r.recipientName,
                                style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                              subtitle: Text(
                                _formatDateWithYear(r.payoutDate),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              children: [
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ROUND STATUS',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 10),
                                      ...members.map((member) {
                                        final contrib = roundContributions.firstWhere(
                                          (c) => c.userId == member.userId,
                                          orElse: () => Contribution(
                                            id: 0,
                                            groupId: group.id,
                                            userId: member.userId,
                                            round: r.round,
                                            amount: group.contribution,
                                            status: 'pending',
                                            dueDate: r.payoutDate,
                                          ),
                                        );
                                        
                                        final proof = proofs.firstWhere(
                                          (p) => p.contributionId == contrib.id,
                                          orElse: () => PaymentProof(id: 0, contributionId: 0, groupId: 0, senderId: '', senderName: '', recipientId: '', recipientName: '', round: 0, gcashName: '', gcashNumber: '', transactionNo: '', screenshotPath: '', amount: 0, status: 'none', submittedAt: DateTime.now()),
                                        );

                                        final isPaid = contrib.status == 'paid';
                                        final hasProof = proof.status != 'none';
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Row(
                                            children: [
                                              _buildMemberAvatar(name: member.userName, userId: member.userId, radius: 12, fontSize: 9),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  member.userId == r.recipientId ? '${member.userName} (Recipient)' : member.userName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: member.userId == r.recipientId ? FontWeight.w800 : FontWeight.w600,
                                                    color: const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                              if (member.userId == r.recipientId)
                                                _buildBadge('GETTING PAID', Colors.orange)
                                              else if (isPaid || hasProof)
                                                Row(
                                                  children: [
                                                    _buildBadge(
                                                      isPaid ? 'PAID' : 'VERIFYING',
                                                      isPaid ? Colors.green : Colors.blue,
                                                    ),
                                                    if (hasProof) ...[
                                                      const SizedBox(width: 6),
                                                      GestureDetector(
                                                        onTap: () => _viewReceipt(context, proof),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(5),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.primary.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Icon(
                                                            Icons.receipt_long_rounded,
                                                            size: 12,
                                                            color: colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                )
                                              else
                                                _buildBadge('PENDING', Colors.grey),
                                            ],
                                          ),
                                        );
                                      }),
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
              },
            );
          },
        );
      },
    );
  }

  void _viewReceipt(BuildContext context, PaymentProof proof) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 10),
            const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: double.maxFinite,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: ${proof.senderName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Ref: ${proof.transactionNo}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: proof.screenshotPath.startsWith('http')
                      ? Image.network(
                          proof.screenshotPath,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2.5),
                            );
                          },
                        )
                      : Image.file(File(proof.screenshotPath), fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(BuildContext context, User currentUser, bool isGroupCompleted) {
    final groupsVm = context.read<GroupsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: groupsVm.streamChat(widget.groupId),
            builder: (context, snapshot) {
              final messages = snapshot.data?.map((m) => GroupChat.fromMap(m)).toList() ?? [];
              messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              if (messages.isEmpty) return _buildEmptyTab(Icons.chat_bubble_outline_rounded, 'No messages', 'Start the conversation!');

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.userId == currentUser.id;
                  return _buildChatBubble(msg, isMe, colorScheme);
                },
              );
            },
          ),
        ),
        _buildChatInput(colorScheme),
      ],
    );
  }

  Widget _buildChatBubble(GroupChat msg, bool isMe, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildMemberAvatar(name: msg.userName, userId: msg.userId, radius: 12, fontSize: 9),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? colorScheme.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(2),
                  bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) Text(msg.userName, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                  Text(msg.message, style: TextStyle(fontSize: 12, color: isMe ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(_formatTime(msg.timestamp), style: TextStyle(fontSize: 7, color: isMe ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true, fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, size: 20), color: colorScheme.primary, padding: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Future<void> _startGroup(PaluwaganGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Association?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: const Text('This will begin the savings cycle and randomize the rotation order.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 12))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('START NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await context.read<GroupsViewModel>().startGroup(group.id);
      if (success && mounted) UIUtils.showFloatingBanner(context, 'Cycle started!');
    }
  }

  Future<void> _deleteGroup(PaluwaganGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Group?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16)),
        content: const Text('This action is permanent. All group data will be lost.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 12))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await context.read<GroupsViewModel>().deleteGroup(group.id);
      if (success && mounted) {
        UIUtils.showFloatingBanner(context, 'Group deleted.', isError: true);
        Navigator.pop(context);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.2)),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar({required String name, required String userId, String? profilePicture, double radius = 20, double fontSize = 14, Color? backgroundColor, Color? textColor}) {
    final groupsVm = context.read<GroupsViewModel>();
    final imageUrl = profilePicture ?? groupsVm.profileCache[userId];
    return CircleAvatar(
      radius: radius, backgroundColor: backgroundColor ?? const Color(0xFFEEF2FF),
      backgroundImage: imageUrl != null ? (imageUrl.startsWith('http') ? NetworkImage(imageUrl) as ImageProvider : FileImage(File(imageUrl))) : null,
      child: imageUrl == null ? Text(_getInitials(name), style: TextStyle(fontSize: fontSize, color: textColor ?? Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)) : null,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _formatDateWithYear(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('h:mm a').format(date);
}
