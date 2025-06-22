import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/sevices/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'BillingPage.dart';
import '../utils/theme.dart';

class MyReservationPage extends StatefulWidget {
  const MyReservationPage({Key? key}) : super(key: key);

  @override
  State<MyReservationPage> createState() => _MyReservationPageState();
}

class _MyReservationPageState extends State<MyReservationPage> {
  final DatabaseService _databaseService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;

  Future<List<QueryDocumentSnapshot>> _fetchReservations() async {
    if (user == null) return [];
    print('Fetching reservations for user: ${user!.uid}');
    final reservations = await _databaseService.getActiveReservationsForUser(
      user!.uid,
    );
    print('Fetched ${reservations.length} reservations');
    return reservations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navyBlue),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No active reservations.',
                style: TextStyle(color: AppColors.navyBlue),
              ),
            );
          }
          final reservations = snapshot.data!;
          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;
              final lockerId = data['lockerID'] ?? '';
              final timestamp =
                  (data['timestamp'] is Timestamp)
                      ? (data['timestamp'] as Timestamp).toDate()
                      : DateTime.tryParse(data['timestamp'].toString()) ??
                          DateTime.now();
              final now = DateTime.now();
              final duration = now.difference(timestamp);
              final billingHours =
                  duration.inSeconds >= 0 ? duration.inHours : 0;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.lock_clock, color: AppColors.navyBlue),
                  title: Text(
                    'Locker ID: $lockerId',
                    style: TextStyle(
                      color: AppColors.navyBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserved at:  ${timestamp.toLocal()}',
                        style: TextStyle(color: AppColors.navyBlue),
                      ),
                      Text(
                        'Billing hours: $billingHours',
                        style: TextStyle(color: AppColors.tealBlue),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unlock'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BillingPage(
                                reservationDocId: reservations[index].id,
                                userId: user!.uid,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
