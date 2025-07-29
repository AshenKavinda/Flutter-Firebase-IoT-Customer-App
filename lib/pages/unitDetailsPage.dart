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

  Future<int> _checkUserPayableBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final db = DatabaseService();
      final payableBalance = await db.getUserPayableBalance(user.uid);
      return payableBalance;
    } catch (e) {
      print('Error checking payable balance: $e');
      return 0;
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

  void _showPayableBalanceDialog(int balance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Outstanding Balance'),
            ],
          ),
          content: Text(
            'You have an outstanding balance of Rs. $balance that needs to be paid before making a new reservation. '
            'Please go to your profile page to pay the balance.',
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
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: const Text('Pay Now'),
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

      // Check if user has payable balance
      final payableBalance = await _checkUserPayableBalance();
      if (payableBalance > 0) {
        setState(() {
          _isLoading = false;
        });
        _showPayableBalanceDialog(payableBalance);
        return;
      }

      final db = DatabaseService();
      // Use the database service method that handles the data structure complexity
      final lockerDetails = await db.getLockerDetailsByUnitAndLockerId(
        widget.unitId,
        lockerId,
      );

      if (lockerDetails != null) {
        final locker = lockerDetails['locker'] as Map<String, dynamic>;

        if (locker['status'] == 'available' && locker['reserved'] == false) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => ConfirmReservationPage(
                    unitId: widget.unitId,
                    lockerId: lockerId,
                  ),
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
          msg: 'Locker not found in this unit.',
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Modern header with gradient
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.navyBlue, AppColors.tealBlue],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.storage_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Locker Unit',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      widget.unitId,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: FutureBuilder<DataSnapshot?>(
                  future: _fetchUnit(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 400,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.tealBlue,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Loading unit details...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        !snapshot.data!.exists) {
                      return Container(
                        height: 400,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.grey[400],
                                  size: 80,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Unit Not Found',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No data available for this unit',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        final lockersData = Map<String, dynamic>.from(
                          lockersRaw,
                        );
                        lockers =
                            lockersData.values
                                .where((e) => e != null && e is Map)
                                .map((e) {
                                  final locker = Map<String, dynamic>.from(
                                    e as Map<Object?, Object?>,
                                  );
                                  // Convert integer values to boolean for app compatibility
                                  locker['locked'] = (locker['locked'] == 1);
                                  locker['confirmation'] =
                                      (locker['confirmation'] == 1);
                                  return locker;
                                })
                                .toList();
                      } else if (lockersRaw is List) {
                        // If lockers is a List
                        lockers =
                            lockersRaw.where((e) => e != null && e is Map).map((
                              e,
                            ) {
                              final locker = Map<String, dynamic>.from(
                                e as Map<Object?, Object?>,
                              );
                              // Convert integer values to boolean for app compatibility
                              locker['locked'] = (locker['locked'] == 1);
                              locker['confirmation'] =
                                  (locker['confirmation'] == 1);
                              return locker;
                            }).toList();
                      }
                    }
                    final availableCount =
                        lockers.where((l) => l['reserved'] == false).length;

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.tealBlue.withOpacity(0.1),
                                  AppColors.navyBlue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.tealBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.tealBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: AppColors.tealBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    'A PIN is required to make reservations. Tap on available lockers to reserve.',
                                    style: TextStyle(
                                      color: AppColors.tealBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Stats card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.tealBlue,
                                  AppColors.navyBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.tealBlue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.dashboard_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available Lockers',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '$availableCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Section title
                          Text(
                            'Select Locker',
                            style: TextStyle(
                              color: AppColors.navyBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Lockers grid
                          ...lockers.map((locker) {
                            final isAvailable =
                                locker['reserved'] == false &&
                                locker['status'] == 'available';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color:
                                      isAvailable
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap:
                                      isAvailable
                                          ? () => _reserveLocker(
                                            locker['id'].toString(),
                                          )
                                          : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors:
                                                  isAvailable
                                                      ? [
                                                        Colors.green.shade400,
                                                        Colors.green.shade600,
                                                      ]
                                                      : [
                                                        Colors.red.shade400,
                                                        Colors.red.shade600,
                                                      ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          child: Icon(
                                            isAvailable
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Locker ${locker['id']}',
                                                style: TextStyle(
                                                  color: AppColors.navyBlue,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isAvailable
                                                              ? Colors.green
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                              : Colors.red
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      isAvailable
                                                          ? 'Available'
                                                          : 'Occupied',
                                                      style: TextStyle(
                                                        color:
                                                            isAvailable
                                                                ? Colors
                                                                    .green[700]
                                                                : Colors
                                                                    .red[700],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  if (locker['price'] !=
                                                      null) ...[
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      '\$${locker['price']}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isAvailable)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.navyBlue,
                                                  AppColors.tealBlue,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Text(
                                              'Reserve',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.tealBlue,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Processing reservation...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
