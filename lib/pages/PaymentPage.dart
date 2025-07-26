import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' as material;
import '../sevices/database.dart';
import '../sevices/payment_service.dart';
import '../utils/theme.dart';
import 'package:customer_app/pages/HomePage.dart';

class PaymentPage extends material.StatefulWidget {
  final int total;
  final String reservationDocId;
  final String lokerId;
  const PaymentPage({
    material.Key? key,
    required this.total,
    required this.reservationDocId,
    required this.lokerId,
  }) : super(key: key);

  @override
  material.State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends material.State<PaymentPage> {
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
      // If payment successful, update Realtime Database
      final db = DatabaseService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Set reservation active to false
      await FirebaseDatabase.instance
          .ref('reservations')
          .child(widget.reservationDocId)
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
      await material.showDialog(
        context: context,
        builder:
            (context) => material.AlertDialog(
              title: const material.Text('Payment Successful'),
              content: const material.Text('Your payment was successful.'),
              actions: [
                material.TextButton(
                  onPressed: () {
                    material.Navigator.of(context).pop();
                  },
                  child: const material.Text('OK'),
                ),
              ],
            ),
      );
      // --- Locker confirmation/locking logic (after dialog) ---
      // 1. Set locked to false
      await db.setLockerLocked(widget.lokerId, false);

      // Show thank you message after unlocking
      if (!mounted) return;
      await material.showDialog(
        context: context,
        builder:
            (context) => material.AlertDialog(
              title: const material.Text('Thank You!'),
              content: const material.Text(
                'Your locker has been unlocked. Thank you for using our service!',
              ),
              actions: [
                material.TextButton(
                  onPressed: () {
                    material.Navigator.of(context).pop();
                  },
                  child: const material.Text('OK'),
                ),
              ],
            ),
      );
      // --- End Locker confirmation/locking logic ---
      // Redirect to HomePage with reservation tab selected (index 2)
      material.Navigator.of(context).pushAndRemoveUntil(
        material.MaterialPageRoute(
          builder: (context) => HomePage(initialTab: 2),
        ),
        (route) => false,
      );
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
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text('Payment'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: material.Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.navyBlue.withOpacity(0.03),
      body: material.Center(
        child:
            _loading
                ? const material.CircularProgressIndicator(
                  color: AppColors.navyBlue,
                )
                : material.Padding(
                  padding: const material.EdgeInsets.symmetric(
                    horizontal: 24.0,
                  ),
                  child: material.Column(
                    mainAxisAlignment: material.MainAxisAlignment.center,
                    crossAxisAlignment: material.CrossAxisAlignment.center,
                    children: [
                      material.Card(
                        color: AppColors.tealBlue,
                        shape: material.RoundedRectangleBorder(
                          borderRadius: material.BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: material.Padding(
                          padding: const material.EdgeInsets.all(24.0),
                          child: material.Column(
                            children: [
                              material.Icon(
                                material.Icons.payment,
                                color: material.Colors.white,
                                size: 40,
                              ),
                              const material.SizedBox(height: 16),
                              material.Text(
                                'Total Payment',
                                style: material.TextStyle(
                                  color: material.Colors.white70,
                                  fontSize: 16,
                                  fontWeight: material.FontWeight.w500,
                                ),
                              ),
                              const material.SizedBox(height: 8),
                              material.Text(
                                'Rs. ${widget.total}',
                                style: material.TextStyle(
                                  color: material.Colors.white,
                                  fontSize: 28,
                                  fontWeight: material.FontWeight.bold,
                                ),
                              ),
                              const material.SizedBox(height: 12),
                              material.Text(
                                'Reservation ID: ${widget.reservationDocId}',
                                style: material.TextStyle(
                                  color: material.Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: material.TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const material.SizedBox(height: 32),
                      material.SizedBox(
                        width: double.infinity,
                        child: material.ElevatedButton(
                          style: material.ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyBlue,
                            foregroundColor: material.Colors.white,
                            padding: const material.EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: material.RoundedRectangleBorder(
                              borderRadius: material.BorderRadius.circular(12),
                            ),
                            textStyle: const material.TextStyle(
                              fontSize: 18,
                              fontWeight: material.FontWeight.bold,
                            ),
                            elevation: 2,
                          ),
                          onPressed: _handlePayment,
                          child: const material.Text('Pay Now'),
                        ),
                      ),
                      if (_error != null) ...[
                        const material.SizedBox(height: 20),
                        material.Container(
                          padding: const material.EdgeInsets.all(12),
                          decoration: material.BoxDecoration(
                            color: material.Colors.red.withOpacity(0.1),
                            borderRadius: material.BorderRadius.circular(8),
                          ),
                          child: material.Row(
                            mainAxisAlignment:
                                material.MainAxisAlignment.center,
                            children: [
                              material.Icon(
                                material.Icons.error,
                                color: material.Colors.red[700],
                              ),
                              const material.SizedBox(width: 8),
                              material.Expanded(
                                child: material.Text(
                                  _error!,
                                  style: const material.TextStyle(
                                    color: material.Colors.red,
                                    fontWeight: material.FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }
}
