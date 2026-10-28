import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';

class TopNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext? context, {
    required String title,
    required String body,
    String? timeAgo,
    IconData? icon,
    Color? iconBgColor,
    VoidCallback? onTap,
  }) {
    showBanner(
      context: context,
      title: title,
      body: body,
      timeAgo: timeAgo,
      icon: icon,
      iconBgColor: iconBgColor,
      onTap: onTap,
    );
  }

  static void showBanner({
    BuildContext? context,
    required String title,
    required String body,
    String? timeAgo,
    IconData? icon,
    Color? iconBgColor,
    VoidCallback? onTap,
  }) {
    // Dismiss existing banner if still shown
    _dismissTimer?.cancel();
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;

    final targetContext = context ?? navigatorKey.currentContext;
    if (targetContext == null) {
      debugPrint('[Banner] ⚠️ Tidak ada context untuk menampilkan banner notifikasi');
      return;
    }

    final overlay = Overlay.maybeOf(targetContext, rootOverlay: true) ??
        Overlay.maybeOf(targetContext);
    if (overlay == null) {
      debugPrint('[Banner] ⚠️ Overlay tidak ditemukan pada context');
      return;
    }

    debugPrint('[Banner] 🔔 Memunculkan banner notifikasi: $title - $body');

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopBannerWidget(
        title: title,
        body: body,
        timeAgo: timeAgo ?? 'Baru saja',
        icon: icon,
        iconBgColor: iconBgColor,
        onTap: () {
          entry.remove();
          _currentEntry = null;
          _dismissTimer?.cancel();
          onTap?.call();
        },
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
          _dismissTimer?.cancel();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _TopBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final String timeAgo;
  final IconData? icon;
  final Color? iconBgColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.title,
    required this.body,
    required this.timeAgo,
    this.icon,
    this.iconBgColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after 5 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isIzin = widget.title.toLowerCase().contains('izin');
    final isSakit = widget.title.toLowerCase().contains('sakit');

    final badgeColor = widget.iconBgColor ??
        (isIzin
            ? AppColors.info
            : isSakit
                ? AppColors.warning
                : AppColors.primary);

    final badgeIcon = widget.icon ??
        (isIzin
            ? Icons.event_busy_rounded
            : isSakit
                ? Icons.sick_rounded
                : Icons.notifications_active_rounded);

    return Positioned(
      top: topPadding + 6,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {
              _autoDismissTimer?.cancel();
              _controller.reverse().then((_) {
                widget.onTap();
              });
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App / Notification Icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(badgeIcon, color: badgeColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Notification Title, Time & Body
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.timeAgo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.body,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
