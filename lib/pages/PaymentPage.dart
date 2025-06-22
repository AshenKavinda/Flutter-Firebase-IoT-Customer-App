import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final int total;
  final String reservationDocId;
  const PaymentPage({
    Key? key,
    required this.total,
    required this.reservationDocId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Text(
          'Proceed to pay Rs. $total for reservation $reservationDocId',
        ),
      ),
    );
  }
}
