import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import necessario per authProvider
import 'providers.dart' show authProvider;

// Provider che tiene traccia delle leghe per ogni utente specifico
// La chiave è l'userId, il valore è se ha leghe
final userLeaguesStatusProvider = StateProvider<Map<String, bool>>((ref) {
  return <String, bool>{};
});

// Provider helper per verificare se l'utente corrente ha leghe
final hasLeaguesProvider = Provider<bool>((ref) {
  final userLeaguesStatus = ref.watch(userLeaguesStatusProvider);
  final authState = ref.watch(authProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return false;
      // Controlla se questo specifico utente ha leghe
      return userLeaguesStatus[user.uid] ?? false;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});