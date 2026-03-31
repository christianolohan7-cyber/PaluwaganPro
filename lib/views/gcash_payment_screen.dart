import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/paluwagan_group.dart';
import '../models/contribution.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/ui_utils.dart';

class GcashPaymentScreen extends StatefulWidget {
  const GcashPaymentScreen({
    super.key,
    required this.group,
    required this.contribution,
    required this.round,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
  });

  final PaluwaganGroup group;
  final Contribution contribution;
  final int round;
  final String recipientId;
  final String recipientName;
  final double amount;

  @override
  State<GcashPaymentScreen> createState() => _GcashPaymentScreenState();
}

class _GcashPaymentScreenState extends State<GcashPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gcashNameController = TextEditingController();
  final _gcashNumberController = TextEditingController();
  final _transactionNoController = TextEditingController();

  String? recipientGcashName;
  String? recipientGcashNumber;
  String? recipientQrPath;

  String? _screenshotPath;
  String? _screenshotFilename;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadRecipientInfo();
  }

  Future<void> _loadRecipientInfo() async {
    try {
      final groupsVm = context.read<GroupsViewModel>();
      final user = await groupsVm.getUserById(widget.recipientId);

      setState(() {
        recipientGcashName = user?.fullName ?? widget.recipientName;
        recipientGcashNumber = user?.gcashNumber ?? '';
        recipientQrPath = user?.urcodePath ?? '';
      });
    } catch (e) {
      setState(() {
        recipientGcashName = widget.recipientName;
        recipientGcashNumber = '';
        recipientQrPath = '';
      });
    }
  }

  @override
  void dispose() {
    _gcashNameController.dispose();
    _gcashNumberController.dispose();
    _transactionNoController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _screenshotPath = image.path;
          _screenshotFilename = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showFloatingBanner(context, 'Failed to pick image: $e', isError: true);
      }
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_screenshotPath == null) {
      UIUtils.showFloatingBanner(context, 'Please upload transaction screenshot', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final groupsVm = context.read<GroupsViewModel>();
    final authVm = context.read<AuthViewModel>();

    final success = await groupsVm.submitPaymentProof(
      groupId: widget.group.id,
      contributionId: widget.contribution.id,
      senderId: authVm.currentUser!.id,
      senderName: authVm.currentUser!.fullName,
      recipientId: widget.recipientId,
      recipientName: widget.recipientName,
      round: widget.round,
      gcashName: _gcashNameController.text.trim(),
      gcashNumber: _gcashNumberController.text.trim(),
      transactionNo: _transactionNoController.text.trim(),
      screenshotPath: _screenshotPath!,
      amount: widget.amount,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Payment Submitted!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'Your payment for Round ${widget.round} has been submitted and is pending verification by ${widget.recipientName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
    } else {
      UIUtils.showFloatingBanner(
        context,
        groupsVm.errorMessage ?? 'Failed to submit payment',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              height: 24, width: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Color(0xFF2563EB)),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Recipient Information'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.payments_outlined, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount to Pay', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('₱${widget.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                        _buildBadge('ROUND ${widget.round}', const Color(0xFF2563EB)),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Send GCash To:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(recipientGcashName ?? widget.recipientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                              Text(recipientGcashNumber ?? 'Loading...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 32,
                          child: TextButton.icon(
                            onPressed: () => _viewRecipientQr(),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 14),
                            label: const Text('VIEW QR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('Your Payment Details'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _gcashNameController,
                      label: 'GCash Registered Name',
                      icon: Icons.account_box_outlined,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter your GCash name' : null,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _gcashNumberController,
                      label: 'GCash Number',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.trim().length < 11 ? 'Enter valid GCash number' : null,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _transactionNoController,
                      label: 'Transaction Reference No.',
                      icon: Icons.receipt_long_outlined,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter reference number' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('Upload Transaction Proof'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    if (_screenshotPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_screenshotPath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 10),
                      Text(_screenshotFilename ?? 'Screenshot selected', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _pickScreenshot,
                        icon: const Icon(Icons.change_circle_outlined, size: 16),
                        label: const Text('CHANGE SCREENSHOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                      ),
                    ] else
                      InkWell(
                        onTap: _pickScreenshot,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text('Tap to upload GCash receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 3,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('SUBMIT PAYMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.2)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 16),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      ),
      validator: validator,
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  void _viewRecipientQr() {
    if (recipientQrPath != null && recipientQrPath!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('InstaPay QR Code', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: recipientQrPath!.startsWith('http')
                  ? Image.network(recipientQrPath!, fit: BoxFit.contain)
                  : Image.file(File(recipientQrPath!), fit: BoxFit.contain),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
      );
    } else {
      UIUtils.showFloatingBanner(context, 'QR Code not available', isError: true);
    }
  }
}

