import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/ui_utils.dart';
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
      UIUtils.showFloatingBanner(context, 'Please enter all 6 digits', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authVm = context.read<AuthViewModel>();

    try {
      final success = await authVm.verifyEmailOTP(widget.email, otp);

      if (success && mounted) {
        UIUtils.showFloatingBanner(context, 'Email verified successfully!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: authVm.currentUser!),
          ),
          (route) => false,
        );
      } else {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
          UIUtils.showFloatingBanner(
            context,
            authVm.errorMessage ?? 'Invalid or expired code',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        UIUtils.showFloatingBanner(context, 'An error occurred. Please try again.', isError: true);
      }
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
    });

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.resendEmailOTP(widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    if (success) {
      _syncCooldownFromLastSent(authVm.lastVerificationEmailSentAt);
      UIUtils.showFloatingBanner(context, 'A new verification code was sent to ${widget.email}');
    } else {
      UIUtils.showFloatingBanner(
        context,
        authVm.errorMessage ?? 'Failed to resend verification code',
        isError: true,
      );
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
              const Color(0xFFE2E8F0).withValues(alpha: 0.5),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Header Section with Logo/Icon
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 50,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Verification Code',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'We sent a 6-digit code to ${widget.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
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
                                      width: 38,
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                          ),
                                        ),
                                        onChanged: (value) => _onOtpChanged(value, index),
                                      ),
                                    );
                                  }),
                                ),

                                const SizedBox(height: 24),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authVm.isLoading ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 3,
                                      shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                                    ),
                                    child: authVm.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'VERIFY & REGISTER',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Resend Timer/Link
                                TextButton(
                                  onPressed: (_isResending ||
                                          authVm.isLoading ||
                                          _remainingResendSeconds > 0)
                                      ? null
                                      : _resendCode,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  ),
                                  child: Text(
                                    _isResending
                                        ? 'SENDING...'
                                        : _remainingResendSeconds > 0
                                        ? 'RESEND CODE IN ${_remainingResendSeconds}s'
                                        : 'RESEND VERIFICATION CODE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
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
                          const SizedBox(height: 32),
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
