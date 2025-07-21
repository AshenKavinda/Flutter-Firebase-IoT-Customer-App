import 'package:flutter/material.dart';
import '../sevices/database.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/theme.dart';

class UnitDetailsPage extends StatelessWidget {
  final String unitId;

  const UnitDetailsPage({Key? key, required this.unitId}) : super(key: key);

  Future<DataSnapshot?> _fetchUnit() async {
    return await DatabaseService().getUnitById(unitId);
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
      body: FutureBuilder<DataSnapshot?>(
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
          final lockersData = data['lockers'] as Map<Object?, Object?>? ?? {};
          final lockers =
              lockersData.values.map((e) {
                final locker = Map<String, dynamic>.from(
                  e as Map<Object?, Object?>,
                );
                // Convert integer values to boolean for app compatibility
                locker['locked'] = (locker['locked'] == 1);
                locker['confirmation'] = (locker['confirmation'] == 1);
                return locker;
              }).toList();
          final availableCount =
              lockers.where((l) => l['reserved'] == false).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                    final isAvailable = locker['reserved'] == false;
                    return Card(
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        subtitle: Text(
                          isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
