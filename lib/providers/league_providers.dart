import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/providers.dart' show authProvider;
import '../services/league_service.dart';
import '../models/league_models.dart';

// === BASE ===

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService();
});

// === USER LEAGUES ===

final userHasLeaguesProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return false;
  final leagueService = ref.read(leagueServiceProvider);
  return await leagueService.userHasActiveLeagues(user.uid);
});

final userLeaguesProvider =
    StreamProvider.family<List<LastManStandingLeague>, String>((ref, userId) {
  final leagueService = ref.read(leagueServiceProvider);
  return leagueService.getUserLeagues(userId);
});

final currentUserLeaguesProvider =
    StreamProvider<List<LastManStandingLeague>>((ref) {
  final userId = ref.watch(authProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(userLeaguesProvider(userId).stream);
});

// === PUBLIC LEAGUES ===

final publicLeaguesProvider = FutureProvider.family<
    List<LastManStandingLeague>, String?>((ref, query) async {
  final leagueService = ref.read(leagueServiceProvider);
  final leagues = await leagueService.searchPublicLeagues(query: query);
  return leagues
      .where((l) => !l.isPrivate && l.status == LeagueStatus.waiting && !l.isFull)
      .toList();
});

final leagueProvider = FutureProvider.family<LastManStandingLeague?, String>(
    (ref, leagueId) async {
  final leagueService = ref.read(leagueServiceProvider);
  return await leagueService.getLeague(leagueId);
});

final leagueParticipantsProvider =
    StreamProvider.family<List<LeagueParticipant>, String>((ref, leagueId) {
  final leagueService = ref.read(leagueServiceProvider);
  return leagueService.getLeagueParticipants(leagueId);
});

final leagueByInviteCodeProvider = FutureProvider.family<
    LastManStandingLeague?, String>((ref, inviteCode) async {
  final leagueService = ref.read(leagueServiceProvider);
  return await leagueService.findLeagueByInviteCode(inviteCode);
});

// === STATE NOTIFIERS ===

final createLeagueStateProvider =
    StateNotifierProvider<CreateLeagueNotifier, CreateLeagueState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return CreateLeagueNotifier(leagueService);
});

final joinLeagueStateProvider =
    StateNotifierProvider<JoinLeagueNotifier, JoinLeagueState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return JoinLeagueNotifier(leagueService);
});

class CreateLeagueNotifier extends StateNotifier<CreateLeagueState> {
  final LeagueService _leagueService;

  CreateLeagueNotifier(this._leagueService)
      : super(const CreateLeagueState());

  Future<void> createLeague({
    required String name,
    required String description,
    required int maxParticipants,
    bool isPrivate = false,
    bool requirePassword = false,
    String? password,
    LeagueSettings? settings,
  }) async {
    state = state.copyWith(status: CreateLeagueStatus.loading);
    try {
      final league = await _leagueService.createLeague(
        name: name,
        description: description,
        maxParticipants: maxParticipants,
        isPrivate: isPrivate,
        requirePassword: requirePassword,
        password: password,
        settings: settings,
      );
      state = state.copyWith(
        status: CreateLeagueStatus.success,
        createdLeague: league,
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateLeagueStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const CreateLeagueState();
}

class JoinLeagueNotifier extends StateNotifier<JoinLeagueState> {
  final LeagueService _leagueService;

  JoinLeagueNotifier(this._leagueService) : super(const JoinLeagueState());

  Future<void> joinLeagueById({
    required String leagueId,
    String? password,
  }) async {
    state = state.copyWith(status: JoinLeagueStatus.loading);
    try {
      await _leagueService.joinLeague(
          leagueId: leagueId, password: password);
      state = state.copyWith(
        status: JoinLeagueStatus.success,
        joinedLeagueId: leagueId,
      );
    } catch (e) {
      state = state.copyWith(
        status: JoinLeagueStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> joinLeagueByInviteCode({
    required String inviteCode,
    String? password,
  }) async {
    state = state.copyWith(status: JoinLeagueStatus.loading);
    try {
      final league =
          await _leagueService.findLeagueByInviteCode(inviteCode);
      if (league == null) {
        throw LeagueException('Lega non trovata con questo codice');
      }
      await _leagueService.joinLeague(
          leagueId: league.id, password: password);
      state = state.copyWith(
        status: JoinLeagueStatus.success,
        joinedLeagueId: league.id,
      );
    } catch (e) {
      state = state.copyWith(
        status: JoinLeagueStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> leaveLeague(String leagueId) async {
    state = state.copyWith(status: JoinLeagueStatus.loading);
    try {
      await _leagueService.leaveLeague(leagueId);
      state = state.copyWith(
        status: JoinLeagueStatus.success,
        leftLeagueId: leagueId,
      );
    } catch (e) {
      state = state.copyWith(
        status: JoinLeagueStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const JoinLeagueState();
}

// === STATE MODELS ===

enum CreateLeagueStatus { initial, loading, success, error }

class CreateLeagueState {
  final CreateLeagueStatus status;
  final LastManStandingLeague? createdLeague;
  final String? errorMessage;

  const CreateLeagueState({
    this.status = CreateLeagueStatus.initial,
    this.createdLeague,
    this.errorMessage,
  });

  CreateLeagueState copyWith({
    CreateLeagueStatus? status,
    LastManStandingLeague? createdLeague,
    String? errorMessage,
  }) {
    return CreateLeagueState(
      status: status ?? this.status,
      createdLeague: createdLeague ?? this.createdLeague,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum JoinLeagueStatus { initial, loading, success, error }

class JoinLeagueState {
  final JoinLeagueStatus status;
  final String? joinedLeagueId;
  final String? leftLeagueId;
  final String? errorMessage;

  const JoinLeagueState({
    this.status = JoinLeagueStatus.initial,
    this.joinedLeagueId,
    this.leftLeagueId,
    this.errorMessage,
  });

  JoinLeagueState copyWith({
    JoinLeagueStatus? status,
    String? joinedLeagueId,
    String? leftLeagueId,
    String? errorMessage,
  }) {
    return JoinLeagueState(
      status: status ?? this.status,
      joinedLeagueId: joinedLeagueId ?? this.joinedLeagueId,
      leftLeagueId: leftLeagueId ?? this.leftLeagueId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// === SEARCH ===

final searchPublicLeaguesProvider =
    StateNotifierProvider<SearchLeaguesNotifier, SearchLeaguesState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return SearchLeaguesNotifier(leagueService);
});

class SearchLeaguesNotifier extends StateNotifier<SearchLeaguesState> {
  final LeagueService _leagueService;

  SearchLeaguesNotifier(this._leagueService)
      : super(const SearchLeaguesState());

  Future<void> searchLeagues(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchLeaguesState();
      return;
    }
    state = state.copyWith(status: SearchStatus.loading);
    try {
      final leagues =
          await _leagueService.searchPublicLeagues(query: query);
      state = state.copyWith(
        status: SearchStatus.success,
        results: leagues,
        query: query,
      );
    } catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearSearch() => state = const SearchLeaguesState();
}

enum SearchStatus { initial, loading, success, error }

class SearchLeaguesState {
  final SearchStatus status;
  final List<LastManStandingLeague> results;
  final String query;
  final String? errorMessage;

  const SearchLeaguesState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.query = '',
    this.errorMessage,
  });

  SearchLeaguesState copyWith({
    SearchStatus? status,
    List<LastManStandingLeague>? results,
    String? query,
    String? errorMessage,
  }) {
    return SearchLeaguesState(
      status: status ?? this.status,
      results: results ?? this.results,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// === UTILITY ===

final defaultLeagueSettingsProvider = Provider<LeagueSettings>((ref) {
  return const LeagueSettings();
});
