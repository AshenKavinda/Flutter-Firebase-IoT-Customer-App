import 'package:customer_app/sevices/database.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmReservationPage extends StatefulWidget {
  final String lockerId;
  const ConfirmReservationPage({Key? key, required this.lockerId})
    : super(key: key);

  @override
  State<ConfirmReservationPage> createState() => _ConfirmReservationPageState();
}

class _ConfirmReservationPageState extends State<ConfirmReservationPage> {
  double? _pricePerHour;
  bool _isProcessing = false;
  String? _message;
  bool _lockerOpened = false;
  bool _processComplete = false;

  @override
  void initState() {
    super.initState();
    _fetchLockerDetails();
  }

  Future<void> _fetchLockerDetails() async {
    try {
      final details = await DatabaseService().getLockerDetailsById(
        widget.lockerId,
      );
      if (details != null) {
        final locker = details['locker'] as Map<String, dynamic>;
        setState(() {
          _pricePerHour =
              locker['price'] != null
                  ? (locker['price'] as num).toDouble()
                  : null;
        });
      } else {
        setState(() {
          _pricePerHour = null;
        });
      }
    } catch (e) {
      setState(() {
        _pricePerHour = null;
      });
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
      _message = null;
    });
    // Step 1: Unlock locker
    final success = await DatabaseService().setLockerLocked(
      widget.lockerId,
      false,
    );
    if (success) {
      // Confirm it's unlocked
      final details = await DatabaseService().getLockerStatusById(
        widget.lockerId,
      );
      final locker =
          details != null ? details['locker'] as Map<String, dynamic> : null;
      if (locker != null && locker['locked'] == false) {
        setState(() {
          _lockerOpened = true;
          _message =
              'Locker is now OPEN. Please place your items inside, close the door, and press the CONFIRM button on the locker.';
        });
        // Start polling for confirmation
        _pollForConfirmation();
      } else {
        setState(() {
          _isProcessing = false;
          _message = 'Failed to open locker.';
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _message = 'Failed to open locker.';
      });
    }
  }

  Future<void> _pollForConfirmation() async {
    // Poll confirmation field
    bool confirmed = false;
    for (int i = 0; i < 40; i++) {
      // Poll up to 20 seconds
      final details = await DatabaseService().getLockerStatusById(
        widget.lockerId,
      );
      final locker =
          details != null ? details['locker'] as Map<String, dynamic> : null;
      if (locker != null && locker['confirmation'] == true) {
        confirmed = true;
        break;
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
    if (confirmed) {
      // Lock the locker again
      final locked = await DatabaseService().setLockerLocked(
        widget.lockerId,
        true,
      );
      if (locked) {
        // Add reservation record
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await DatabaseService().addReservation(
            userId: user.uid,
            lockerId: widget.lockerId,
            timestamp: DateTime.now(),
          );
          await DatabaseService().setLockerReserved(widget.lockerId, true);
        }
        // Reset confirmation field to false
        await DatabaseService().setLockerConfirmation(widget.lockerId, false);
        setState(() {
          _processComplete = true;
          _isProcessing = false;
          _message =
              'All done! Locker is now LOCKED. Thank you for using our service.';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _message = 'Failed to lock locker.';
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _message =
            'Locker confirmation not received. Please try again or contact support.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation Receipt'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          color: AppColors.tealBlue,
          margin: EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Locker ID: ${widget.lockerId}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  _pricePerHour != null
                      ? 'Price per hour: LKR ${_pricePerHour!.toStringAsFixed(2)}'
                      : 'Price not available',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 24),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _message!,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!_lockerOpened && !_processComplete)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: Size(180, 48),
                    ),
                    onPressed: _isProcessing ? null : _handleConfirm,
                    child:
                        _isProcessing
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Confirm'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
