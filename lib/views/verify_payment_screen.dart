import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/payment_proof.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class VerifyPaymentScreen extends StatefulWidget {
  const VerifyPaymentScreen({
    super.key,
    required this.paymentProof,
  });

  final PaymentProof paymentProof;

  @override
  State<VerifyPaymentScreen> createState() => _VerifyPaymentScreenState();
}

class _VerifyPaymentScreenState extends State<VerifyPaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _verifyPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final groupsVm = context.read<GroupsViewModel>();
    final authVm = context.read<AuthViewModel>();
    
    final success = await groupsVm.verifyPayment(
      widget.paymentProof,
      authVm.currentUser!.id,
    );

    setState(() {
      _isProcessing = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = groupsVm.errorMessage ?? 'Failed to verify payment';
      });
    }
  }

  Future<void> _rejectPayment() async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reject Payment', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection. This will be shown to the sender.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g., Wrong amount, blurry screenshot...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();

              setState(() {
                _isProcessing = true;
                _errorMessage = null;
              });

              final groupsVm = context.read<GroupsViewModel>();
              final success = await groupsVm.rejectPayment(
                widget.paymentProof,
                reasonController.text.trim(),
              );

              if (!mounted) return;

              setState(() {
                _isProcessing = false;
              });

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Payment rejected successfully'),
                    backgroundColor: Color(0xFFF59E0B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(this.context).pop();
              } else {
                setState(() {
                  _errorMessage = groupsVm.errorMessage ?? 'Failed to reject payment';
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final proof = widget.paymentProof;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(color: Color(0xFF1E293B)),
        title: Row(
          children: [
            Container(
              height: 28, width: 28,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF2563EB)),
                children: [
                  TextSpan(text: 'Paluwagan'),
                  TextSpan(text: 'Pro', style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Verification Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      Text(
                        '₱${proof.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Row(
                    children: [
                      _buildMemberAvatar(name: proof.senderName, userId: proof.senderId),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proof.senderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            Text('Sender', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      _buildBadge('ROUND ${proof.round}', const Color(0xFF2563EB)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Transaction Details'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.account_box_outlined, 'GCash Name', proof.gcashName),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.phone_android_outlined, 'GCash Number', proof.gcashNumber),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.receipt_long_outlined, 'Reference No.', proof.transactionNo),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.schedule_outlined, 'Submitted At', _formatDateTime(proof.submittedAt)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Transaction Screenshot'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  if (proof.screenshotPath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: proof.screenshotPath.startsWith('http')
                          ? Image.network(
                              proof.screenshotPath,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : Image.file(
                              File(proof.screenshotPath),
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            ),
                    )
                  else
                    _buildPlaceholder(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              _buildErrorMessage(_errorMessage!),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _verifyPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 4,
                  shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('VERIFY & CONFIRM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _rejectPayment,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('REJECT PAYMENT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.2),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120, width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_outlined, size: 36, color: Color(0xFFCBD5E1)),
          SizedBox(height: 6),
          Text('No screenshot available', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String msg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFEE2E2))),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar({required String name, required String userId}) {
    final groupsVm = context.read<GroupsViewModel>();
    final imageUrl = groupsVm.profileCache[userId];
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFFEEF2FF),
      backgroundImage: imageUrl != null ? (imageUrl.startsWith('http') ? NetworkImage(imageUrl) as ImageProvider : FileImage(File(imageUrl))) : null,
      child: imageUrl == null ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))) : null,
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
