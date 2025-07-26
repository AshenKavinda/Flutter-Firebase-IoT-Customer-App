import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _unitsRef = FirebaseDatabase.instance.ref('units');
  final DatabaseReference _reservationsRef = FirebaseDatabase.instance.ref(
    'reservations',
  );
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  /// Get all unit documents (for marker loading)
  Future<List<DataSnapshot>> getAllUnitDocs() async {
    final snapshot = await _unitsRef.get();
    if (!snapshot.exists) return [];

    final units = <DataSnapshot>[];
    for (final child in snapshot.children) {
      final data = child.value as Map<Object?, Object?>?;
      if (data != null &&
          data['deleted'] == false &&
          data['status'] == 'available') {
        units.add(child);
      }
    }
    return units;
  }

  /// Get a unit document by its Realtime Database key
  Future<DataSnapshot?> getUnitById(String id) async {
    final snapshot = await _unitsRef.child(id).get();
    return snapshot.exists ? snapshot : null;
  }

  /// Get the unit document that contains a locker with the given lockerId
  Future<DataSnapshot?> getUnitByLockerId(String lockerId) async {
    // Realtime Database: fetch all available units and filter in Dart
    final snapshot = await _unitsRef.get();
    if (!snapshot.exists) return null;

    for (final child in snapshot.children) {
      final data = child.value as Map<Object?, Object?>?;
      if (data != null &&
          data['deleted'] == false &&
          data['status'] == 'available' &&
          data['lockers'] != null) {
        final lockersData = data['lockers'] as Map<Object?, Object?>;
        if (lockersData.containsKey(lockerId)) {
          return child;
        }
      }
    }
    return null;
  }

  /// Get locker details (unit snapshot, locker map, locker index) by lockerId
  Future<Map<String, dynamic>?> getLockerDetailsById(String lockerId) async {
    final snapshot = await _unitsRef.get();
    if (!snapshot.exists) return null;

    for (final child in snapshot.children) {
      final data = child.value as Map<Object?, Object?>?;
      if (data != null &&
          data['deleted'] == false &&
          data['status'] == 'available' &&
          data['lockers'] != null) {
        final lockersData = data['lockers'] as Map<Object?, Object?>;
        if (lockersData.containsKey(lockerId)) {
          final lockerData = lockersData[lockerId] as Map<Object?, Object?>;
          final locker = Map<String, dynamic>.from(lockerData);

          // Convert integer values to boolean for app compatibility
          locker['locked'] = (locker['locked'] == 1);
          locker['confirmation'] = (locker['confirmation'] == 1);

          return {
            'unitSnapshot': child,
            'locker': locker,
            'lockerId': lockerId,
          };
        }
      }
    }
    return null;
  }

  /// Set the 'locked' field of a locker to false (unlock)
  Future<bool> unlockLocker(String lockerId) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final unitSnapshot = details['unitSnapshot'] as DataSnapshot;

    await _unitsRef
        .child(unitSnapshot.key!)
        .child('lockers')
        .child(lockerId)
        .update({'locked': 0});
    return true;
  }

  /// Set the 'locked' field of a locker to a given value (lock/unlock)
  Future<bool> setLockerLocked(String lockerId, bool locked) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final unitSnapshot = details['unitSnapshot'] as DataSnapshot;

    await _unitsRef
        .child(unitSnapshot.key!)
        .child('lockers')
        .child(lockerId)
        .update({'locked': locked ? 1 : 0});
    return true;
  }

  /// Set the 'confirmation' field of a locker to a given value
  Future<bool> setLockerConfirmation(String lockerId, bool confirmation) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final unitSnapshot = details['unitSnapshot'] as DataSnapshot;

    await _unitsRef
        .child(unitSnapshot.key!)
        .child('lockers')
        .child(lockerId)
        .update({'confirmation': confirmation ? 1 : 0});
    return true;
  }

  /// Add a reservation record to the reservations collection
  Future<bool> addReservation({
    required String userId,
    required String lockerId,
    required DateTime timestamp,
  }) async {
    try {
      await _reservationsRef.push().set({
        'timestamp': timestamp.toIso8601String(),
        'userID': userId,
        'lockerID': lockerId,
        'active': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set the 'reserved' field of a locker to true
  Future<bool> setLockerReserved(String lockerId, bool reserved) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final unitSnapshot = details['unitSnapshot'] as DataSnapshot;

    await _unitsRef
        .child(unitSnapshot.key!)
        .child('lockers')
        .child(lockerId)
        .update({'reserved': reserved});
    return true;
  }

  /// Get the latest locker details (for polling)
  Future<Map<String, dynamic>?> getLockerStatusById(String lockerId) async {
    return await getLockerDetailsById(lockerId);
  }

  /// Get all active reservations for a user
  Future<List<DataSnapshot>> getActiveReservationsForUser(String userId) async {
    final snapshot = await _reservationsRef.get();
    if (!snapshot.exists) return [];

    final reservations = <DataSnapshot>[];
    for (final child in snapshot.children) {
      final data = child.value as Map<Object?, Object?>?;
      if (data != null && data['userID'] == userId && data['active'] == true) {
        reservations.add(child);
      }
    }

    // Sort by timestamp (descending)
    reservations.sort((a, b) {
      final aData = a.value as Map<Object?, Object?>;
      final bData = b.value as Map<Object?, Object?>;
      final aTime =
          DateTime.tryParse(aData['timestamp']?.toString() ?? '') ??
          DateTime.now();
      final bTime =
          DateTime.tryParse(bData['timestamp']?.toString() ?? '') ??
          DateTime.now();
      return bTime.compareTo(aTime);
    });

    return reservations;
  }

  /// Get user PIN by user ID
  Future<String?> getUserPin(String userId) async {
    final snapshot = await _usersRef.child(userId).child('pin').get();
    return snapshot.exists ? snapshot.value as String? : null;
  }

  /// Set or update user PIN
  Future<bool> setUserPin(String userId, String pin) async {
    try {
      await _usersRef.child(userId).update({'pin': pin});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has a PIN
  Future<bool> userHasPin(String userId) async {
    final pin = await getUserPin(userId);
    return pin != null && pin.isNotEmpty;
  }
}
