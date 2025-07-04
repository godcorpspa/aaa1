// lib/shared_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart' show authProvider;
import 'providers/league_providers.dart' show currentUserLeaguesProvider;

/// Provider che verifica se l'utente CORRENTE ha leghe attive
final hasLeaguesProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final userLeaguesAsync = ref.watch(currentUserLeaguesProvider);
  
  // Debug
  final userId = authState.valueOrNull?.uid;
  print('🔍 hasLeaguesProvider - User ID: $userId');
  
  return authState.when(
    data: (user) {
      if (user == null) {
        print('🔍 hasLeaguesProvider - No user');
        return false;
      }
      
      return userLeaguesAsync.when(
        data: (leagues) {
          print('🔍 hasLeaguesProvider - User ${user.uid} has ${leagues.length} leagues');
          return leagues.isNotEmpty;
        },
        loading: () => false,
        error: (e, s) {
          print('❌ hasLeaguesProvider error: $e');
          return false;
        },
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});