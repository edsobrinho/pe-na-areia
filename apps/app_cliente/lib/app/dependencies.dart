import 'package:core_shared/core_shared.dart';
import '../presentation/location_selection/location_selection_controller.dart';

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

  late final ReferencePointRepository referencePointRepository =
      ReferencePointRepository(apiClient);

  late final CatalogRepository catalogRepository =
      CatalogRepository(apiClient);

  late final OrderRepository orderRepository = OrderRepository(apiClient);

  late final UploadRepository uploadRepository = UploadRepository(apiClient);

  LocationSelectionController createLocationSelectionController() =>
      LocationSelectionController(
        referencePointRepository: referencePointRepository,
        locationService: locationService,
        uploadRepository: uploadRepository,
      );
}
