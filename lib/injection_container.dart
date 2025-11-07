import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import 'core/services/auth_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/payment_service.dart';
import 'core/api/dio_client.dart';

// Domain
import 'domain/repositories/event_repository.dart';
import 'domain/repositories/post_repository.dart';
import 'domain/repositories/ticket_repository.dart';
import 'domain/usecases/get_events.dart';
import 'domain/usecases/get_events_by_category.dart';
import 'domain/usecases/create_event.dart';
import 'domain/usecases/get_posts.dart';
import 'domain/usecases/create_post.dart';
import 'domain/usecases/like_post.dart';
import 'domain/usecases/unlike_post.dart';
import 'domain/usecases/repost_post.dart';
import 'domain/usecases/get_comments.dart';
import 'domain/usecases/create_comment.dart';
import 'domain/usecases/like_comment.dart';
import 'domain/usecases/unlike_comment.dart';
import 'domain/usecases/purchase_ticket.dart';
import 'domain/usecases/get_user_tickets.dart';
import 'domain/usecases/check_in_ticket.dart';

// Data
import 'data/datasources/event_local_datasource.dart';
import 'data/datasources/event_remote_datasource.dart';
import 'data/datasources/post_remote_datasource.dart';
import 'data/datasources/ticket_remote_datasource.dart';
import 'data/datasources/ticket_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/event_repository_impl.dart';
import 'data/repositories/post_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/analytics_service.dart';

// Dummy Data (for development)
// import 'dummy_data/dummy_event_repository.dart';

// Presentation
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/posts/posts_bloc.dart';
import 'presentation/bloc/tickets/tickets_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core - External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton(() => secureStorage);

  // Core - HTTP Client
  sl.registerLazySingleton(() => DioClient());

  // Core - Services
  sl.registerLazySingleton(() => AuthService(sl(), sl()));
  sl.registerLazySingleton(() => GoogleAuthService());

  // Initialize and register PaymentService
  final paymentService = PaymentService();
  await paymentService.initialize(
    clientKey: 'sandbox-client-key', // TODO: Replace with actual Midtrans key
    merchantBaseUrl: 'https://api.sandbox.midtrans.com',
    environment: MidtransEnvironment.sandbox,
  );
  sl.registerLazySingleton(() => paymentService);

  // API Services
  sl.registerLazySingleton(() => AuthApiService(sl()));

  // Analytics Service
  sl.registerLazySingleton(() => AnalyticsService(
    sl<DioClient>().dio,
    'https://api.example.com', // TODO: Replace with actual API base URL
  ));

  // Features - Events
  // Bloc
  sl.registerFactory(
    () => EventsBloc(
      getEvents: sl(),
      getEventsByCategory: sl(),
      createEvent: sl(),
    ),
  );

  // Features - User
  // Bloc
  sl.registerFactory(
    () => UserBloc(
      authService: sl(),
    ),
  );

  // Features - Posts
  // Bloc
  sl.registerFactory(
    () => PostsBloc(
      getPosts: sl(),
      createPost: sl(),
      likePost: sl(),
      unlikePost: sl(),
      repostPost: sl(),
      getComments: sl(),
      createComment: sl(),
      likeComment: sl(),
      unlikeComment: sl(),
    ),
  );

  // Features - Tickets
  // Bloc
  sl.registerFactory(
    () => TicketsBloc(
      purchaseTicket: sl(),
      getUserTickets: sl(),
      checkInTicket: sl(),
    ),
  );

  // Use cases - Events
  sl.registerLazySingleton(() => GetEvents(sl()));
  sl.registerLazySingleton(() => GetEventsByCategory(sl()));
  sl.registerLazySingleton(() => CreateEvent(sl()));

  // Use cases - Posts
  sl.registerLazySingleton(() => GetPosts(sl()));
  sl.registerLazySingleton(() => GetFeedPosts(sl()));
  sl.registerLazySingleton(() => CreatePost(sl()));
  sl.registerLazySingleton(() => LikePost(sl()));
  sl.registerLazySingleton(() => UnlikePost(sl()));
  sl.registerLazySingleton(() => RepostPost(sl()));
  sl.registerLazySingleton(() => GetComments(sl()));
  sl.registerLazySingleton(() => CreateComment(sl()));
  sl.registerLazySingleton(() => LikeComment(sl()));
  sl.registerLazySingleton(() => UnlikeComment(sl()));

  // Use cases - Tickets
  sl.registerLazySingleton(() => PurchaseTicket(sl()));
  sl.registerLazySingleton(() => GetUserTickets(sl()));
  sl.registerLazySingleton(() => CheckInTicket(sl()));

  // Data sources - Remote
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<TicketRemoteDataSource>(
    () => TicketRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );

  // Data sources - Local
  sl.registerLazySingleton<EventLocalDataSource>(
    () => EventLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<TicketLocalDataSource>(
    () => TicketLocalDataSource(sharedPreferences: sl()),
  );
  
  // Repository - Events (Real repository with API)
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Repository - Posts
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Repository - Tickets
  sl.registerLazySingleton<TicketRepository>(
    () => TicketRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      paymentService: sl(),
    ),
  );
}