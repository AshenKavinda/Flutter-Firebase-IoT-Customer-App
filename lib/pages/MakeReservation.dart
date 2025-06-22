import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:customer_app/sevices/database.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:customer_app/pages/ConfirmReservationPage.dart'; // Import the ConfirmReservationPage

// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Uncomment if using a QR package
// import 'package:barcode_scan2/barcode_scan2.dart'; // Alternative QR package

class MakeReservationPage extends StatefulWidget {
  @override
  _MakeReservationPageState createState() => _MakeReservationPageState();
}

class _MakeReservationPageState extends State<MakeReservationPage> {
  final TextEditingController _lockerIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _scanQRCode() async {
    // TODO: Implement QR code scanning logic
    // Example with barcode_scan2:
    // var result = await BarcodeScanner.scan();
    // setState(() { _lockerIdController.text = result.rawContent; });
    setState(() {
      _lockerIdController.text = "6115475X"; // Placeholder for demo
    });
  }

  Future<void> _onNextPressed() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final lockerId = _lockerIdController.text.trim();
    if (lockerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorText = 'Please enter a locker ID.';
      });
      Fluttertoast.showToast(
        msg: 'Please enter a locker ID.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    try {
      final db = DatabaseService();
      final doc = await db.getUnitByLockerId(lockerId);
      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;
        final lockers = List<Map<String, dynamic>>.from(data['lockers']);
        final locker = lockers.firstWhere(
          (l) => l['id'] == lockerId,
          orElse: () => {},
        );
        if (locker.isNotEmpty && locker['status'] == 'available') {
          if (locker['reserved'] == true) {
            setState(() {
              _errorText = 'Locker is already reserved.';
            });
            Fluttertoast.showToast(
              msg: 'Locker is already reserved.',
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConfirmReservationPage(lockerId: lockerId),
            ),
          );
          return;
        }
      }
      setState(() {
        _errorText = 'Locker not found or not available.';
      });
      Fluttertoast.showToast(
        msg: 'Locker not found or not available.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      setState(() {
        _errorText = 'Error: ${e.toString()}';
      });
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Reservation'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _lockerIdController,
              decoration: InputDecoration(
                labelText: 'Locker ID',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: AppColors.navyBlue),
                  onPressed: _scanQRCode,
                ),
                errorText: _errorText,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _isLoading ? null : _onNextPressed,
                child:
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
