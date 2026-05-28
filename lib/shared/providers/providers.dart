import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:theoriginallab_v2/core/constants/api_constants.dart';
import 'package:theoriginallab_v2/core/constants/storage_keys.dart';
import 'package:theoriginallab_v2/core/network/interceptors/auth_interceptor.dart';
import 'package:theoriginallab_v2/core/network/network_client.dart';
import 'package:theoriginallab_v2/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:theoriginallab_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:theoriginallab_v2/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:theoriginallab_v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:theoriginallab_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:theoriginallab_v2/features/chatbot/data/repositories/openai_chatbot_repository.dart';
import 'package:theoriginallab_v2/features/chatbot/data/services/appointment_service.dart';
import 'package:theoriginallab_v2/features/chatbot/data/services/openai_chatbot_service.dart';
import 'package:theoriginallab_v2/features/chatbot/domain/repositories/chatbot_repository.dart';
import 'package:theoriginallab_v2/features/content/data/datasources/content_remote_datasource.dart';
import 'package:theoriginallab_v2/features/meetings/data/repositories/webhook_meetings_repository.dart';
import 'package:theoriginallab_v2/features/meetings/data/services/booking_webhook_service.dart';
import 'package:theoriginallab_v2/features/meetings/domain/repositories/meetings_repository.dart';
import 'package:theoriginallab_v2/features/store/data/repositories/api_products_repository.dart';
import 'package:theoriginallab_v2/features/store/domain/repositories/products_repository.dart';
import 'package:theoriginallab_v2/features/tickets/data/repositories/api_tickets_repository.dart';
import 'package:theoriginallab_v2/features/tickets/domain/repositories/tickets_repository.dart';

// ============================================================================
// CORE DEPENDENCIES
// ============================================================================

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences debe ser inicializado en main()');
});

final authTokenReaderProvider = Provider<AuthTokenReader>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return () => secureStorage.read(key: StorageKeys.accessToken);
});

// La anotación de tipo explícita `Provider<AppNetworkClient>` es necesaria
// para evitar una circularidad de inferencia en el analizador de Dart.
// ref.read() dentro del callback onUnauthorized es seguro: se ejecuta en runtime
// (al recibir un 401), no durante la construcción del grafo de providers.
final Provider<AppNetworkClient> networkClientProvider =
    Provider<AppNetworkClient>((ref) {
  final readToken = ref.watch(authTokenReaderProvider);

  return AppNetworkClient(
    readToken: readToken,
    onUnauthorized: () async {
      ref.read(authProvider.notifier).logout();
    },
  );
});

// ============================================================================
// SHARED DIO CLIENTS
// ============================================================================

final authApiDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(networkClientProvider);
  return client.createClient(
    baseUrl: ApiConstants.baseUrl,
    headers: ApiConstants.defaultHeaders,
    enableAuth: false,
    usePinning: false, // API externa — cert distinto al embebido
  );
});

final contentApiDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(networkClientProvider);
  return client.createClient(
    baseUrl: ApiConstants.contentBaseUrl,
    headers: ApiConstants.contentHeaders,
    enableAuth: true,
    usePinning: true,
    useEncryption: true, // AES-256-CTR+HMAC activo
  );
});

final ticketsApiDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(networkClientProvider);
  return client.createClient(
    baseUrl: ApiConstants.resolvedTicketsApiBaseUrl,
    headers: ApiConstants.ticketsHeaders,
    enableAuth: true,
    usePinning: true,
    useEncryption: true, // AES-256-CTR+HMAC activo
  );
});

/// Cliente Dio apuntando al proxy propio (nuestra Dart Frog API).
/// Usa la misma apikey que el resto de la app para autenticarse.
/// La OPENAI_API_KEY nunca sale al cliente — vive solo en el servidor.
final aiProxyDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(networkClientProvider);
  return client.createClient(
    baseUrl: ApiConstants.aiProxyUrl,
    headers: ApiConstants.contentHeaders,
    connectTimeout: ApiConstants.appointmentsTimeout,
    receiveTimeout: ApiConstants.appointmentsTimeout,
    enableAuth: true,
    usePinning: true,
    useEncryption: true, // AES-256-CTR+HMAC activo
  );
});

final storeApiDioProvider = Provider<Dio>((ref) {
  final client = ref.watch(networkClientProvider);
  return client.createClient(
    baseUrl: ApiConstants.storeApiBaseUrl,
    headers: ApiConstants.defaultHeaders,
    enableAuth: false,
    usePinning: false, // API externa — cert distinto al embebido
  );
});

// ============================================================================
// FEATURE DATA LAYER DI
// ============================================================================

final productsRepositoryDiProvider = Provider<ProductsRepository>((ref) {
  final dio = ref.watch(storeApiDioProvider);
  return ApiProductsRepository(dio: dio);
});

final ticketsRepositoryDiProvider = Provider<TicketsRepository>((ref) {
  final dio = ref.watch(ticketsApiDioProvider);
  return ApiTicketsRepository(dio: dio);
});

final chatbotRepositoryDiProvider = Provider<ChatbotRepository>((ref) {
  // El chatbot SIEMPRE usa el proxy propio (AI_PROXY_URL).
  // La OPENAI_API_KEY vive solo en el servidor y nunca llega al cliente.
  final chatDio = ref.watch(aiProxyDioProvider);
  // Las citas también pasan por nuestra API (proxy de Make.com).
  final contentDio = ref.watch(contentApiDioProvider);

  final chatService = OpenAiChatbotService(
    dio: chatDio,
    useProxy: true, // Siempre proxy
  );
  final appointmentService = AppointmentService(dio: contentDio);

  return OpenAiChatbotRepository(
    chatService: chatService,
    appointmentService: appointmentService,
  );
});

final bookingWebhookServiceDiProvider = Provider<BookingWebhookService>((ref) {
  final dio = ref.watch(contentApiDioProvider);
  return BookingWebhookService(dio: dio);
});

final meetingsRepositoryDiProvider = Provider<MeetingsRepository>((ref) {
  final authState = ref.watch(authProvider);
  final dio = ref.watch(contentApiDioProvider);

  String name = 'Usuario';
  String email = '';
  authState.whenOrNull(
    authenticated: (user) {
      name = user.name;
      email = user.email;
    },
  );

  return WebhookMeetingsRepository(
    dio: dio,
    userName: name,
    userEmail: email,
  );
});

// ============================================================================
// AUTH DATA SOURCES
// ============================================================================

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final authDio = ref.watch(authApiDioProvider);
  final secureExchangeDio = ref.watch(contentApiDioProvider);
  return AuthRemoteDataSourceImpl(
    authDio,
    exchangeDio: secureExchangeDio,
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthLocalDataSourceImpl(
    secureStorage: secureStorage,
  );
});

// ============================================================================
// CONTENT DATA SOURCES
// ============================================================================

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(contentApiDioProvider);
  return ContentRemoteDataSourceImpl(dio);
});

// ============================================================================
// AUTH REPOSITORY
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
