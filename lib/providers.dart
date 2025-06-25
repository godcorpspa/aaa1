import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_repo.dart';
import 'models/matchday.dart';
import 'models/user_data.dart';

final repoProvider = Provider((_) => FirestoreRepo());

final authProvider = StreamProvider<User?>(
    (_) => FirebaseAuth.instance.authStateChanges());

final matchdayProvider =
    FutureProvider<Matchday>((ref) => ref.read(repoProvider).fetchNextMatchday());

/*final userDataProvider = StreamProvider<UserData>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) throw UnimplementedError();
  return ref.read(repoProvider).streamUserData(user.uid);
});*/

final userDataProvider = StreamProvider<UserData>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) throw UnimplementedError();
  return ref.read(repoProvider).streamUserData(user.uid);
});