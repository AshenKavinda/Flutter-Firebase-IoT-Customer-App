import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sevices/database.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/theme.dart';
import 'ConfirmReservationPage.dart';
import 'Profile.dart';

class UnitDetailsPage extends StatefulWidget {
  final String unitId;

  const UnitDetailsPage({Key? key, required this.unitId}) : super(key: key);

  @override
  _UnitDetailsPageState createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage> {
  bool _isLoading = false;

  Future<DataSnapshot?> _fetchUnit() async {
    return await DatabaseService().getUnitById(widget.unitId);
  }

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

  Future<void> _reserveLocker(String lockerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user has PIN first
      final hasPin = await _checkUserPin();
      if (!hasPin) {
        setState(() {
          _isLoading = false;
        });
        _showPinRequiredDialog();
        return;
      }

      final db = DatabaseService();
      final doc = await db.getUnitByLockerId(lockerId);
      if (doc != null) {
        final data = Map<String, dynamic>.from(
          doc.value as Map<Object?, Object?>,
        );

        // Handle both Map and List structures for lockers
        final lockersRaw = data['lockers'];
        Map<String, dynamic>? targetLocker;

        if (lockersRaw != null) {
          if (lockersRaw is Map) {
            final lockersData = Map<String, dynamic>.from(lockersRaw);
            if (lockersData.containsKey(lockerId)) {
              targetLocker = Map<String, dynamic>.from(
                lockersData[lockerId] as Map<Object?, Object?>,
              );
            }
          } else if (lockersRaw is List) {
            for (var item in lockersRaw) {
              if (item != null && item is Map) {
                final locker = Map<String, dynamic>.from(
                  item as Map<Object?, Object?>,
                );
                if (locker['id'] == lockerId) {
                  targetLocker = locker;
                  break;
                }
              }
            }
          }
        }

        if (targetLocker != null) {
          if (targetLocker['status'] == 'available' &&
              targetLocker['reserved'] == false) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ConfirmReservationPage(lockerId: lockerId),
              ),
            );
          } else {
            Fluttertoast.showToast(
              msg: 'Locker is already reserved or not available.',
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Locker not found.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Unit not found.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error reserving locker: $e');
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
        title: Text('Unit Details'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<DataSnapshot?>(
            future: _fetchUnit(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.navyBlue),
                );
              }
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'No data found for this unit.',
                    style: TextStyle(color: AppColors.navyBlue),
                  ),
                );
              }
              final data = Map<String, dynamic>.from(
                snapshot.data!.value as Map<Object?, Object?>,
              );

              // Handle both Map and List structures for lockers
              final lockersRaw = data['lockers'];
              List<Map<String, dynamic>> lockers = [];

              if (lockersRaw != null) {
                if (lockersRaw is Map) {
                  // If lockers is a Map (like {"1": {...}, "2": {...}})
                  final lockersData = Map<String, dynamic>.from(lockersRaw);
                  lockers =
                      lockersData.values.where((e) => e != null && e is Map).map((
                        e,
                      ) {
                        final locker = Map<String, dynamic>.from(
                          e as Map<Object?, Object?>,
                        );
                        // Convert integer values to boolean for app compatibility
                        locker['locked'] = (locker['locked'] == 1);
                        locker['confirmation'] = (locker['confirmation'] == 1);
                        return locker;
                      }).toList();
                } else if (lockersRaw is List) {
                  // If lockers is a List
                  lockers =
                      lockersRaw.where((e) => e != null && e is Map).map((e) {
                        final locker = Map<String, dynamic>.from(
                          e as Map<Object?, Object?>,
                        );
                        // Convert integer values to boolean for app compatibility
                        locker['locked'] = (locker['locked'] == 1);
                        locker['confirmation'] = (locker['confirmation'] == 1);
                        return locker;
                      }).toList();
                }
              }
              final availableCount =
                  lockers.where((l) => l['reserved'] == false).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card about PIN requirement
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.tealBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.tealBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.tealBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A PIN is required to make reservations. Tap on available lockers to reserve.',
                            style: TextStyle(
                              color: AppColors.tealBlue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: AppColors.tealBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Available Lockers: $availableCount',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.navyBlue, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lockers.length,
                      itemBuilder: (context, index) {
                        final locker = lockers[index];
                        final isAvailable =
                            locker['reserved'] == false &&
                            locker['status'] == 'available';
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isAvailable ? Icons.check_circle : Icons.cancel,
                              color: isAvailable ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              'Locker ID: ${locker['id']}',
                              style: TextStyle(
                                color: AppColors.navyBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAvailable ? 'Available' : 'Not Available',
                                  style: TextStyle(
                                    color:
                                        isAvailable ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (locker['price'] != null)
                                  Text(
                                    'Price: \$${locker['price']}',
                                    style: TextStyle(
                                      color: AppColors.navyBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                isAvailable
                                    ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.navyBlue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed:
                                          () => _reserveLocker(
                                            locker['id'].toString(),
                                          ),
                                      child: Text('Reserve'),
                                    )
                                    : null,
                            onTap:
                                isAvailable
                                    ? () =>
                                        _reserveLocker(locker['id'].toString())
                                    : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyBlue),
              ),
            ),
        ],
      ),
    );
  }
}
