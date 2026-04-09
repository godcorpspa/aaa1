import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/matchday.dart';
import '../models/pick.dart';
import '../models/user_data.dart';
import 'football_data_service.dart';

class FirestoreRepo {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FootballDataService _footballService;

  Matchday? _cachedMatchday;
  DateTime? _lastMatchdayFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  FirestoreRepo({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FootballDataService? footballService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _footballService = footballService ?? FootballDataService();

  Future<Matchday> fetchNextMatchday() async {
    if (_cachedMatchday != null &&
        _lastMatchdayFetch != null &&
        DateTime.now().difference(_lastMatchdayFetch!) < _cacheDuration) {
      return _cachedMatchday!;
    }

    // Prima prova da Firestore
    try {
      final snap = await _db
          .collection('matchdays')
          .doc('next')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.exists && snap.data() != null) {
        final matchday = Matchday.fromJson(snap.data()!);
        _cachedMatchday = matchday;
        _lastMatchdayFetch = DateTime.now();
        return matchday;
      }
    } catch (_) {
      // Fallback all'API se Firestore fallisce
    }

    // Se non esiste su Firestore, crea da API reale
    return await _createMatchdayFromApi();
  }

  /// Crea giornata usando dati reali dall'API Football-Data.org.
  ///
  /// Chiave: targettiamo la PROSSIMA giornata giocabile (la più piccola con
  /// almeno una partita ancora SCHEDULED), non quella attualmente in corso.
  /// La deadline coincide con il calcio d'inizio della prima partita della
  /// giornata: è "aperto" finché quella partita non inizia.
  Future<Matchday> _createMatchdayFromApi() async {
    try {
      final next = await _footballService.getNextPlayableMatchday();

      DateTime deadline;
      DateTime? startDate;
      DateTime? endDate;

      if (next.matches.isNotEmpty) {
        startDate = next.firstMatch!.date;
        endDate = next.lastMatch!.date;
        // Deadline = kickoff della prima partita (picks chiusi all'inizio).
        deadline = startDate;
      } else {
        // Nessuna partita SCHEDULED trovata: fallback a un lunedì futuro.
        final now = DateTime.now();
        deadline = now.add(const Duration(days: 7));
      }

      final giornata = next.matchday < 1 ? 1 : next.matchday;
      final isOpen = DateTime.now().isBefore(deadline);

      final matchday = Matchday(
        giornata: giornata,
        deadline: deadline,
        availableTeams: const [],
        doubleChoiceAvailable: true,
        status: isOpen ? MatchdayStatus.active : MatchdayStatus.closed,
        startDate: startDate,
        endDate: endDate,
      );

      _cachedMatchday = matchday;
      _lastMatchdayFetch = DateTime.now();
      return matchday;
    } catch (_) {
      throw const MatchdayNotFoundException();
    }
  }

  Stream<UserData> streamUserData(String uid) {
    if (uid.isEmpty) throw const InvalidUserIdException();

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        _createDefaultUserDocument(uid);
        return UserData(teamsUsed: []);
      }
      return UserData.fromJson(snap.data()!);
    });
  }

  Stream<List<Pick>> streamUserPicks(String uid) {
    if (uid.isEmpty) throw const InvalidUserIdException();

    return _db
        .collection('users')
        .doc(uid)
        .collection('picks')
        .orderBy('giornata', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Pick.fromJson(doc.data())).toList());
  }

  /// Submit a pick with transaction-based validation
  Future<void> submitPick(String uid, Pick pick) async {
    if (uid.isEmpty) throw const InvalidUserIdException();
    await _validatePick(uid, pick);

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(uid);
      final pickRef =
          userRef.collection('picks').doc(pick.giornata.toString());

      final existingPick = await tx.get(pickRef);
      if (existingPick.exists) throw const PickAlreadyExistsException();

      final userDoc = await tx.get(userRef);
      UserData userData;
      if (!userDoc.exists) {
        userData = UserData(teamsUsed: []);
        tx.set(userRef, userData.toJson());
      } else {
        userData = UserData.fromJson(userDoc.data()!);
      }

      if (userData.hasUsedTeam(pick.team)) {
        throw TeamAlreadyUsedException(pick.team);
      }
      if (pick.secondTeam != null && userData.hasUsedTeam(pick.secondTeam!)) {
        throw TeamAlreadyUsedException(pick.secondTeam!);
      }

      tx.set(pickRef, pick.toJson());

      final teamsToAdd = [pick.team];
      if (pick.secondTeam != null) teamsToAdd.add(pick.secondTeam!);

      tx.update(userRef, {
        'teamsUsed': FieldValue.arrayUnion(teamsToAdd),
        'lastPickDate': FieldValue.serverTimestamp(),
      });
    });

    _invalidateCache();
  }

  /// Use a Gold Ticket for automatic survival on a matchday
  Future<void> useGoldTicket(String uid, int giornata) async {
    if (uid.isEmpty) throw const InvalidUserIdException();

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(uid);
      final userDoc = await tx.get(userRef);

      if (!userDoc.exists) throw const UserNotFoundException();
      final userData = UserData.fromJson(userDoc.data()!);

      if (!userData.hasGoldTicket) {
        throw const NoGoldTicketException();
      }

      final pickRef =
          userRef.collection('picks').doc(giornata.toString());
      final pickDoc = await tx.get(pickRef);

      if (pickDoc.exists) {
        throw const PickAlreadyExistsException();
      }

      final goldTicketPick = Pick(
        giornata: giornata,
        team: 'GOLD_TICKET',
        usedGoldTicket: true,
        result: PickResult.win,
      );

      tx.set(pickRef, goldTicketPick.toJson());
      tx.update(userRef, {
        'goldTickets': userData.goldTickets - 1,
      });
    });
  }

  /// Award a Gold Ticket after a successful Double Choice
  Future<void> awardGoldTicket(String uid) async {
    if (uid.isEmpty) throw const InvalidUserIdException();

    await _db.collection('users').doc(uid).update({
      'goldTickets': FieldValue.increment(1),
    });
  }

  /// Auto-assign the first alphabetically-available team to a user who
  /// missed the deadline. Idempotent: does nothing if a pick already exists
  /// or if the user is eliminated / has no teams left.
  ///
  /// [allTeams] is the pool of Serie A teams to choose from (normally from
  /// `FootballDataService.getTeamNames()`).
  Future<Pick?> autoAssignPickIfMissed({
    required String uid,
    required int giornata,
    required List<String> allTeams,
  }) async {
    if (uid.isEmpty) throw const InvalidUserIdException();
    if (allTeams.isEmpty) return null;

    Pick? assignedPick;

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(uid);
      final pickRef = userRef.collection('picks').doc(giornata.toString());

      final pickDoc = await tx.get(pickRef);
      if (pickDoc.exists) return; // User already picked.

      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) return;
      final userData = UserData.fromJson(userDoc.data()!);
      if (!userData.isActive) return; // Eliminated users don't auto-pick.

      final team = userData.getAutoAssignTeam(allTeams);
      if (team == null) return; // No teams left.

      final pick = Pick(
        giornata: giornata,
        team: team,
        autoAssigned: true,
      );

      tx.set(pickRef, pick.toJson());
      tx.update(userRef, {
        'teamsUsed': FieldValue.arrayUnion([team]),
        'lastPickDate': FieldValue.serverTimestamp(),
      });

      assignedPick = pick;
    });

    _invalidateCache();
    return assignedPick;
  }

  Future<List<UserRanking>> getLeaderboard() async {
    final query = await _db
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('currentStreak', descending: true)
        .orderBy('totalSurvivals', descending: true)
        .limit(100)
        .get();

    return query.docs.map((doc) {
      return UserRanking.fromJson({...doc.data(), 'uid': doc.id});
    }).toList();
  }

  Future<void> _validatePick(String uid, Pick pick) async {
    if (pick.giornata < 1 || pick.giornata > 38) {
      throw const InvalidMatchdayException();
    }
    if (pick.team.trim().isEmpty) throw const InvalidTeamException();

    final matchday = await fetchNextMatchday();
    if (DateTime.now().isAfter(matchday.deadline)) {
      throw const DeadlineExpiredException();
    }
    if (pick.giornata != matchday.giornata) {
      throw const WrongMatchdayException();
    }
  }

  Future<void> _createDefaultUserDocument(String uid) async {
    final user = _auth.currentUser;
    await _db.collection('users').doc(uid).set({
      'goldTickets': 0,
      'teamsUsed': <String>[],
      'isActive': true,
      'currentStreak': 0,
      'totalSurvivals': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'displayName': _resolveDisplayName(user),
      'email': user?.email,
    });
  }

  /// Returns a human-readable display name for a Firebase user.
  ///
  /// Order of fallback:
  ///  1. `user.displayName` (set by Google/Apple providers)
  ///  2. Local part of the email (e.g. "mario.rossi" from "mario.rossi@x.it")
  ///  3. A short suffix of the uid as a last resort
  String _resolveDisplayName(User? user) {
    final raw = user?.displayName?.trim();
    if (raw != null && raw.isNotEmpty) return raw;

    final email = user?.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }

    final uid = user?.uid ?? '';
    if (uid.isNotEmpty) {
      return 'Player ${uid.substring(0, uid.length > 6 ? 6 : uid.length)}';
    }
    return 'Player';
  }

  void _invalidateCache() {
    _cachedMatchday = null;
    _lastMatchdayFetch = null;
  }

  void dispose() {
    _invalidateCache();
    _footballService.dispose();
  }
}

// === EXCEPTIONS ===

class FirestoreException implements Exception {
  final String message;
  final String? code;
  const FirestoreException(this.message, [this.code]);
  @override
  String toString() => message;
}

class MatchdayNotFoundException implements Exception {
  const MatchdayNotFoundException();
  @override
  String toString() => 'Dati della giornata non trovati';
}

class InvalidUserIdException implements Exception {
  const InvalidUserIdException();
  @override
  String toString() => 'ID utente non valido';
}

class UserNotFoundException implements Exception {
  const UserNotFoundException();
  @override
  String toString() => 'Utente non trovato';
}

class PickAlreadyExistsException implements Exception {
  const PickAlreadyExistsException();
  @override
  String toString() => 'Hai già fatto una scelta per questa giornata';
}

class TeamAlreadyUsedException implements Exception {
  final String team;
  const TeamAlreadyUsedException(this.team);
  @override
  String toString() => 'Hai già usato la squadra: $team';
}

class InvalidMatchdayException implements Exception {
  const InvalidMatchdayException();
  @override
  String toString() => 'Numero giornata non valido';
}

class InvalidTeamException implements Exception {
  const InvalidTeamException();
  @override
  String toString() => 'Nome squadra non valido';
}

class DeadlineExpiredException implements Exception {
  const DeadlineExpiredException();
  @override
  String toString() => 'Termine per le scelte scaduto';
}

class WrongMatchdayException implements Exception {
  const WrongMatchdayException();
  @override
  String toString() => 'Giornata non corrispondente';
}

class NoGoldTicketException implements Exception {
  const NoGoldTicketException();
  @override
  String toString() => 'Non hai Gold Ticket disponibili';
}

class PickNotFoundException implements Exception {
  const PickNotFoundException();
  @override
  String toString() => 'Scelta non trovata';
}

class UserRanking {
  final String uid;
  final String displayName;
  final int currentStreak;
  final int totalSurvivals;
  final bool isActive;

  UserRanking({
    required this.uid,
    required this.displayName,
    required this.currentStreak,
    required this.totalSurvivals,
    required this.isActive,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Utente',
      currentStreak: json['currentStreak'] ?? 0,
      totalSurvivals: json['totalSurvivals'] ?? json['totalWins'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
