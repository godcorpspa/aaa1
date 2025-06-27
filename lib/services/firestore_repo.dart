import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/matchday.dart';
import '../models/pick.dart';
import '../models/user_data.dart';

/// Repository per operazioni Firestore con gestione errori migliorata
class FirestoreRepo {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  
  // Cache per ridurre le chiamate ripetute
  Matchday? _cachedMatchday;
  DateTime? _lastMatchdayFetch;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  FirestoreRepo({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance {
    // Configura settings per performance
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Recupera i dati della prossima giornata con cache
  Future<Matchday> fetchNextMatchday() async {
    try {
      // Controlla se la cache è ancora valida
      if (_cachedMatchday != null && 
          _lastMatchdayFetch != null &&
          DateTime.now().difference(_lastMatchdayFetch!) < _cacheValidityDuration) {
        return _cachedMatchday!;
      }

      final docRef = _db.collection('matchdays').doc('next');
      final snap = await docRef.get(const GetOptions(source: Source.serverAndCache));
      
      if (!snap.exists) {
        throw const MatchdayNotFoundException();
      }
      
      final data = snap.data();
      if (data == null) {
        throw const InvalidMatchdayDataException();
      }
      
      final matchday = Matchday.fromJson(data);
      
      // Aggiorna cache
      _cachedMatchday = matchday;
      _lastMatchdayFetch = DateTime.now();
      
      return matchday;
    } on FirebaseException catch (e) {
      throw FirestoreException('Errore nel recupero della giornata: ${e.message}', e.code);
    } catch (e) {
      throw FirestoreException('Errore sconosciuto nel recupero della giornata: $e');
    }
  }

  /// Stream dei dati utente con gestione errori migliorata
  Stream<UserData> streamUserData(String uid) {
    if (uid.isEmpty) {
      throw const InvalidUserIdException();
    }

    return _db
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: false)
        .map((snap) {
          try {
            // Se il documento non esiste, crea uno di default
            if (!snap.exists) {
              _createDefaultUserDocument(uid);
              return UserData(jollyLeft: 0, teamsUsed: []);
            }
            
            final data = snap.data();
            if (data == null) {
              return UserData(jollyLeft: 0, teamsUsed: []);
            }
            
            return UserData.fromJson(data);
          } catch (e) {
            throw FirestoreException('Errore nella deserializzazione dei dati utente: $e');
          }
        })
        .handleError((error) {
          if (error is FirebaseException) {
            throw FirestoreException('Errore nel stream dati utente: ${error.message}', error.code);
          }
          throw FirestoreException('Errore sconosciuto nel stream dati utente: $error');
        });
  }

  /// Stream delle scelte dell'utente
  Stream<List<Pick>> streamUserPicks(String uid) {
    if (uid.isEmpty) {
      throw const InvalidUserIdException();
    }

    return _db
        .collection('users')
        .doc(uid)
        .collection('picks')
        .orderBy('giornata', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            try {
              final data = doc.data();
              return Pick.fromJson(data);
            } catch (e) {
              throw FirestoreException('Errore nella deserializzazione delle scelte: $e');
            }
          }).toList();
        })
        .handleError((error) {
          if (error is FirebaseException) {
            throw FirestoreException('Errore nel recupero delle scelte: ${error.message}', error.code);
          }
          throw FirestoreException('Errore sconosciuto nel recupero delle scelte: $error');
        });
  }

  /// Invia una scelta con validazione e transazione
  Future<void> submitPick(String uid, Pick pick) async {
    if (uid.isEmpty) {
      throw const InvalidUserIdException();
    }

    // Validazioni preliminari
    await _validatePick(uid, pick);

    try {
      // Usa una transazione per garantire consistenza
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(uid);
        final pickRef = userRef.collection('picks').doc(pick.giornata.toString());
        
        // Verifica che l'utente non abbia già fatto una scelta per questa giornata
        final existingPick = await transaction.get(pickRef);
        if (existingPick.exists) {
          throw const PickAlreadyExistsException();
        }
        
        // Verifica i dati utente correnti
        final userDoc = await transaction.get(userRef);
        UserData userData;
        
        if (!userDoc.exists) {
          // Crea documento utente se non esiste
          userData = UserData(jollyLeft: 0, teamsUsed: []);
          transaction.set(userRef, userData.toJson());
        } else {
          userData = UserData.fromJson(userDoc.data()!);
        }
        
        // Verifica che la squadra non sia già stata usata (a meno che non sia una giornata a tema)
        final matchday = await fetchNextMatchday();
        if (matchday.validTeams.isEmpty && userData.teamsUsed.contains(pick.team)) {
          throw TeamAlreadyUsedException(pick.team);
        }
        
        // Salva la scelta
        transaction.set(pickRef, pick.toJson());
        
        // Aggiorna la lista delle squadre usate solo se non è una giornata a tema
        if (matchday.validTeams.isEmpty) {
          transaction.update(userRef, {
            'teamsUsed': FieldValue.arrayUnion([pick.team]),
            'lastPickDate': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // Invalida cache se necessario
      _invalidateCache();
      
    } on FirebaseException catch (e) {
      throw FirestoreException('Errore nell\'invio della scelta: ${e.message}', e.code);
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException('Errore sconosciuto nell\'invio della scelta: $e');
    }
  }

  /// Acquista un jolly (placeholder per implementazione futura)
  Future<void> purchaseJolly(String uid) async {
    if (uid.isEmpty) {
      throw const InvalidUserIdException();
    }

    try {
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw const UserNotFoundException();
        }
        
        final userData = UserData.fromJson(userDoc.data()!);
        
        if (userData.jollyLeft >= 3) {
          throw const MaxJollyReachedException();
        }
        
        // TODO: Implementare logica di pagamento qui
        
        transaction.update(userRef, {
          'jollyLeft': userData.jollyLeft + 1,
          'lastJollyPurchase': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Errore nell\'acquisto del jolly: ${e.message}', e.code);
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException('Errore sconosciuto nell\'acquisto del jolly: $e');
    }
  }

  /// Usa un jolly per salvarsi da un'eliminazione
  Future<void> useJolly(String uid, int giornata) async {
    if (uid.isEmpty) {
      throw const InvalidUserIdException();
    }

    try {
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(uid);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw const UserNotFoundException();
        }
        
        final userData = UserData.fromJson(userDoc.data()!);
        
        if (userData.jollyLeft <= 0) {
          throw const NoJollyAvailableException();
        }
        
        // Aggiorna la scelta con il jolly usato
        final pickRef = userRef.collection('picks').doc(giornata.toString());
        final pickDoc = await transaction.get(pickRef);
        
        if (!pickDoc.exists) {
          throw const PickNotFoundException();
        }
        
        final pick = Pick.fromJson(pickDoc.data()!);
        if (pick.usedJolly) {
          throw const JollyAlreadyUsedException();
        }
        
        transaction.update(pickRef, {'usedJolly': true});
        transaction.update(userRef, {
          'jollyLeft': userData.jollyLeft - 1,
          'lastJollyUsed': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Errore nell\'uso del jolly: ${e.message}', e.code);
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException('Errore sconosciuto nell\'uso del jolly: $e');
    }
  }

  /// Recupera la classifica generale
  Future<List<UserRanking>> getLeaderboard() async {
    try {
      final query = await _db
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('currentStreak', descending: true)
          .orderBy('totalWins', descending: true)
          .limit(100)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return UserRanking.fromJson({...data, 'uid': doc.id});
      }).toList();
    } on FirebaseException catch (e) {
      throw FirestoreException('Errore nel recupero della classifica: ${e.message}', e.code);
    } catch (e) {
      throw FirestoreException('Errore sconosciuto nel recupero della classifica: $e');
    }
  }

  // === METODI PRIVATI ===

  /// Valida una scelta prima dell'invio
  Future<void> _validatePick(String uid, Pick pick) async {
    // Verifica che la giornata sia valida
    if (pick.giornata < 1 || pick.giornata > 38) {
      throw const InvalidMatchdayException();
    }

    // Verifica che la squadra non sia vuota
    if (pick.team.trim().isEmpty) {
      throw const InvalidTeamException();
    }

    // Verifica che non sia scaduto il termine
    final matchday = await fetchNextMatchday();
    if (DateTime.now().isAfter(matchday.deadline)) {
      throw const DeadlineExpiredException();
    }

    // Verifica che sia la giornata corretta
    if (pick.giornata != matchday.giornata) {
      throw const WrongMatchdayException();
    }
  }

  /// Crea un documento utente di default
  Future<void> _createDefaultUserDocument(String uid) async {
    try {
      final user = _auth.currentUser;
      final defaultData = {
        'jollyLeft': 0,
        'teamsUsed': <String>[],
        'isActive': true,
        'currentStreak': 0,
        'totalWins': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user?.displayName ?? 'Utente',
        'email': user?.email,
      };

      await _db.collection('users').doc(uid).set(defaultData);
    } catch (e) {
      // Log error but don't throw to avoid breaking the stream
      print('Errore nella creazione del documento utente: $e');
    }
  }

  /// Invalida la cache
  void _invalidateCache() {
    _cachedMatchday = null;
    _lastMatchdayFetch = null;
  }

  /// Cleanup per rilasciare risorse
  void dispose() {
    _invalidateCache();
  }
}

// === ECCEZIONI PERSONALIZZATE ===

class FirestoreException implements Exception {
  final String message;
  final String? code;
  
  const FirestoreException(this.message, [this.code]);
  
  @override
  String toString() => 'FirestoreException: $message${code != null ? ' (Code: $code)' : ''}';
}

class MatchdayNotFoundException implements Exception {
  const MatchdayNotFoundException();
  @override
  String toString() => 'Dati della giornata non trovati';
}

class InvalidMatchdayDataException implements Exception {
  const InvalidMatchdayDataException();
  @override
  String toString() => 'Dati della giornata non validi';
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

class MaxJollyReachedException implements Exception {
  const MaxJollyReachedException();
  @override
  String toString() => 'Hai raggiunto il limite massimo di jolly';
}

class NoJollyAvailableException implements Exception {
  const NoJollyAvailableException();
  @override
  String toString() => 'Non hai jolly disponibili';
}

class PickNotFoundException implements Exception {
  const PickNotFoundException();
  @override
  String toString() => 'Scelta non trovata';
}

class JollyAlreadyUsedException implements Exception {
  const JollyAlreadyUsedException();
  @override
  String toString() => 'Jolly già utilizzato per questa giornata';
}

// === MODELLI AGGIUNTIVI ===

class UserRanking {
  final String uid;
  final String displayName;
  final int currentStreak;
  final int totalWins;
  final bool isActive;

  UserRanking({
    required this.uid,
    required this.displayName,
    required this.currentStreak,
    required this.totalWins,
    required this.isActive,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Utente',
      currentStreak: json['currentStreak'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}