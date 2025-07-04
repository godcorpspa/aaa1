// lib/providers/league_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/providers.dart' show authProvider;
import '../services/league_service.dart';
import '../models/league_models.dart';

// === PROVIDER BASE ===

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService();
});

// === PROVIDER USER-SPECIFIC ===

/// Provider per verificare se l'UTENTE CORRENTE ha leghe attive
final userHasLeaguesProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  
  if (user == null) return false;
  
  final leagueService = ref.read(leagueServiceProvider);
  
  try {
    // Passa esplicitamente l'userId per essere sicuri
    return await leagueService.userHasActiveLeagues(user.uid);
  } catch (e) {
    print('❌ Errore verifica leghe per utente ${user.uid}: $e');
    return false;
  }
});

/// Provider per le leghe dell'utente corrente - FAMILY provider per user ID
final userLeaguesProvider =
    StreamProvider.family<List<LastManStandingLeague>, String>((ref, userId) {
  final leagueService = ref.read(leagueServiceProvider);
  return leagueService.getUserLeagues(userId);
});

// helper per l’utente corrente
final currentUserLeaguesProvider = StreamProvider<List<LastManStandingLeague>>((ref) {
  final userId = ref.watch(authProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(userLeaguesProvider(userId).stream);
});

/// Provider per leghe pubbliche disponibili
final publicLeaguesProvider = FutureProvider.family<List<LastManStandingLeague>, String?>((ref, query) async {
  final leagueService = ref.read(leagueServiceProvider);
  
  try {
    // Ottieni tutte le leghe pubbliche in stato waiting
    final leagues = await leagueService.searchPublicLeagues(query: query);
    
    // Filtra ulteriormente per essere sicuri che siano pubbliche e aperte
    return leagues.where((league) => 
      !league.isPrivate && 
      league.status == LeagueStatus.waiting &&
      !league.isFull
    ).toList();
  } catch (e) {
    throw LeagueException('Errore nel caricamento delle leghe pubbliche: $e');
  }
});

/// Provider per una lega specifica
final leagueProvider = FutureProvider.family<LastManStandingLeague?, String>((ref, leagueId) async {
  final leagueService = ref.read(leagueServiceProvider);
  
  try {
    return await leagueService.getLeague(leagueId);
  } catch (e) {
    throw LeagueException('Errore nel caricamento della lega: $e');
  }
});

/// Provider per i partecipanti di una lega
final leagueParticipantsProvider = StreamProvider.family<List<LeagueParticipant>, String>((ref, leagueId) {
  final leagueService = ref.read(leagueServiceProvider);
  return leagueService.getLeagueParticipants(leagueId);
});

/// Provider per trovare lega tramite codice invito
final leagueByInviteCodeProvider = FutureProvider.family<LastManStandingLeague?, String>((ref, inviteCode) async {
  final leagueService = ref.read(leagueServiceProvider);
  
  try {
    return await leagueService.findLeagueByInviteCode(inviteCode);
  } catch (e) {
    throw LeagueException('Errore nella ricerca della lega: $e');
  }
});

// === PROVIDER DI STATO ===

/// Provider per lo stato di creazione lega
final createLeagueStateProvider = StateNotifierProvider<CreateLeagueNotifier, CreateLeagueState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return CreateLeagueNotifier(leagueService);
});

/// Provider per lo stato di join lega
final joinLeagueStateProvider = StateNotifierProvider<JoinLeagueNotifier, JoinLeagueState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return JoinLeagueNotifier(leagueService);
});

// === STATE NOTIFIERS ===

/// Notifier per la creazione di leghe
class CreateLeagueNotifier extends StateNotifier<CreateLeagueState> {
  final LeagueService _leagueService;
  
  CreateLeagueNotifier(this._leagueService) : super(const CreateLeagueState());

  /// Crea una nuova lega
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

  /// Reset dello stato
  void reset() {
    state = const CreateLeagueState();
  }
}

/// Notifier per unirsi alle leghe
class JoinLeagueNotifier extends StateNotifier<JoinLeagueState> {
  final LeagueService _leagueService;
  
  JoinLeagueNotifier(this._leagueService) : super(const JoinLeagueState());

  /// Unisciti a una lega tramite ID
  Future<void> joinLeagueById({
    required String leagueId,
    String? password,
  }) async {
    state = state.copyWith(status: JoinLeagueStatus.loading);
    
    try {
      await _leagueService.joinLeague(
        leagueId: leagueId,
        password: password,
      );
      
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

  /// Unisciti a una lega tramite codice invito
  Future<void> joinLeagueByInviteCode({
    required String inviteCode,
    String? password,
  }) async {
    state = state.copyWith(status: JoinLeagueStatus.loading);
    
    try {
      // Prima trova la lega
      final league = await _leagueService.findLeagueByInviteCode(inviteCode);
      if (league == null) {
        throw LeagueException('Lega non trovata con questo codice');
      }
      
      // Poi unisciti
      await _leagueService.joinLeague(
        leagueId: league.id,
        password: password,
      );
      
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

  /// Lascia una lega
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

  /// Reset dello stato
  void reset() {
    state = const JoinLeagueState();
  }
}

// === MODELLI DI STATO ===

/// Stato per la creazione di leghe
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

enum CreateLeagueStatus {
  initial,
  loading,
  success,
  error,
}

/// Stato per unirsi alle leghe
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

enum JoinLeagueStatus {
  initial,
  loading,
  success,
  error,
}

// === PROVIDER COMBINATI ===

/// Provider che combina lo stato di autenticazione e leghe utente
final userLeaguesStatusProvider = Provider<AsyncValue<bool>>((ref) {
  final leaguesAsync = ref.watch(currentUserLeaguesProvider);

  return leaguesAsync.when(
    data: (leagues) => AsyncValue.data(leagues.isNotEmpty),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider per statistiche generali delle leghe
final leagueStatsProvider = FutureProvider<LeagueGlobalStats>((ref) async {
  // TODO: Implementare statistiche globali
  return const LeagueGlobalStats(
    totalLeagues: 0,
    activeLeagues: 0,
    totalPlayers: 0,
    activePlayers: 0,
  );
});

/// Modello per statistiche globali
class LeagueGlobalStats {
  final int totalLeagues;
  final int activeLeagues;
  final int totalPlayers;
  final int activePlayers;

  const LeagueGlobalStats({
    required this.totalLeagues,
    required this.activeLeagues,
    required this.totalPlayers,
    required this.activePlayers,
  });
}

// === PROVIDER DI UTILITÀ ===

/// Provider per validare un codice invito
final validateInviteCodeProvider = FutureProvider.family<bool, String>((ref, inviteCode) async {
  if (inviteCode.trim().isEmpty) return false;
  
  final leagueService = ref.read(leagueServiceProvider);
  try {
    final league = await leagueService.findLeagueByInviteCode(inviteCode);
    return league != null;
  } catch (e) {
    return false;
  }
});

/// Provider per ottenere le impostazioni predefinite di una lega
final defaultLeagueSettingsProvider = Provider<LeagueSettings>((ref) {
  return const LeagueSettings(
    allowJolly: true,
    maxJollyPerPlayer: 3,
    jollyPrice: 50,
    allowDoubleDown: true,
    allowGoldenTicket: true,
    enableThemedRounds: true,
    autoElimination: true,
    allowLateJoin: false,
    maxLateJoinRound: 3,
  );
});

// === PROVIDER PER RICERCA ===

/// Provider per la ricerca di leghe pubbliche con debounce
final searchPublicLeaguesProvider = StateNotifierProvider<SearchLeaguesNotifier, SearchLeaguesState>((ref) {
  final leagueService = ref.read(leagueServiceProvider);
  return SearchLeaguesNotifier(leagueService);
});

class SearchLeaguesNotifier extends StateNotifier<SearchLeaguesState> {
  final LeagueService _leagueService;
  
  SearchLeaguesNotifier(this._leagueService) : super(const SearchLeaguesState());

  /// Cerca leghe pubbliche
  Future<void> searchLeagues(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchLeaguesState();
      return;
    }

    state = state.copyWith(status: SearchStatus.loading);
    
    try {
      final leagues = await _leagueService.searchPublicLeagues(query: query);
      
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

  /// Pulisci risultati ricerca
  void clearSearch() {
    state = const SearchLeaguesState();
  }
}

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

enum SearchStatus {
  initial,
  loading,
  success,
  error,
}