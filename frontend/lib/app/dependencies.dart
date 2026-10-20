import '../data/http/api_client.dart';
import '../data/auth/token_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/reference_point_repository.dart';
import '../data/repositories/upload_repository.dart';
import '../data/services/location_service.dart';
import '../presentation/location_selection/location_selection_controller.dart';

/// Raiz de composicao do app: monta as dependencias compartilhadas.
///
/// O [ApiClient] e o [LocationService] sao injetaveis para permitir fakes
/// em testes sem tocar na rede ou em plugins de plataforma.
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

  /// Cria um controller novo por navegacao (a tela descarta o controller
  /// recebido ao sair).
  LocationSelectionController createLocationSelectionController() =>
      LocationSelectionController(
        referencePointRepository: referencePointRepository,
        uploadRepository: uploadRepository,
        locationService: locationService,
      );
}
