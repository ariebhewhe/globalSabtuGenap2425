import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class AppToast extends StatelessWidget {
  final String message;
  final ToastType type;

  const AppToast({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color backgroundColor;
    IconData iconData;
    Color textColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = colors.primary;
        iconData = Icons.check_circle_outline;
        textColor = colors.onPrimary;
        break;
      case ToastType.error:
        backgroundColor = colors.error;
        iconData = Icons.error_outline;
        textColor = colors.onError;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange.shade700;
        iconData = Icons.warning_amber_rounded;
        textColor = Colors.white;
        break;
      case ToastType.info:
        backgroundColor = colors.secondary;
        iconData = Icons.info_outline;
        textColor = colors.onSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: backgroundColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: textColor, size: 24),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
