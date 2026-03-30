import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'home_view.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  static const int _resendCooldownSeconds = 60;

  String? _errorMessage;
  Timer? _resendTimer;
  int _remainingResendSeconds = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authVm = context.read<AuthViewModel>();
      _syncCooldownFromLastSent(authVm.lastVerificationEmailSentAt);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  bool _isVerifying = false;

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled - but don't auto-verify to avoid race conditions
    // Let the user click the button instead, or add a small delay
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return; // Prevent double taps

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authVm = context.read<AuthViewModel>();

    try {
      final success = await authVm.verifyEmailOTP(widget.email, otp);

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: authVm.currentUser!),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = authVm.errorMessage ?? 'Invalid or expired code';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isVerifying = false;
      });
    }
  }

  void _startResendCooldown([int seconds = _resendCooldownSeconds]) {
    _resendTimer?.cancel();
    setState(() {
      _remainingResendSeconds = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingResendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingResendSeconds = 0;
        });
        return;
      }

      setState(() {
        _remainingResendSeconds--;
      });
    });
  }

  void _syncCooldownFromLastSent(DateTime? sentAt) {
    if (sentAt == null) return;

    final elapsed = DateTime.now().difference(sentAt).inSeconds;
    final remaining = _resendCooldownSeconds - elapsed;
    if (remaining > 0) {
      _startResendCooldown(remaining);
    } else {
      _resendTimer?.cancel();
      setState(() {
        _remainingResendSeconds = 0;
      });
    }
  }

  int? _extractRemainingSeconds(String? message) {
    if (message == null) return null;
    final match = RegExp(r'after\s+(\d+)\s+seconds?', caseSensitive: false)
        .firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<void> _resendCode() async {
    if (_isResending || _remainingResendSeconds > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.resendEmailOTP(widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (!success) {
        _errorMessage =
            authVm.errorMessage ?? 'Failed to resend verification code';
      }
    });

    if (success) {
      _syncCooldownFromLastSent(authVm.lastVerificationEmailSentAt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new verification code was sent to ${widget.email}'),
        ),
      );
    } else {
      final remaining = _extractRemainingSeconds(authVm.errorMessage);
      if (remaining != null && remaining > 0) {
        _startResendCooldown(remaining);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0).withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // Header Section with Logo/Icon
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 70,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Verification Code',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'We sent a 6-digit code to ${widget.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Form Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              children: [
                                // OTP Inputs
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return SizedBox(
                                      width: 42,
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                          ),
                                        ),
                                        onChanged: (value) => _onOtpChanged(value, index),
                                      ),
                                    );
                                  }),
                                ),

                                // Error Message
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFEE2E2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Color(0xFF991B1B),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: authVm.isLoading ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 4,
                                      shadowColor: colorScheme.primary.withOpacity(0.4),
                                    ),
                                    child: authVm.isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'VERIFY & REGISTER',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Resend Timer/Link
                                TextButton(
                                  onPressed: (_isResending ||
                                          authVm.isLoading ||
                                          _remainingResendSeconds > 0)
                                      ? null
                                      : _resendCode,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    _isResending
                                        ? 'SENDING...'
                                        : _remainingResendSeconds > 0
                                        ? 'RESEND CODE IN ${_remainingResendSeconds}s'
                                        : 'RESEND VERIFICATION CODE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: _remainingResendSeconds > 0
                                          ? Colors.grey.shade400
                                          : colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
