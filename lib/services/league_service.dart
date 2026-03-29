import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/league_models.dart';

class LeagueService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  LeagueService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<LastManStandingLeague> createLeague({
    required String name,
    required String description,
    required int maxParticipants,
    bool isPrivate = false,
    bool requirePassword = false,
    String? password,
    LeagueSettings? settings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    final leagueId = _db.collection('leagues').doc().id;
    final inviteCode = LastManStandingLeague.generateInviteCode();

    final league = LastManStandingLeague(
      id: leagueId,
      name: name.trim(),
      description: description.trim(),
      creatorId: user.uid,
      creatorName: user.displayName ?? 'Utente',
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
      requirePassword: requirePassword,
      passwordHash: requirePassword ? password : null,
      maxParticipants: maxParticipants,
      currentParticipants: 1,
      participants: [user.uid],
      admins: [user.uid],
      status: LeagueStatus.waiting,
      settings: settings ?? const LeagueSettings(),
      inviteCode: inviteCode,
    );

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      tx.set(leagueRef, league.toJson());

      final participantRef =
          leagueRef.collection('participants').doc(user.uid);
      final participant = LeagueParticipant(
        userId: user.uid,
        displayName: user.displayName ?? 'Utente',
        email: user.email,
        joinedAt: DateTime.now(),
        isAdmin: true,
      );
      tx.set(participantRef, participant.toJson());

      final userRef = _db.collection('users').doc(user.uid);
      tx.set(
        userRef,
        {
          'currentLeagues': FieldValue.arrayUnion([leagueId]),
          'createdLeagues': FieldValue.arrayUnion([leagueId]),
        },
        SetOptions(merge: true),
      );
    });

    return league;
  }

  Future<List<LastManStandingLeague>> searchPublicLeagues({
    String? query,
    int limit = 20,
  }) async {
    final snapshot = await _db
        .collection('leagues')
        .where('isPrivate', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    var leagues = snapshot.docs
        .map((doc) {
          try {
            return LastManStandingLeague.fromJson({
              'id': doc.id,
              ...doc.data(),
            });
          } catch (_) {
            return null;
          }
        })
        .whereType<LastManStandingLeague>()
        .where((l) => !l.isPrivate && l.status == LeagueStatus.waiting)
        .toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      leagues = leagues
          .where((l) =>
              l.name.toLowerCase().contains(q) ||
              l.description.toLowerCase().contains(q))
          .toList();
    }

    return leagues;
  }

  Future<LastManStandingLeague?> findLeagueByInviteCode(
      String inviteCode) async {
    final snapshot = await _db
        .collection('leagues')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return LastManStandingLeague.fromJson({'id': doc.id, ...doc.data()});
  }

  Future<void> joinLeague({
    required String leagueId,
    String? password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (league.participants.contains(user.uid)) {
        throw const AlreadyMemberException();
      }
      if (!league.canJoin) {
        throw const LeagueException('Impossibile unirsi a questa lega');
      }
      if (league.requirePassword && league.passwordHash != password) {
        throw const InvalidPasswordException();
      }

      final participantRef =
          leagueRef.collection('participants').doc(user.uid);
      final participant = LeagueParticipant(
        userId: user.uid,
        displayName: user.displayName ?? 'Utente',
        email: user.email,
        joinedAt: DateTime.now(),
      );
      tx.set(participantRef, participant.toJson());

      tx.update(leagueRef, {
        'participants': FieldValue.arrayUnion([user.uid]),
        'currentParticipants': FieldValue.increment(1),
      });

      final userRef = _db.collection('users').doc(user.uid);
      tx.set(
        userRef,
        {'currentLeagues': FieldValue.arrayUnion([leagueId])},
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<LastManStandingLeague>> getUserLeagues([String? userId]) {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return Stream.value([]);

    return _db
        .collection('leagues')
        .where('participants', arrayContains: targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LastManStandingLeague.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  Future<bool> userHasActiveLeagues([String? userId]) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return false;

    final snapshot = await _db
        .collection('leagues')
        .where('participants', arrayContains: targetUserId)
        .where('status', whereIn: [
          LeagueStatus.waiting.name,
          LeagueStatus.active.name,
        ])
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<LastManStandingLeague?> getLeague(String leagueId) async {
    final doc = await _db.collection('leagues').doc(leagueId).get();
    if (!doc.exists) return null;
    return LastManStandingLeague.fromJson({'id': doc.id, ...doc.data()!});
  }

  Stream<List<LeagueParticipant>> getLeagueParticipants(String leagueId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('participants')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeagueParticipant.fromJson(doc.data()))
            .toList());
  }

  Future<void> leaveLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (league.creatorId == user.uid) {
        throw const LeagueException(
            'Il creatore non può lasciare la lega. Cancellala invece.');
      }

      tx.delete(leagueRef.collection('participants').doc(user.uid));
      tx.update(leagueRef, {
        'participants': FieldValue.arrayRemove([user.uid]),
        'currentParticipants': FieldValue.increment(-1),
      });
      tx.update(_db.collection('users').doc(user.uid), {
        'currentLeagues': FieldValue.arrayRemove([leagueId]),
      });
    });
  }

  Future<void> removeParticipant(
      String leagueId, String participantId) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (!league.isAdmin(user.uid)) {
        throw const PermissionDeniedException();
      }
      if (league.creatorId == participantId) {
        throw const LeagueException(
            'Non puoi rimuovere il creatore della lega');
      }

      tx.delete(leagueRef.collection('participants').doc(participantId));
      tx.update(leagueRef, {
        'participants': FieldValue.arrayRemove([participantId]),
        'admins': FieldValue.arrayRemove([participantId]),
        'currentParticipants': FieldValue.increment(-1),
      });
      tx.update(_db.collection('users').doc(participantId), {
        'currentLeagues': FieldValue.arrayRemove([leagueId]),
      });
    });
  }

  Future<void> startLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (!league.isAdmin(user.uid)) {
        throw const PermissionDeniedException();
      }
      if (league.status != LeagueStatus.waiting) {
        throw const LeagueAlreadyStartedException();
      }
      if (league.currentParticipants < 2) {
        throw const LeagueException(
            'Servono almeno 2 partecipanti per iniziare');
      }

      tx.update(leagueRef, {
        'status': LeagueStatus.active.name,
        'startDate': FieldValue.serverTimestamp(),
        'stats.activePlayers': league.currentParticipants,
      });
    });
  }

  Future<void> deleteLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (league.creatorId != user.uid) {
        throw const LeagueException(
            'Solo il creatore può cancellare la lega');
      }

      tx.update(leagueRef, {
        'status': LeagueStatus.cancelled.name,
        'endDate': FieldValue.serverTimestamp(),
      });

      for (final pid in league.participants) {
        tx.update(_db.collection('users').doc(pid), {
          'currentLeagues': FieldValue.arrayRemove([leagueId]),
        });
      }
    });
  }

  Future<void> updateLeagueSettings({
    required String leagueId,
    required LeagueSettings newSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const LeagueException('Utente non autenticato');

    await _db.runTransaction((tx) async {
      final leagueRef = _db.collection('leagues').doc(leagueId);
      final leagueDoc = await tx.get(leagueRef);

      if (!leagueDoc.exists) throw const LeagueNotFoundException();

      final league = LastManStandingLeague.fromJson({
        'id': leagueDoc.id,
        ...leagueDoc.data()!,
      });

      if (!league.isAdmin(user.uid)) {
        throw const PermissionDeniedException();
      }
      if (league.hasStarted) {
        throw const LeagueException(
            'Impossibile modificare le impostazioni di una lega già iniziata');
      }

      tx.update(leagueRef, {'settings': newSettings.toJson()});
    });
  }

  void dispose() {}
}

// === EXCEPTIONS ===

class LeagueException implements Exception {
  final String message;
  final String? code;
  const LeagueException(this.message, [this.code]);
  @override
  String toString() => message;
}

class LeagueNotFoundException extends LeagueException {
  const LeagueNotFoundException() : super('Lega non trovata');
}

class LeagueFullException extends LeagueException {
  const LeagueFullException() : super('La lega è al completo');
}

class InvalidPasswordException extends LeagueException {
  const InvalidPasswordException() : super('Password non corretta');
}

class PermissionDeniedException extends LeagueException {
  const PermissionDeniedException() : super('Permessi insufficienti');
}

class LeagueAlreadyStartedException extends LeagueException {
  const LeagueAlreadyStartedException() : super('La lega è già iniziata');
}

class AlreadyMemberException extends LeagueException {
  const AlreadyMemberException() : super('Sei già membro di questa lega');
}
