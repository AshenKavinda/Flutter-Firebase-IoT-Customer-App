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
}
