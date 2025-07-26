import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:customer_app/sevices/database.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:customer_app/pages/ConfirmReservationPage.dart'; // Import the ConfirmReservationPage
import 'package:customer_app/pages/Profile.dart'; // Import the ProfilePage
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<bool> _checkUserPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final db = DatabaseService();
      final hasPin = await db.userHasPin(user.uid);
      return hasPin;
    } catch (e) {
      print('Error checking PIN: $e');
      return false;
    }
  }

  void _showPinRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: AppColors.navyBlue),
              const SizedBox(width: 8),
              const Text('PIN Required'),
            ],
          ),
          content: const Text(
            'You need to set up a 4-digit PIN before making a reservation. '
            'Please go to your profile page to create one.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanQRCode() async {
    // TODO: Implement QR code scanning logic
    // Example with barcode_scan2:
    // var result = await BarcodeScanner.scan();
    // setState(() { _lockerIdController.text = result.rawContent; });
    setState(() {
      _lockerIdController.text = "4c364013"; // Placeholder for demo
    });
  }

  Future<void> _onNextPressed() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Check if user has PIN first
    final hasPin = await _checkUserPin();
    if (!hasPin) {
      setState(() {
        _isLoading = false;
      });
      _showPinRequiredDialog();
      return;
    }

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
      // Note: Using deprecated method since this page searches by locker ID only
      // Consider redesigning this flow to first select unit, then locker
      final doc = await db.getUnitByLockerId(lockerId);
      if (doc != null) {
        final data = Map<String, dynamic>.from(
          doc.value as Map<Object?, Object?>,
        );
        final lockersData = data['lockers'] as Map<Object?, Object?>?;
        if (lockersData != null && lockersData.containsKey(lockerId)) {
          final locker = Map<String, dynamic>.from(
            lockersData[lockerId] as Map<Object?, Object?>,
          );
          if (locker['status'] == 'available') {
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
            // Get the unit ID from the document
            final unitId = doc.key!;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ConfirmReservationPage(
                      unitId: unitId,
                      lockerId: lockerId,
                    ),
              ),
            );
            return;
          }
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
      print('Error fetching locker: $e');
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
            // Info card about PIN requirement
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 24.0),
              decoration: BoxDecoration(
                color: AppColors.tealBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tealBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.tealBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A PIN is required to make reservations. Please ensure you have set up your PIN in the Profile page.',
                      style: TextStyle(color: AppColors.tealBlue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
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
