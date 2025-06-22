import 'package:flutter/material.dart';
import '../sevices/database.dart';
import 'package:intl/intl.dart';
import 'PaymentPage.dart';
import '../utils/theme.dart';

class BillingPage extends StatefulWidget {
  final String reservationDocId;
  final String userId;
  const BillingPage({
    Key? key,
    required this.reservationDocId,
    required this.userId,
  }) : super(key: key);

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Map<String, dynamic>? reservationData;
  Map<String, dynamic>? lockerData;
  int billingHours = 1;
  int pricePerHour = 0;
  int total = 0;
  String lockerId = '';
  DateTime? reservedDate;
  String? reservedTime;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBillingInfo();
  }

  Future<void> fetchBillingInfo() async {
    final db = DatabaseService();
    // Get reservation document
    final reservationDocs = await db.getActiveReservationsForUser(
      widget.userId,
    );
    final doc = reservationDocs.firstWhereOrNull(
      (d) => d.id == widget.reservationDocId,
    );
    if (doc == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    reservationData = doc.data() as Map<String, dynamic>;
    lockerId = reservationData!["lockerID"];
    // Handle Firestore Timestamp or ISO string
    final ts = reservationData!["timestamp"];
    if (ts is DateTime) {
      reservedDate = ts;
    } else if (ts is String) {
      reservedDate = DateTime.tryParse(ts);
    } else if (ts != null && ts.toString().contains('Timestamp')) {
      reservedDate = (ts as dynamic).toDate();
    }
    reservedTime =
        reservedDate != null ? DateFormat('hh:mm a').format(reservedDate!) : '';
    // Get locker details
    final lockerDetails = await db.getLockerDetailsById(lockerId);
    if (lockerDetails != null) {
      lockerData = lockerDetails['locker'];
      pricePerHour = lockerData?["price"] ?? 0;
    }
    // Calculate billing hours (difference from now)
    final now = DateTime.now();
    if (reservedDate != null) {
      billingHours = now.difference(reservedDate!).inHours;
      if (billingHours < 1) billingHours = 1;
    }
    total = billingHours * pricePerHour;
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.navyBlue),
        ),
      );
    }
    if (reservationData == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Reservation not found.',
            style: TextStyle(color: AppColors.navyBlue),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Information'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: AppColors.tealBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Locker ID: $lockerId',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Reserved Date: ${reservedDate != null ? DateFormat('yyyy-MM-dd').format(reservedDate!) : '-'}',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Time: $reservedTime',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Billing Hours: $billingHours',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Price per Hour: Rs. $pricePerHour',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.white, thickness: 1),
                Text(
                  'Total: Rs. $total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PaymentPage(
                                total: total,
                                reservationDocId: widget.reservationDocId,
                                lokerId: lockerId,
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'Make Payment (Rs. $total)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper extension for firstWhereOrNull
extension IterableX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
