import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final CollectionReference _paymentCollection = FirebaseFirestore.instance
      .collection('payment');

  Future<void> addPayment({
    required String reservationDocId,
    required int total,
    required String userId,
    required String lokerId,
    required DateTime timestamp,
  }) async {
    await _paymentCollection.add({
      'reservationDocId': reservationDocId,
      'total': total,
      'userId': userId,
      'lokerId': lokerId,
      'timestamp': timestamp,
    });
  }
}
