import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final double top;
  final double right;
  final double badgeSize;
  
  const NotificationBadge({
    super.key,
    required this.child,
    this.top = 0,
    this.right = 0,
    this.badgeSize = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0)
          Positioned(
            top: top,
            right: right,
            child: Container(
              padding: EdgeInsets.all(badgeSize / 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize,
                minHeight: badgeSize,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeSize / 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}