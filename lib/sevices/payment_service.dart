import 'package:firebase_database/firebase_database.dart';

class PaymentService {
  final DatabaseReference _paymentRef = FirebaseDatabase.instance.ref(
    'payment',
  );

  Future<void> addPayment({
    required String reservationDocId,
    required int total,
    required String userId,
    required String lokerId,
    required DateTime timestamp,
  }) async {
    await _paymentRef.push().set({
      'reservationDocId': reservationDocId,
      'total': total,
      'userId': userId,
      'lokerId': lokerId,
      'timestamp': timestamp.toIso8601String(),
    });
  }
}
