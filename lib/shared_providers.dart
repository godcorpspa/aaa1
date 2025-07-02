// lib/shared_providers.dart - Aggiornato con sistema leghe
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import necessari
import 'providers.dart' show authProvider;
import 'providers/league_providers.dart' show userHasLeaguesProvider;

// === PROVIDER LEGHE CONDIVISO ===

/// Provider che verifica se l'utente corrente ha leghe attive
/// Questo sostituisce il vecchio userLeaguesStatusProvider basato su Map
final hasLeaguesProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final userHasLeaguesAsync = ref.watch(userHasLeaguesProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return false;
      
      return userHasLeaguesAsync.when(
        data: (hasLeagues) => hasLeagues,
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider legacy per compatibilità (sarà rimosso)
/// Mantenuto temporaneamente per non rompere il codice esistente
@Deprecated('Usa hasLeaguesProvider invece')
final userLeaguesStatusProvider = StateProvider<Map<String, bool>>((ref) {
  // Questo provider è deprecato ma mantenuto per compatibilità
  // Il nuovo sistema usa direttamente i dati Firebase
  return <String, bool>{};
});

// === PROVIDER STATO APPLICAZIONE ===

/// Provider per lo stato generale dell'applicazione
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  
  AppStateNotifier(this._ref) : super(const AppState());

  /// Inizializza lo stato dell'app
  void initialize() {
    // Ascolta i cambiamenti nell'autenticazione
    _ref.listen(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            state = state.copyWith(
              isAuthenticated: true,
              userId: user.uid,
            );
          } else {
            state = state.copyWith(
              isAuthenticated: false,
              userId: null,
              hasLeagues: false,
            );
          }
        },
        loading: () {},
        error: (_, __) {
          state = state.copyWith(
            isAuthenticated: false,
            userId: null,
            hasLeagues: false,
          );
        },
      );
    });

    // Ascolta i cambiamenti nelle leghe
    _ref.listen(hasLeaguesProvider, (previous, next) {
      state = state.copyWith(hasLeagues: next);
    });
  }

  /// Aggiorna lo stato quando l'utente si unisce a una lega
  void userJoinedLeague() {
    state = state.copyWith(hasLeagues: true);
  }

  /// Aggiorna lo stato quando l'utente lascia tutte le leghe
  void userLeftAllLeagues() {
    state = state.copyWith(hasLeagues: false);
  }

  /// Reset dello stato
  void reset() {
    state = const AppState();
  }
}

/// Modello per lo stato dell'applicazione
class AppState {
  final bool isAuthenticated;
  final String? userId;
  final bool hasLeagues;
  final bool isLoading;

  const AppState({
    this.isAuthenticated = false,
    this.userId,
    this.hasLeagues = false,
    this.isLoading = false,
  });

  AppState copyWith({
    bool? isAuthenticated,
    String? userId,
    bool? hasLeagues,
    bool? isLoading,
  }) {
    return AppState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      hasLeagues: hasLeagues ?? this.hasLeagues,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Determina quale schermata mostrare
  AppScreen get currentScreen {
    if (!isAuthenticated) return AppScreen.welcome;
    if (!hasLeagues) return AppScreen.joinLeague;
    return AppScreen.main;
  }
}

/// Enum per le schermate principali dell'app
enum AppScreen {
  welcome,     // Schermata di benvenuto (non autenticato)
  joinLeague,  // Schermata per unirsi a leghe (autenticato ma senza leghe)
  main,        // Schermata principale (autenticato con leghe)
}

// === PROVIDER NAVIGAZIONE ===

/// Provider per la navigazione dell'app
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  /// Naviga a una schermata specifica
  void navigateTo(AppScreen screen) {
    state = state.copyWith(currentScreen: screen);
  }

  /// Torna alla schermata precedente
  void goBack() {
    if (state.history.isNotEmpty) {
      final previous = state.history.last;
      final newHistory = List<AppScreen>.from(state.history)..removeLast();
      
      state = state.copyWith(
        currentScreen: previous,
        history: newHistory,
      );
    }
  }

  /// Aggiungi alla cronologia
  void pushToHistory(AppScreen screen) {
    final newHistory = List<AppScreen>.from(state.history)..add(state.currentScreen);
    state = state.copyWith(
      currentScreen: screen,
      history: newHistory,
    );
  }

  /// Pulisci cronologia
  void clearHistory() {
    state = state.copyWith(history: []);
  }
}

class NavigationState {
  final AppScreen currentScreen;
  final List<AppScreen> history;

  const NavigationState({
    this.currentScreen = AppScreen.welcome,
    this.history = const [],
  });

  NavigationState copyWith({
    AppScreen? currentScreen,
    List<AppScreen>? history,
  }) {
    return NavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      history: history ?? this.history,
    );
  }

  bool get canGoBack => history.isNotEmpty;
}

// === PROVIDER CONFIGURAZIONE ===

/// Provider per la configurazione dell'app
final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig();
});

class AppConfig {
  final String appName;
  final String version;
  final bool debugMode;
  final int maxLeaguesPerUser;
  final int defaultJollyCount;
  final int jollyPrice;

  const AppConfig({
    this.appName = 'Last Man Standing',
    this.version = '1.0.0',
    this.debugMode = false,
    this.maxLeaguesPerUser = 5,
    this.defaultJollyCount = 0,
    this.jollyPrice = 50,
  });
}

// === PROVIDER TEMA ===

/// Provider per gestire il tema dell'app
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState());

  /// Cambia il tema
  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  /// Imposta tema specifico
  void setTheme(bool isDarkMode) {
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  /// Imposta colore accent
  void setAccentColor(int colorValue) {
    state = state.copyWith(accentColorValue: colorValue);
  }
}

class ThemeState {
  final bool isDarkMode;
  final int accentColorValue;

  const ThemeState({
    this.isDarkMode = false,
    this.accentColorValue = 0xFFE64A19, // AppTheme.accentOrange
  });

  ThemeState copyWith({
    bool? isDarkMode,
    int? accentColorValue,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }
}

// === PROVIDER PERFORMANCE ===

/// Provider per monitorare le performance
final performanceProvider = StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  return PerformanceNotifier();
});

class PerformanceNotifier extends StateNotifier<PerformanceState> {
  PerformanceNotifier() : super(PerformanceState.initial());

  /// Registra il tempo di caricamento
  void recordLoadTime(String screen, Duration loadTime) {
    final newLoadTimes = Map<String, Duration>.from(state.loadTimes);
    newLoadTimes[screen] = loadTime;
    
    state = state.copyWith(loadTimes: newLoadTimes);
  }

  /// Incrementa il contatore errori
  void recordError(String error) {
    state = state.copyWith(errorCount: state.errorCount + 1);
  }

  /// Reset delle statistiche
  void reset() {
    state = PerformanceState.initial();
  }
}

class PerformanceState {
  final Map<String, Duration> loadTimes;
  final int errorCount;
  final DateTime startTime;

  const PerformanceState({
    required this.loadTimes,
    required this.errorCount,
    required this.startTime,
  });

  // Factory constructor per creare stato iniziale
  factory PerformanceState.initial() {
    return PerformanceState(
      loadTimes: const {},
      errorCount: 0,
      startTime: DateTime.now(),
    );
  }

  PerformanceState copyWith({
    Map<String, Duration>? loadTimes,
    int? errorCount,
    DateTime? startTime,
  }) {
    return PerformanceState(
      loadTimes: loadTimes ?? this.loadTimes,
      errorCount: errorCount ?? this.errorCount,
      startTime: startTime ?? this.startTime,
    );
  }

  /// Tempo di utilizzo totale dell'app
  Duration get totalUsageTime => DateTime.now().difference(startTime);

  /// Tempo medio di caricamento
  Duration get averageLoadTime {
    if (loadTimes.isEmpty) return Duration.zero;
    
    final totalMs = loadTimes.values
        .map((duration) => duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ loadTimes.length);
  }
}

// === PROVIDER CACHE ===

/// Provider per gestire la cache dell'app
final cacheProvider = StateNotifierProvider<CacheNotifier, CacheState>((ref) {
  return CacheNotifier();
});

class CacheNotifier extends StateNotifier<CacheState> {
  CacheNotifier() : super(CacheState.initial());

  /// Aggiungi elemento alla cache
  void addToCache(String key, dynamic value) {
    final newCache = Map<String, dynamic>.from(state.cache);
    newCache[key] = value;
    
    state = state.copyWith(
      cache: newCache,
      lastUpdated: DateTime.now(),
    );
  }

  /// Rimuovi elemento dalla cache
  void removeFromCache(String key) {
    final newCache = Map<String, dynamic>.from(state.cache);
    newCache.remove(key);
    
    state = state.copyWith(cache: newCache);
  }

  /// Pulisci cache
  void clearCache() {
    state = CacheState.initial();
  }

  /// Verifica se un elemento è nella cache
  bool hasInCache(String key) {
    return state.cache.containsKey(key);
  }

  /// Ottieni elemento dalla cache
  T? getFromCache<T>(String key) {
    return state.cache[key] as T?;
  }
}

class CacheState {
  final Map<String, dynamic> cache;
  final DateTime lastUpdated;

  const CacheState({
    required this.cache,
    required this.lastUpdated,
  });

  // Factory constructor per creare stato iniziale
  factory CacheState.initial() {
    return CacheState(
      cache: const {},
      lastUpdated: DateTime.now(),
    );
  }

  CacheState copyWith({
    Map<String, dynamic>? cache,
    DateTime? lastUpdated,
  }) {
    return CacheState(
      cache: cache ?? this.cache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Verifica se la cache è scaduta
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  /// Dimensione della cache
  int get size => cache.length;
}