/// Stub pour le web : pas d'accès à Platform.
String getDefaultApiBaseUrl() => 'http://localhost:3000';

String getDefaultStressApiUrl() => 'http://localhost:8000';

String getDefaultAiBaseUrl() => 'http://127.0.0.1:8002';

String getDefaultAiModuleBaseUrl() => 'http://localhost:5001';

/// FastAPI analyse accessibilité (Groq) — Chrome/web : localhost.
String getDefaultAccessibilityAiBaseUrl() => 'http://127.0.0.1:8002';

String? getDefaultAiModuleSecondaryBaseUrl() => null;
