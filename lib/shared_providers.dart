import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/models/league_models.dart'
    show LastManStandingLeague;
import 'providers.dart' show authProvider;
import 'providers/league_providers.dart' show currentUserLeaguesProvider;

/// Whether the current user has any leagues
final hasLeaguesProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final userLeaguesAsync = ref.watch(currentUserLeaguesProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      return userLeaguesAsync.when(
        data: (leagues) => leagues.isNotEmpty,
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Currently selected league ID
final selectedLeagueProvider =
    StateNotifierProvider<SelectedLeagueNotifier, String?>((ref) {
  return SelectedLeagueNotifier(ref);
});

class SelectedLeagueNotifier extends StateNotifier<String?> {
  final Ref _ref;

  SelectedLeagueNotifier(this._ref) : super(null) {
    _initializeSelectedLeague();
  }

  Future<void> _initializeSelectedLeague() async {
    try {
      final leagues = await _ref.read(currentUserLeaguesProvider.future);
      if (leagues.isNotEmpty && state == null) {
        state = leagues.first.id;
      }
    } catch (_) {
      // Will be initialized when leagues load
    }
  }

  void selectLeague(String leagueId) {
    state = leagueId;
  }
}

/// Details of the currently selected league
final selectedLeagueDetailsProvider =
    Provider<AsyncValue<LastManStandingLeague?>>((ref) {
  final selectedId = ref.watch(selectedLeagueProvider);
  final leagues = ref.watch(currentUserLeaguesProvider);

  if (selectedId == null) return const AsyncValue.data(null);

  return leagues.when(
    data: (leaguesList) {
      try {
        final league = leaguesList.firstWhere((l) => l.id == selectedId);
        return AsyncValue.data(league);
      } catch (_) {
        if (leaguesList.isNotEmpty) {
          return AsyncValue.data(leaguesList.first);
        }
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
