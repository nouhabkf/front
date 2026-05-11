import 'app_config_stub.dart' if (dart.library.io) 'app_config_io.dart' as impl;

/// Configuration de l'application Ma3ak.
/// Les valeurs peuvent être surchargées via --dart-define ou environnement.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _envStressApiUrl = String.fromEnvironment(
    'STRESS_API_URL',
    defaultValue: '',
  );

  static const String _envAiModuleBaseUrl = String.fromEnvironment(
    'AI_MODULE_BASE_URL',
    defaultValue: '',
  );
  static const String _envAiModuleBaseUrlSecondary = String.fromEnvironment(
    'AI_MODULE_BASE_URL_2',
    defaultValue: '',
  );

  static const String _envAccessibilityAiBaseUrl = String.fromEnvironment(
    'ACCESSIBILITY_AI_BASE_URL',
    defaultValue: '',
  );

  static const String _envAiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: '',
  );

  /// **BASE_URL_API** (origine NestJS, sans chemin `/api` sauf si déjà inclus dans l’URL).
  ///
  /// Utilisée par Dio pour les routes (`/user/me`, …) et pour résoudre les photos
  /// relatives `uploads/...` : URL affichée = `apiBaseUrl` + `/` + `photoProfil`.
  ///
  /// **Développement** : défauts plateforme (`app_config_io.dart`) ou
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android) /
  /// `http://localhost:3000` / `http://<IP_LAN>:3000` (appareil réel).
  ///
  /// **Production / staging** : `--dart-define=API_BASE_URL=https://api.votredomaine.tn`
  /// (même host que celui qui sert les fichiers statiques sous `/uploads/...`).
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return impl.getDefaultApiBaseUrl();
  }

  /// Base FastAPI / IA (port 8002 par défaut). Surcharge : `--dart-define=AI_BASE_URL=...`.
  static String get aiBaseUrl {
    if (_envAiBaseUrl.isNotEmpty) {
      return _envAiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    return impl.getDefaultAiBaseUrl().replaceAll(RegExp(r'/+$'), '');
  }

  /// Alias sémantique (Socket.IO, URLs publiques).
  static String get baseUrl => apiBaseUrl;

  /// Service Python d’analyse stress vocal (MFCC). Surcharge : `--dart-define=STRESS_API_URL=...`.
  static String get stressAudioApiUrl {
    if (_envStressApiUrl.isNotEmpty) return _envStressApiUrl;
    return impl.getDefaultStressApiUrl();
  }

  /// Backend Flask AI local (Whisper, pyttsx3, air-click, adaptation).
  /// Surcharge : `--dart-define=AI_MODULE_BASE_URL=...`.
  static String get aiModuleBaseUrl {
    if (_envAiModuleBaseUrl.isNotEmpty) return _envAiModuleBaseUrl;
    return impl.getDefaultAiModuleBaseUrl();
  }

  /// Deuxième backend IA optionnel (ex: ai-model).
  /// Surcharge : `--dart-define=AI_MODULE_BASE_URL_2=...`.
  static String? get aiModuleSecondaryBaseUrl {
    if (_envAiModuleBaseUrlSecondary.isNotEmpty) {
      return _envAiModuleBaseUrlSecondary;
    }
    return impl.getDefaultAiModuleSecondaryBaseUrl();
  }

  /// Backend FastAPI analyse d’accessibilité (Groq + OSM), ex. `uvicorn --port 8002`.
  /// Défaut Android émulateur : `http://10.0.2.2:8002` ([impl.getDefaultAccessibilityAiBaseUrl]).
  static String get accessibilityAiBaseUrl {
    if (_envAccessibilityAiBaseUrl.isNotEmpty) {
      return _envAccessibilityAiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    return impl.getDefaultAccessibilityAiBaseUrl();
  }

  /// Identique à [apiBaseUrl] ; les chemins `uploads/...` sont concaténés à cette base
  /// pour l’affichage des photos de profil.
  static String get uploadsBaseUrl => apiBaseUrl;

  /// Mode démo : navigation sans compte (`--dart-define=ALLOW_GUEST=true`).
  static const bool allowGuest = bool.fromEnvironment(
    'ALLOW_GUEST',
    defaultValue: false,
  );

  /// Forcer l’écran de connexion au démarrage (`--dart-define=FORCE_LOGIN_ON_START=true`).
  static const bool forceLoginOnStart = bool.fromEnvironment(
    'FORCE_LOGIN_ON_START',
    defaultValue: false,
  );

  /// Résumés post/commentaires via `/ai/community/*` (`--dart-define=AI_COMMUNITY_REMOTE=true`).
  static const bool aiCommunityRemoteEnabled = bool.fromEnvironment(
    'AI_COMMUNITY_REMOTE',
    defaultValue: false,
  );
}
