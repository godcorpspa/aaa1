// lib/services/league_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/league_models.dart';

class LeagueService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  
  LeagueService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // === CREAZIONE LEGA ===
  
  /// Crea una nuova lega Last Man Standing
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
    if (user == null) throw Exception('Utente non autenticato');

    final leagueId = _db.collection('leagues').doc().id;
    final inviteCode = _generateInviteCode();
    
    final league = LastManStandingLeague(
      id: leagueId,
      name: name.trim(),
      description: description.trim(),
      creatorId: user.uid,
      creatorName: user.displayName ?? 'Utente',
      createdAt: DateTime.now(),
      isPrivate: isPrivate,
      requirePassword: requirePassword,
      password: requirePassword ? password : null,
      maxParticipants: maxParticipants,
      currentParticipants: 1,
      participants: [user.uid],
      admins: [user.uid],
      status: LeagueStatus.waiting,
      settings: settings ?? const LeagueSettings(),
      inviteCode: inviteCode,
    );

    try {
      await _db.runTransaction((transaction) async {
        // Crea la lega
        final leagueRef = _db.collection('leagues').doc(leagueId);
        transaction.set(leagueRef, league.toJson());
        
        // Aggiungi il creatore come partecipante
        final participantRef = leagueRef.collection('participants').doc(user.uid);
        final participant = LeagueParticipant(
          userId: user.uid,
          displayName: user.displayName ?? 'Utente',
          email: user.email,
          joinedAt: DateTime.now(),
          isAdmin: true,
        );
        transaction.set(participantRef, participant.toJson());
        
        // Aggiorna il profilo utente
        final userRef = _db.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'currentLeagues': FieldValue.arrayUnion([leagueId]),
          'createdLeagues': FieldValue.arrayUnion([leagueId]),
        });
      });

      return league;
    } catch (e) {
      throw LeagueException('Errore nella creazione della lega: $e');
    }
  }

  // === RICERCA E JOIN LEGHE ===
  
  /// Cerca leghe pubbliche
  Future<List<LastManStandingLeague>> searchPublicLeagues({
    String? query,
    int limit = 20,
  }) async {
    try {
      Query leaguesQuery = _db
          .collection('leagues')
          .where('isPrivate', isEqualTo: false)
          .where('status', isEqualTo: LeagueStatus.waiting.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (query != null && query.trim().isNotEmpty) {
        // Firestore non supporta ricerca full-text, implementa logica base
        leaguesQuery = leaguesQuery.where('name', isGreaterThanOrEqualTo: query);
      }

      final snapshot = await leaguesQuery.get();
      return snapshot.docs
          .map((doc) => LastManStandingLeague.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              }))
          .toList();
    } catch (e) {
      throw LeagueException('Errore nella ricerca delle leghe: $e');
    }
  }

  /// Trova lega per codice invito
  Future<LastManStandingLeague?> findLeagueByInviteCode(String inviteCode) async {
    try {
      final snapshot = await _db
          .collection('leagues')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return LastManStandingLeague.fromJson({
        'id': doc.id,
        ...doc.data()
      });
    } catch (e) {
      throw LeagueException('Errore nella ricerca della lega: $e');
    }
  }

  /// Unisciti a una lega
  Future<void> joinLeague({
    required String leagueId,
    String? password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Validazioni
        if (league.participants.contains(user.uid)) {
          throw LeagueException('Sei già membro di questa lega');
        }

        if (!league.canJoin) {
          throw LeagueException('Impossibile unirsi a questa lega');
        }

        if (league.requirePassword && league.password != password) {
          throw LeagueException('Password non corretta');
        }

        // Aggiungi partecipante
        final participantRef = leagueRef.collection('participants').doc(user.uid);
        final participant = LeagueParticipant(
          userId: user.uid,
          displayName: user.displayName ?? 'Utente',
          email: user.email,
          joinedAt: DateTime.now(),
        );
        transaction.set(participantRef, participant.toJson());

        // Aggiorna la lega
        transaction.update(leagueRef, {
          'participants': FieldValue.arrayUnion([user.uid]),
          'currentParticipants': FieldValue.increment(1),
        });

        // Aggiorna il profilo utente
        final userRef = _db.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'currentLeagues': FieldValue.arrayUnion([leagueId]),
        });
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nell\'unirsi alla lega: $e');
    }
  }

  // === GESTIONE LEGHE UTENTE ===
  
  /// Ottieni le leghe dell'utente corrente
  Stream<List<LastManStandingLeague>> getUserLeagues() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('leagues')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LastManStandingLeague.fromJson({
                  'id': doc.id,
                  ...doc.data()
                }))
            .toList());
  }

  /// Verifica se l'utente ha leghe attive
  Future<bool> userHasActiveLeagues() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _db
          .collection('leagues')
          .where('participants', arrayContains: user.uid)
          .where('status', whereIn: [
            LeagueStatus.waiting.name,
            LeagueStatus.active.name,
          ])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Ottieni dettagli di una lega specifica
  Future<LastManStandingLeague?> getLeague(String leagueId) async {
    try {
      final doc = await _db.collection('leagues').doc(leagueId).get();
      if (!doc.exists) return null;

      return LastManStandingLeague.fromJson({
        'id': doc.id,
        ...doc.data()!
      });
    } catch (e) {
      throw LeagueException('Errore nel recupero della lega: $e');
    }
  }

  /// Ottieni partecipanti di una lega
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

  // === GESTIONE PARTECIPANTI ===

  /// Lascia una lega
  Future<void> leaveLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Non permettere al creatore di lasciare la lega
        if (league.creatorId == user.uid) {
          throw LeagueException('Il creatore non può lasciare la lega. Cancellala invece.');
        }

        // Rimuovi partecipante
        final participantRef = leagueRef.collection('participants').doc(user.uid);
        transaction.delete(participantRef);

        // Aggiorna la lega
        transaction.update(leagueRef, {
          'participants': FieldValue.arrayRemove([user.uid]),
          'currentParticipants': FieldValue.increment(-1),
        });

        // Aggiorna il profilo utente
        final userRef = _db.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'currentLeagues': FieldValue.arrayRemove([leagueId]),
        });
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nell\'uscire dalla lega: $e');
    }
  }

  /// Rimuovi un partecipante (solo admin)
  Future<void> removeParticipant(String leagueId, String participantId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Verifica permessi admin
        if (!league.isAdmin(user.uid)) {
          throw LeagueException('Non hai i permessi per rimuovere partecipanti');
        }

        // Non permettere di rimuovere il creatore
        if (league.creatorId == participantId) {
          throw LeagueException('Non puoi rimuovere il creatore della lega');
        }

        // Rimuovi partecipante
        final participantRef = leagueRef.collection('participants').doc(participantId);
        transaction.delete(participantRef);

        // Aggiorna la lega
        transaction.update(leagueRef, {
          'participants': FieldValue.arrayRemove([participantId]),
          'admins': FieldValue.arrayRemove([participantId]),
          'currentParticipants': FieldValue.increment(-1),
        });

        // Aggiorna il profilo dell'utente rimosso
        final removedUserRef = _db.collection('users').doc(participantId);
        transaction.update(removedUserRef, {
          'currentLeagues': FieldValue.arrayRemove([leagueId]),
        });
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nella rimozione del partecipante: $e');
    }
  }

  // === GESTIONE LEGA ===

  /// Avvia una lega (solo creator/admin)
  Future<void> startLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Verifica permessi
        if (!league.isAdmin(user.uid)) {
          throw LeagueException('Non hai i permessi per avviare la lega');
        }

        // Verifica stato
        if (league.status != LeagueStatus.waiting) {
          throw LeagueException('La lega non è in stato di attesa');
        }

        // Verifica numero minimo partecipanti
        if (league.currentParticipants < 2) {
          throw LeagueException('Servono almeno 2 partecipanti per iniziare');
        }

        // Avvia la lega
        transaction.update(leagueRef, {
          'status': LeagueStatus.active.name,
          'startDate': FieldValue.serverTimestamp(),
          'stats.activePlayers': league.currentParticipants,
        });
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nell\'avvio della lega: $e');
    }
  }

  /// Cancella una lega (solo creator)
  Future<void> deleteLeague(String leagueId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Solo il creatore può cancellare
        if (league.creatorId != user.uid) {
          throw LeagueException('Solo il creatore può cancellare la lega');
        }

        // Non cancellare se la lega è attiva e ha partite in corso
        if (league.status == LeagueStatus.active && league.stats.currentRound > 0) {
          throw LeagueException('Impossibile cancellare una lega con partite in corso');
        }

        // Segna come cancellata invece di eliminare
        transaction.update(leagueRef, {
          'status': LeagueStatus.cancelled.name,
          'endDate': FieldValue.serverTimestamp(),
        });

        // Rimuovi la lega dai profili di tutti i partecipanti
        for (final participantId in league.participants) {
          final userRef = _db.collection('users').doc(participantId);
          transaction.update(userRef, {
            'currentLeagues': FieldValue.arrayRemove([leagueId]),
          });
        }
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nella cancellazione della lega: $e');
    }
  }

  /// Aggiorna impostazioni lega (solo admin)
  Future<void> updateLeagueSettings({
    required String leagueId,
    required LeagueSettings newSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    try {
      await _db.runTransaction((transaction) async {
        final leagueRef = _db.collection('leagues').doc(leagueId);
        final leagueDoc = await transaction.get(leagueRef);
        
        if (!leagueDoc.exists) {
          throw LeagueException('Lega non trovata');
        }

        final league = LastManStandingLeague.fromJson({
          'id': leagueDoc.id,
          ...leagueDoc.data()!
        });

        // Verifica permessi
        if (!league.isAdmin(user.uid)) {
          throw LeagueException('Non hai i permessi per modificare le impostazioni');
        }

        // Non modificare se la lega è già iniziata (tranne alcune impostazioni)
        if (league.hasStarted) {
          throw LeagueException('Impossibile modificare le impostazioni di una lega già iniziata');
        }

        transaction.update(leagueRef, {
          'settings': newSettings.toJson(),
        });
      });
    } catch (e) {
      if (e is LeagueException) rethrow;
      throw LeagueException('Errore nell\'aggiornamento delle impostazioni: $e');
    }
  }

  // === UTILITÀ PRIVATE ===

  /// Genera un codice invito univoco
  String _generateInviteCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs();
    return 'LMS${random.toString().substring(0, 6).toUpperCase()}';
  }

  /// Pulisci risorse
  void dispose() {
    // Cleanup se necessario
  }
}

// === ECCEZIONI PERSONALIZZATE ===

class LeagueException implements Exception {
  final String message;
  final String? code;
  
  const LeagueException(this.message, [this.code]);
  
  @override
  String toString() => 'LeagueException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Eccezioni specifiche
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