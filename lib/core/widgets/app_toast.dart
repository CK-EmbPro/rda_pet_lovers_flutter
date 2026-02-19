import 'package:flutter/material.dart';

/// Toast types mapping to visual styles
enum ToastType { success, error, info, warning }

/// App-wide animated toast notification system.
///
/// Usage:
///   AppToast.show(context, 'Pet created!', type: ToastType.success);
class AppToast {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Close any existing toast
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          entry.remove();
          _currentToast = null;
        },
      ),
    );

    _currentToast = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case ToastType.success: return const Color(0xFF1A7A4A);
      case ToastType.error:   return const Color(0xFFB91C1C);
      case ToastType.warning: return const Color(0xFFB45309);
      case ToastType.info:    return const Color(0xFF1D4ED8);
    }
  }

  Color get _lightColor {
    switch (widget.type) {
      case ToastType.success: return const Color(0xFFDCFCE7);
      case ToastType.error:   return const Color(0xFFFFE4E6);
      case ToastType.warning: return const Color(0xFFFFF3CD);
      case ToastType.info:    return const Color(0xFFDBEAFE);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success: return Icons.check_circle_outline_rounded;
      case ToastType.error:   return Icons.error_outline_rounded;
      case ToastType.warning: return Icons.warning_amber_rounded;
      case ToastType.info:    return Icons.info_outline_rounded;
    }
  }

  String get _title {
    switch (widget.type) {
      case ToastType.success: return 'Success';
      case ToastType.error:   return 'Error';
      case ToastType.warning: return 'Warning';
      case ToastType.info:    return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _bgColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _bgColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon bubble
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _lightColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_icon, color: _bgColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _bgColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dismiss button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _lightColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: _bgColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
