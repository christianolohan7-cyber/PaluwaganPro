import 'package:flutter/material.dart';

class UIUtils {
  static void showFloatingBanner(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FloatingBanner(
        message: message,
        isError: isError,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _FloatingBanner extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _FloatingBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_FloatingBanner> createState() => _FloatingBannerState();
}

class _FloatingBannerState extends State<_FloatingBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35, // Pushed slightly higher
      left: 48,
      right: 48,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Smaller padding
                decoration: BoxDecoration(
                  // Softer, less vibrant colors
                  color: widget.isError 
                      ? const Color(0xFFFEE2E2) // Soft Red
                      : const Color(0xFFECFDF5), // Soft Green
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isError 
                        ? const Color(0xFFFECACA) 
                        : const Color(0xFFD1FAE5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: widget.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.isError ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
