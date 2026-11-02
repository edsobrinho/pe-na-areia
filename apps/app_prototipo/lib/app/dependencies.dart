import 'package:core_shared/core_shared.dart';

class AppDependencies {
  AppDependencies({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    LocationService? locationService,
  })  : tokenStorage = tokenStorage ?? TokenStorage(),
        locationService = locationService ?? LocationService() {
    this.apiClient = apiClient ??
        ApiClient(
          baseUrl: ApiClient.defaultBaseUrl,
          bearerTokenProvider: this.tokenStorage.readToken,
        );
  }

  late final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final LocationService locationService;

  late final AuthRepository authRepository =
      AuthRepository(apiClient, tokenStorage);
}

