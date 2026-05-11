import 'dart:io';

/// Défauts : Android émulateur → `http://10.0.2.2:3000`, iOS → `http://localhost:3000`.
/// **iPhone réel + émulateur** : même backend → `flutter run --dart-define=DEV_LAN_HOST=<IP Wi‑Fi du Mac>`.
/// Port : `--dart-define=API_PORT=3000` (défaut 3000). URL complète : `API_BASE_URL` dans [AppConfig].
String getDefaultApiBaseUrl() {
  const host = String.fromEnvironment('DEV_LAN_HOST', defaultValue: '');
  const port = String.fromEnvironment('API_PORT', defaultValue: '3000');

  if (host.isNotEmpty) return 'http://$host:$port';
  if (Platform.isAndroid) return 'http://10.0.2.2:$port';
  return 'http://localhost:$port';
}

/// Serveur stress audio (ex. Python sur :8000). Émulateur Android → `10.0.2.2`.
String getDefaultStressApiUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

String getDefaultAiBaseUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:8002';
  return 'http://127.0.0.1:8002';
}

/// Backend Flask AI (Whisper/TTS/air-click/adapt), port 5001 par défaut.
String getDefaultAiModuleBaseUrl() {
  const host = String.fromEnvironment('AI_MODULE_HOST', defaultValue: '');
  const port = String.fromEnvironment('AI_MODULE_PORT', defaultValue: '5001');

  if (host.isNotEmpty) return 'http://$host:$port';
  if (Platform.isAndroid) return 'http://10.0.2.2:$port';
  return 'http://localhost:$port';
}

/// Deuxième backend IA optionnel (vide par défaut).
String? getDefaultAiModuleSecondaryBaseUrl() {
  const direct = String.fromEnvironment('AI_MODULE_2_HOST', defaultValue: '');
  const port = String.fromEnvironment('AI_MODULE_2_PORT', defaultValue: '8080');
  if (direct.isNotEmpty) {
    return 'http://$direct:$port';
  }
  return null;
}

/// Service FastAPI « accessibilité » (port 8002 par défaut).
/// Émulateur Android → `10.0.2.2` pour joindre le PC hôte.
/// Surcharge : `--dart-define=ACCESSIBILITY_AI_BASE_URL=http://192.168.x.x:8002`.
String getDefaultAccessibilityAiBaseUrl() {
  const fromEnv = String.fromEnvironment(
    'ACCESSIBILITY_AI_BASE_URL',
    defaultValue: '',
  );
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/+$'), '');
  }
  const host = String.fromEnvironment('ACCESSIBILITY_AI_HOST', defaultValue: '');
  const port = String.fromEnvironment('ACCESSIBILITY_AI_PORT', defaultValue: '8002');
  if (host.isNotEmpty) return 'http://$host:$port';
  if (Platform.isAndroid) return 'http://10.0.2.2:$port';
  return 'http://127.0.0.1:$port';
}
