import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';
import 'network_client.dart' as network;

/// Process-wide default [ApiClient] for call sites that don't receive one via
/// Riverpod (e.g. repositories constructed directly in widgets).
///
/// Riverpod code should prefer `apiClientProvider` from
/// `core/di/app_providers.dart`. This shared instance lets repositories drop
/// the deprecated `ApiService()` singleton without rewiring every consumer:
/// it authenticates per-request from the same Hive-backed token storage, so
/// it stays in sync with logins performed through any other ApiClient.
ApiClient? _instance;

ApiClient get defaultApiClient => _instance ??= ApiClientImpl(
      networkClient: network.NetworkClient(
        baseUrl: AppConfig.fullApiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        enableLogging: AppConfig.enableNetworkLogs,
      ),
      tokenStorage: SecureStorageImpl(),
    );
