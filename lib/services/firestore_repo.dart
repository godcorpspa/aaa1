import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/matchday.dart';
import '../models/pick.dart';
import '../models/user_data.dart';

class FirestoreRepo {
  final _db = FirebaseFirestore.instance;

  Future<Matchday> fetchNextMatchday() async {
    final snap = await _db.collection('matchdays').doc('next').get();
    return Matchday.fromJson(snap.data()!);
  }

  /*Stream<UserData> streamUserData(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => UserData.fromJson(s.data()!));*/

  Stream<UserData> streamUserData(String uid) => _db
    .collection('users')
    .doc(uid)
    .snapshots()
    .map((snap) {
      final data = snap.data();
      if (data == null) {
        // documento mancante → valori di default
        return UserData(jollyLeft: 0, teamsUsed: []);
      }
      return UserData.fromJson(data);
    });

  Future<void> submitPick(String uid, Pick pick) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('picks')
        .doc(pick.giornata.toString())
        .set(pick.toJson());
    await _db.collection('users').doc(uid).update({
      'teamsUsed': FieldValue.arrayUnion([pick.team])
    });
  }
}