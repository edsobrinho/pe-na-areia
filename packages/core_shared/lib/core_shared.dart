library core_shared;

// Design System
export 'design_system/app_colors.dart';
export 'design_system/app_theme.dart';
export 'design_system/pe_na_areia_logo.dart';
export 'design_system/app_text_field.dart';

// Domain Models & Utils
export 'domain/geo.dart';
export 'domain/utils/beach_compass.dart';
export 'domain/models/auth_session.dart';
export 'domain/models/courier.dart';
export 'domain/models/geo_point.dart';
export 'domain/models/kiosk.dart';
export 'domain/models/order.dart';
export 'domain/models/order_location.dart';
export 'domain/models/order_status.dart';
export 'domain/models/partnership.dart';
export 'domain/models/payment_method.dart';
export 'domain/models/reference_point.dart';
export 'domain/models/user.dart';

// Data Layer
export 'data/auth/token_storage.dart';
export 'data/http/api_client.dart';
export 'data/http/api_exception.dart';
export 'data/mappers/courier_mapper.dart';
export 'data/mappers/geo_json_mapper.dart';
export 'data/mappers/json_helpers.dart';
export 'data/mappers/kiosk_mapper.dart';
export 'data/mappers/order_location_mapper.dart';
export 'data/mappers/order_mapper.dart';
export 'data/mappers/reference_point_mapper.dart';
export 'data/mappers/user_mapper.dart';
export 'data/repositories/auth_repository.dart';
export 'data/repositories/catalog_repository.dart';
export 'data/repositories/order_repository.dart';
export 'data/repositories/reference_point_repository.dart';
export 'data/repositories/upload_repository.dart';
export 'data/services/location_service.dart';

// Forms & Validation
export 'forms/formatters.dart';
export 'forms/validators.dart';

