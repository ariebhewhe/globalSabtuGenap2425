import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationUtils {
  /// Request notification permissions from the user
  static Future<void> requestNotificationPermissions(BuildContext context) async {
    // Check current permission status
    PermissionStatus status = await Permission.notification.status;
    
    if (status.isDenied) {
      // If permission is denied, request it
      status = await Permission.notification.request();
      
      // Handle the result
      if (status.isPermanentlyDenied) {
        // If permanently denied, show a dialog to guide the user to settings
        _showSettingsDialog(context);
      } else if (status.isGranted) {
        // Permission granted, show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi diaktifkan! Anda akan menerima update pesanan secara langsung.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  /// Show a dialog guiding users to app settings if permissions are permanently denied
  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Notifikasi Diperlukan'),
          content: const Text(
            'Notifikasi diperlukan untuk menerima update status pesanan. '
            'Silakan aktifkan notifikasi di pengaturan aplikasi.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('BATALKAN'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('BUKA PENGATURAN'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}