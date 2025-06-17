import 'package:flutter/material.dart';

Future<void> showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
