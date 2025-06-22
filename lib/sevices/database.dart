import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference _unitsCollection = FirebaseFirestore.instance
      .collection('units');

  /// Get all unit documents (for marker loading)
  Future<List<QueryDocumentSnapshot>> getAllUnitDocs() async {
    QuerySnapshot snapshot =
        await _unitsCollection
            .where('deleted', isEqualTo: false)
            .where('status', isEqualTo: 'available')
            .get();
    return snapshot.docs;
  }

  /// Get a unit document by its Firestore document ID
  Future<DocumentSnapshot> getUnitById(String id) async {
    return await _unitsCollection.doc(id).get();
  }

  /// Get the unit document that contains a locker with the given lockerId
  Future<DocumentSnapshot?> getUnitByLockerId(String lockerId) async {
    // Firestore does not support querying nested array objects directly by field value,
    // so we fetch units with status 'available' and filter in Dart.
    QuerySnapshot snapshot =
        await _unitsCollection
            .where('deleted', isEqualTo: false)
            .where('status', isEqualTo: 'available')
            .get();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['lockers'] != null) {
        final lockers = List<Map<String, dynamic>>.from(data['lockers']);
        for (var locker in lockers) {
          if (locker['id'] == lockerId) {
            return doc;
          }
        }
      }
    }
    return null;
  }

  /// Get locker details (unit doc, locker map, locker index) by lockerId
  Future<Map<String, dynamic>?> getLockerDetailsById(String lockerId) async {
    QuerySnapshot snapshot =
        await _unitsCollection
            .where('deleted', isEqualTo: false)
            .where('status', isEqualTo: 'available')
            .get();
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['lockers'] != null) {
        final lockers = List<Map<String, dynamic>>.from(data['lockers']);
        for (var i = 0; i < lockers.length; i++) {
          if (lockers[i]['id'] == lockerId) {
            return {'unitDoc': doc, 'locker': lockers[i], 'lockerIndex': i};
          }
        }
      }
    }
    return null;
  }

  /// Set the 'locked' field of a locker to false (unlock)
  Future<bool> unlockLocker(String lockerId) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final doc = details['unitDoc'] as DocumentSnapshot;
    final lockerIndex = details['lockerIndex'] as int;
    final data = doc.data() as Map<String, dynamic>;
    final lockers = List<Map<String, dynamic>>.from(data['lockers']);
    lockers[lockerIndex]['locked'] = false;
    await _unitsCollection.doc(doc.id).update({'lockers': lockers});
    return true;
  }

  /// Set the 'locked' field of a locker to a given value (lock/unlock)
  Future<bool> setLockerLocked(String lockerId, bool locked) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final doc = details['unitDoc'] as DocumentSnapshot;
    final lockerIndex = details['lockerIndex'] as int;
    final data = doc.data() as Map<String, dynamic>;
    final lockers = List<Map<String, dynamic>>.from(data['lockers']);
    lockers[lockerIndex]['locked'] = locked;
    await _unitsCollection.doc(doc.id).update({'lockers': lockers});
    return true;
  }

  /// Set the 'confirmation' field of a locker to a given value
  Future<bool> setLockerConfirmation(String lockerId, bool confirmation) async {
    final details = await getLockerDetailsById(lockerId);
    if (details == null) return false;
    final doc = details['unitDoc'] as DocumentSnapshot;
    final lockerIndex = details['lockerIndex'] as int;
    final data = doc.data() as Map<String, dynamic>;
    final lockers = List<Map<String, dynamic>>.from(data['lockers']);
    lockers[lockerIndex]['confirmation'] = confirmation;
    await _unitsCollection.doc(doc.id).update({'lockers': lockers});
    return true;
  }

  /// Add a reservation record to the reservations collection
  Future<bool> addReservation({
    required String userId,
    required String lockerId,
    required DateTime timestamp,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reservations').add({
        'timestamp': timestamp,
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
    final doc = details['unitDoc'] as DocumentSnapshot;
    final lockerIndex = details['lockerIndex'] as int;
    final data = doc.data() as Map<String, dynamic>;
    final lockers = List<Map<String, dynamic>>.from(data['lockers']);
    lockers[lockerIndex]['reserved'] = reserved;
    await _unitsCollection.doc(doc.id).update({'lockers': lockers});
    return true;
  }

  /// Get the latest locker details (for polling)
  Future<Map<String, dynamic>?> getLockerStatusById(String lockerId) async {
    return await getLockerDetailsById(lockerId);
  }
}
