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

  /// Get the unit document that contains a locker with the given lockerId (deprecated)
  @deprecated
  Future<DataSnapshot?> getUnitByLockerId(String lockerId) async {
    // This method is deprecated since locker IDs are not unique across units
    // Use getUnitByIdAndLockerId instead
    final snapshot = await _unitsRef.get();
    if (!snapshot.exists) return null;

    for (final child in snapshot.children) {
      final data = child.value as Map<Object?, Object?>?;
      if (data != null &&
          data['deleted'] == false &&
          data['status'] == 'available' &&
          data['lockers'] != null) {
        final lockersRaw = data['lockers'];

        // Handle both Map and List structures for lockers
        if (lockersRaw is Map) {
          final lockersData = lockersRaw as Map<Object?, Object?>;
          if (lockersData.containsKey(lockerId)) {
            return child;
          }
        } else if (lockersRaw is List) {
          final lockersList = lockersRaw as List<Object?>;
          for (var item in lockersList) {
            if (item != null && item is Map) {
              final lockerMap = item as Map<Object?, Object?>;
              final locker = Map<String, dynamic>.from(lockerMap);

              // Check if this is the locker we're looking for
              if (locker['id'].toString() == lockerId) {
                return child;
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Get the unit document by unit ID and verify locker exists
  Future<DataSnapshot?> getUnitByIdAndLockerId(
    String unitId,
    String lockerId,
  ) async {
    final snapshot = await _unitsRef.child(unitId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.value as Map<Object?, Object?>?;
    if (data != null &&
        data['deleted'] == false &&
        data['status'] == 'available' &&
        data['lockers'] != null) {
      final lockersRaw = data['lockers'];

      // Handle both Map and List structures for lockers
      if (lockersRaw is Map) {
        // If lockers is stored as a Map (like {"1": {...}, "2": {...}})
        final lockersData = lockersRaw as Map<Object?, Object?>;
        if (lockersData.containsKey(lockerId)) {
          return snapshot;
        }
      } else if (lockersRaw is List) {
        // If lockers is stored as a List
        final lockersList = lockersRaw as List<Object?>;
        for (var item in lockersList) {
          if (item != null && item is Map) {
            final lockerMap = item as Map<Object?, Object?>;
            final locker = Map<String, dynamic>.from(lockerMap);

            // Check if this is the locker we're looking for
            if (locker['id'].toString() == lockerId) {
              return snapshot;
            }
          }
        }
      }
    }
    return null;
  }

  /// Get locker details (unit snapshot, locker map, locker index) by lockerId (deprecated)
  @deprecated
  Future<Map<String, dynamic>?> getLockerDetailsById(String lockerId) async {
    // This method is deprecated since locker IDs are not unique across units
    // Use getLockerDetailsByUnitAndLockerId instead
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

  /// Get locker details by unit ID and locker ID
  Future<Map<String, dynamic>?> getLockerDetailsByUnitAndLockerId(
    String unitId,
    String lockerId,
  ) async {
    final snapshot = await _unitsRef.child(unitId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.value as Map<Object?, Object?>?;
    if (data != null &&
        data['deleted'] == false &&
        data['status'] == 'available' &&
        data['lockers'] != null) {
      final lockersRaw = data['lockers'];

      // Handle both Map and List structures for lockers
      if (lockersRaw is Map) {
        // If lockers is stored as a Map (like {"1": {...}, "2": {...}})
        final lockersData = lockersRaw as Map<Object?, Object?>;
        if (lockersData.containsKey(lockerId)) {
          final lockerData = lockersData[lockerId];
          if (lockerData != null && lockerData is Map) {
            final locker = Map<String, dynamic>.from(
              lockerData as Map<Object?, Object?>,
            );

            // Convert integer values to boolean for app compatibility
            locker['locked'] = (locker['locked'] == 1);
            locker['confirmation'] = (locker['confirmation'] == 1);

            return {
              'unitSnapshot': snapshot,
              'unitId': unitId,
              'locker': locker,
              'lockerId': lockerId,
            };
          }
        }
      } else if (lockersRaw is List) {
        // If lockers is stored as a List
        final lockersList = lockersRaw as List<Object?>;
        for (var item in lockersList) {
          if (item != null && item is Map) {
            final lockerMap = item as Map<Object?, Object?>;
            final locker = Map<String, dynamic>.from(lockerMap);

            // Check if this is the locker we're looking for
            if (locker['id'].toString() == lockerId) {
              // Convert integer values to boolean for app compatibility
              locker['locked'] = (locker['locked'] == 1);
              locker['confirmation'] = (locker['confirmation'] == 1);

              return {
                'unitSnapshot': snapshot,
                'unitId': unitId,
                'locker': locker,
                'lockerId': lockerId,
              };
            }
          }
        }
      }
    }
    return null;
  }

  /// Set the 'locked' field of a locker to false (unlock) - deprecated
  @deprecated
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

  /// Set the 'locked' field of a locker to false (unlock)
  Future<bool> unlockLockerByUnitAndLockerId(
    String unitId,
    String lockerId,
  ) async {
    return await setLockerLockedByUnitAndLockerId(unitId, lockerId, false);
  }

  /// Set the 'locked' field of a locker to a given value (lock/unlock) - deprecated
  @deprecated
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

  /// Set the 'locked' field of a locker to a given value (lock/unlock)
  Future<bool> setLockerLockedByUnitAndLockerId(
    String unitId,
    String lockerId,
    bool locked,
  ) async {
    try {
      final snapshot = await _unitsRef.child(unitId).get();
      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<Object?, Object?>?;
      if (data == null || data['lockers'] == null) return false;

      final lockersRaw = data['lockers'];

      if (lockersRaw is Map) {
        // If lockers is stored as a Map, use direct path update
        await _unitsRef.child(unitId).child('lockers').child(lockerId).update({
          'locked': locked ? 1 : 0,
        });
        return true;
      } else if (lockersRaw is List) {
        // If lockers is stored as a List, update the entire array
        final lockersList = List<Object?>.from(lockersRaw as List<Object?>);
        bool found = false;

        for (int i = 0; i < lockersList.length; i++) {
          final item = lockersList[i];
          if (item != null && item is Map) {
            final lockerMap = Map<String, dynamic>.from(
              item as Map<Object?, Object?>,
            );
            if (lockerMap['id'].toString() == lockerId) {
              lockerMap['locked'] = locked ? 1 : 0;
              lockersList[i] = lockerMap;
              found = true;
              break;
            }
          }
        }

        if (found) {
          await _unitsRef.child(unitId).update({'lockers': lockersList});
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating locker locked status: $e');
      return false;
    }
  }

  Future<bool> setLockerReservedDocId(
    String unitId,
    String lockerId,
    String reservationDocId,
  ) async {
    try {
      final snapshot = await _unitsRef.child(unitId).get();
      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<Object?, Object?>?;
      if (data == null || data['lockers'] == null) return false;

      final lockersRaw = data['lockers'];

      if (lockersRaw is Map) {
        // If lockers is stored as a Map, use direct path update
        await _unitsRef.child(unitId).child('lockers').child(lockerId).update({
          'reservedDocID': reservationDocId,
        });
        return true;
      } else if (lockersRaw is List) {
        // If lockers is stored as a List, update the entire array
        final lockersList = List<Object?>.from(lockersRaw as List<Object?>);
        bool found = false;

        for (int i = 0; i < lockersList.length; i++) {
          final item = lockersList[i];
          if (item != null && item is Map) {
            final lockerMap = Map<String, dynamic>.from(
              item as Map<Object?, Object?>,
            );
            if (lockerMap['id'].toString() == lockerId) {
              lockerMap['reservedDocID'] = reservationDocId;
              lockersList[i] = lockerMap;
              found = true;
              break;
            }
          }
        }

        if (found) {
          await _unitsRef.child(unitId).update({'lockers': lockersList});
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating locker reserved doc ID: $e');
      return false;
    }
  }

  /// Set the 'confirmation' field of a locker to a given value - deprecated
  @deprecated
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

  /// Set the 'confirmation' field of a locker to a given value
  Future<bool> setLockerConfirmationByUnitAndLockerId(
    String unitId,
    String lockerId,
    bool confirmation,
  ) async {
    try {
      final snapshot = await _unitsRef.child(unitId).get();
      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<Object?, Object?>?;
      if (data == null || data['lockers'] == null) return false;

      final lockersRaw = data['lockers'];

      if (lockersRaw is Map) {
        // If lockers is stored as a Map, use direct path update
        await _unitsRef.child(unitId).child('lockers').child(lockerId).update({
          'confirmation': confirmation ? 1 : 0,
        });
        return true;
      } else if (lockersRaw is List) {
        // If lockers is stored as a List, update the entire array
        final lockersList = List<Object?>.from(lockersRaw as List<Object?>);
        bool found = false;

        for (int i = 0; i < lockersList.length; i++) {
          final item = lockersList[i];
          if (item != null && item is Map) {
            final lockerMap = Map<String, dynamic>.from(
              item as Map<Object?, Object?>,
            );
            if (lockerMap['id'].toString() == lockerId) {
              lockerMap['confirmation'] = confirmation ? 1 : 0;
              lockersList[i] = lockerMap;
              found = true;
              break;
            }
          }
        }

        if (found) {
          await _unitsRef.child(unitId).update({'lockers': lockersList});
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating locker confirmation: $e');
      return false;
    }
  }

  /// Add a reservation record to the reservations collection
  Future<String?> addReservation({
    required String userId,
    required String unitId,
    required String lockerId,
    required DateTime timestamp,
  }) async {
    try {
      final reservationRef = _reservationsRef.push();
      await reservationRef.set({
        'timestamp': timestamp.toIso8601String(),
        'userID': userId,
        'unitID': unitId,
        'lockerID': lockerId,
        'active': true,
      });
      return reservationRef.key; // Return the document ID
    } catch (e) {
      return null;
    }
  }

  /// Set the 'reserved' field of a locker to true - deprecated
  @deprecated
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

  /// Set the 'reserved' field of a locker
  Future<bool> setLockerReservedByUnitAndLockerId(
    String unitId,
    String lockerId,
    bool reserved,
  ) async {
    try {
      final snapshot = await _unitsRef.child(unitId).get();
      if (!snapshot.exists) return false;

      final data = snapshot.value as Map<Object?, Object?>?;
      if (data == null || data['lockers'] == null) return false;

      final lockersRaw = data['lockers'];

      if (lockersRaw is Map) {
        // If lockers is stored as a Map, use direct path update
        await _unitsRef.child(unitId).child('lockers').child(lockerId).update({
          'reserved': reserved,
        });
        return true;
      } else if (lockersRaw is List) {
        // If lockers is stored as a List, update the entire array
        final lockersList = List<Object?>.from(lockersRaw as List<Object?>);
        bool found = false;

        for (int i = 0; i < lockersList.length; i++) {
          final item = lockersList[i];
          if (item != null && item is Map) {
            final lockerMap = Map<String, dynamic>.from(
              item as Map<Object?, Object?>,
            );
            if (lockerMap['id'].toString() == lockerId) {
              lockerMap['reserved'] = reserved;
              lockersList[i] = lockerMap;
              found = true;
              break;
            }
          }
        }

        if (found) {
          await _unitsRef.child(unitId).update({'lockers': lockersList});
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating locker reserved status: $e');
      return false;
    }
  }

  /// Get the latest locker details (for polling) - deprecated
  @deprecated
  Future<Map<String, dynamic>?> getLockerStatusById(String lockerId) async {
    return await getLockerDetailsById(lockerId);
  }

  /// Get the latest locker details (for polling)
  Future<Map<String, dynamic>?> getLockerStatusByUnitAndLockerId(
    String unitId,
    String lockerId,
  ) async {
    return await getLockerDetailsByUnitAndLockerId(unitId, lockerId);
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
