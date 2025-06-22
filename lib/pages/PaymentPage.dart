import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../sevices/database.dart';
import '../sevices/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final int total;
  final String reservationDocId;
  final String lokerId;
  const PaymentPage({
    Key? key,
    required this.total,
    required this.reservationDocId,
    required this.lokerId,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;
  String? _error;

  Future<void> _handlePayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Temporary: Simulate payment success
      await Future.delayed(const Duration(seconds: 2));
      // TODO: Integrate Stripe payment here
      // If payment successful, update Firestore
      final db = DatabaseService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Set reservation active to false
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(widget.reservationDocId)
          .update({'active': false});
      // Set unit locker reserved to false
      await db.setLockerReserved(widget.lokerId, false);
      // Add payment record
      final paymentService = PaymentService();
      await paymentService.addPayment(
        reservationDocId: widget.reservationDocId,
        total: widget.total,
        userId: user.uid,
        lokerId: widget.lokerId,
        timestamp: DateTime.now(),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Payment Successful'),
              content: const Text('Your payment was successful.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      // --- Locker confirmation/locking logic (after dialog) ---
      // 1. Set locked to false
      await db.setLockerLocked(widget.lokerId, false);
      // 2. Start waiting for confirmation to become true
      bool confirmed = false;
      int attempts = 0;
      while (!confirmed && attempts < 350) {
        // wait up to ~30 seconds
        await Future.delayed(const Duration(seconds: 1));
        final lockerStatus = await db.getLockerStatusById(widget.lokerId);
        if (lockerStatus != null && lockerStatus['locker'] != null) {
          if (lockerStatus['locker']['confirmation'] == true) {
            confirmed = true;
            break;
          }
        }
        attempts++;
      }
      if (confirmed) {
        // 3. Set locked to true and reset confirmation to false
        await db.setLockerLocked(widget.lokerId, true);
        await db.setLockerConfirmation(widget.lokerId, false);
      }
      // --- End Locker confirmation/locking logic ---
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child:
            _loading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to pay Rs. ${widget.total} for reservation ${widget.reservationDocId}',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handlePayment,
                      child: const Text('Pay Now'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
      ),
    );
  }
}
