import 'package:flutter/material.dart';
import 'package:customer_app/sevices/database.dart';

class LokerUnlockPage extends StatelessWidget {
  final String lockerId;
  const LokerUnlockPage({Key? key, required this.lockerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Locker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Locker ID: $lockerId', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final db = DatabaseService();
                final success = await db.unlockLocker(lockerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Locker unlocked!' : 'Failed to unlock.',
                    ),
                  ),
                );
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
