import 'package:flutter/material.dart';

class NavigationDialog extends StatefulWidget {
  const NavigationDialog({super.key});

  @override
  State<NavigationDialog> createState() => _NavigationDialogState();
}

class _NavigationDialogState extends State<NavigationDialog> {
  Color color = Colors.blue.shade700;

  _showColorDialog(BuildContext context) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('very important question'),
          content: const Text('please choose a color'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                color = Colors.red.shade700;
                Navigator.pop(context, color);
              },
              child: const Text('red'),
            ),
            TextButton(
              onPressed: () {
                color = Colors.blueGrey.shade700;
                Navigator.pop(context, color);
              },
              child: const Text('grey'),
            ),
            TextButton(
              onPressed: () {
                color = Colors.yellowAccent.shade700;
                Navigator.pop(context, color);
              },
              child: const Text('yellow'),
            ),
          ],
        );
      },
    );
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(title: const Text('Navigation Dialog Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showColorDialog(context);
          },
          child: const Text('change color'),
        ),
      ),
    );
  }
}
