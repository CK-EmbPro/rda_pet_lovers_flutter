import 'package:flutter/material.dart';

/// Animated toast service with glassmorphism styling.
/// Provides success, error, warning, and info toasts.
class ToastService {
  static OverlayEntry? _currentOverlay;

  /// Show a success toast
  static void success(BuildContext context, String message, {String? title}) {
    _show(context, message, title: title ?? 'Success', type: _ToastType.success);
  }

  /// Show an error toast
  static void error(BuildContext context, String message, {String? title}) {
    _show(context, message, title: title ?? 'Error', type: _ToastType.error);
  }

  /// Show a warning toast
  static void warning(BuildContext context, String message, {String? title}) {
    _show(context, message, title: title ?? 'Warning', type: _ToastType.warning);
  }

  /// Show an info toast
  static void info(BuildContext context, String message, {String? title}) {
    _show(context, message, title: title ?? 'Info', type: _ToastType.info);
  }

  /// Extract user-friendly message from API error
  static String parseApiError(dynamic error) {
    if (error is Map<String, dynamic>) {
      // NestJS validation errors
      if (error['message'] is List) {
        return (error['message'] as List).join('\n');
      }
      return error['message']?.toString() ?? 'Something went wrong';
    }
    if (error is String) return error;
    return 'Something went wrong. Please try again.';
  }

  static void _show(
    BuildContext context,
    String message, {
    required String title,
    required _ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;
        },
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }
}

enum _ToastType { success, error, warning, info }

class _ToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final _ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
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
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
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
    final config = _getConfig(widget.type);
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _controller.reverse().then((_) {
                  if (mounted) widget.onDismiss();
                });
              },
              onHorizontalDragEnd: (_) {
                _controller.reverse().then((_) {
                  if (mounted) widget.onDismiss();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      config.bgColor.withValues(alpha: 0.95),
                      config.bgColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: config.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.shadowColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(config.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
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

  _ToastConfig _getConfig(_ToastType type) {
    switch (type) {
      case _ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_rounded,
          bgColor: const Color(0xFF059669),
          borderColor: const Color(0xFF34D399),
          shadowColor: const Color(0xFF059669),
        );
      case _ToastType.error:
        return _ToastConfig(
          icon: Icons.error_rounded,
          bgColor: const Color(0xFFDC2626),
          borderColor: const Color(0xFFF87171),
          shadowColor: const Color(0xFFDC2626),
        );
      case _ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_rounded,
          bgColor: const Color(0xFFD97706),
          borderColor: const Color(0xFFFBBF24),
          shadowColor: const Color(0xFFD97706),
        );
      case _ToastType.info:
        return _ToastConfig(
          icon: Icons.info_rounded,
          bgColor: const Color(0xFF2563EB),
          borderColor: const Color(0xFF60A5FA),
          shadowColor: const Color(0xFF2563EB),
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color shadowColor;

  _ToastConfig({
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.shadowColor,
  });
}
