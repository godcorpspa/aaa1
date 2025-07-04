// lib/shared_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/models/league_models.dart' show LastManStandingLeague;
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

/// Provider per la lega attualmente selezionata
final selectedLeagueProvider = StateNotifierProvider<SelectedLeagueNotifier, String?>((ref) {
  return SelectedLeagueNotifier(ref);
});

class SelectedLeagueNotifier extends StateNotifier<String?> {
  final Ref _ref;
  
  SelectedLeagueNotifier(this._ref) : super(null) {
    // Inizializza con la prima lega disponibile
    _initializeSelectedLeague();
  }

  void _initializeSelectedLeague() async {
    final leagues = await _ref.read(currentUserLeaguesProvider.future);
    if (leagues.isNotEmpty && state == null) {
      state = leagues.first.id;
    }
  }

  void selectLeague(String leagueId) {
    state = leagueId;
    // Salva la preferenza localmente se vuoi
    _savePreference(leagueId);
  }

  void _savePreference(String leagueId) async {
    // Opzionale: salva in SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('selected_league_${_ref.read(authProvider).valueOrNull?.uid}', leagueId);
  }
}

/// Provider per ottenere i dettagli della lega selezionata
final selectedLeagueDetailsProvider = Provider<AsyncValue<LastManStandingLeague?>>((ref) {
  final selectedId = ref.watch(selectedLeagueProvider);
  final leagues = ref.watch(currentUserLeaguesProvider);
  
  if (selectedId == null) return const AsyncValue.data(null);
  
  return leagues.when(
    data: (leaguesList) {
      final league = leaguesList.firstWhere(
        (l) => l.id == selectedId,
        orElse: () => leaguesList.isNotEmpty ? leaguesList.first : LastManStandingLeague(
          id: '',
          name: 'Nessuna lega',
          description: '',
          creatorId: '',
          creatorName: '',
          createdAt: DateTime.now(),
        ),
      );
      return AsyncValue.data(league.id.isEmpty ? null : league);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});