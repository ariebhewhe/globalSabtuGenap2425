import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:jamal/shared/widgets/app_toast.dart'; // Sesuaikan path

class ToastUtils {
  static const Duration _duration = Duration(seconds: 3);
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Alignment _align = Alignment(0, 0.85);

  static void _showToast({
    required BuildContext context,
    required String message,
    required ToastType type,
  }) {
    BotToast.showAnimationWidget(
      animationDuration: _animationDuration,
      duration: _duration,
      onlyOne: true,
      enableKeyboardSafeArea: true,
      toastBuilder: (_) {
        return Align(
          alignment: _align,
          child: AppToast(message: message, type: type),
        );
      },
    );
  }

  /// Menampilkan toast tipe SUCCESS (hijau/biru toska)
  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    _showToast(context: context, message: message, type: ToastType.success);
  }

  /// Menampilkan toast tipe ERROR (merah/pink)
  static void showError({
    required BuildContext context,
    required String message,
  }) {
    _showToast(context: context, message: message, type: ToastType.error);
  }

  /// Menampilkan toast tipe WARNING (oranye)
  static void showWarning({
    required BuildContext context,
    required String message,
  }) {
    _showToast(context: context, message: message, type: ToastType.warning);
  }

  /// Menampilkan toast tipe INFO (abu-abu/sekunder)
  static void showInfo({
    required BuildContext context,
    required String message,
  }) {
    _showToast(context: context, message: message, type: ToastType.info);
  }
}
