import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/local_notification_service.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ado_dad_user/common/connectivity_checker.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/report_ad_bloc/report_ad_bloc.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:ado_dad_user/features/login/bloc/otp_bloc.dart';
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/signup/bloc/signup_bloc.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/features/home/notification_bloc/bloc/notification_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/repositories/notification_repo.dart';
import 'package:ado_dad_user/repositories/favorite_repo.dart';
import 'package:ado_dad_user/repositories/banner_repo.dart';
import 'package:ado_dad_user/repositories/login_repository.dart';
import 'package:ado_dad_user/repositories/profile_repo.dart';
import 'package:ado_dad_user/repositories/report_repository.dart';
import 'package:ado_dad_user/repositories/signup_repository.dart';
import 'package:ado_dad_user/features/profile/MyAds/bloc/my_ads_bloc.dart';
import 'package:ado_dad_user/repositories/my_ads_repo.dart';
import 'package:ado_dad_user/features/home/ui/sellerprofile/bloc/bloc/seller_profile_bloc.dart';
import 'package:ado_dad_user/repositories/seller_profile_repo.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// When user opens app by tapping a notification from the scroll shade:
/// - If logged in → go to notifications page.
/// - If not logged in → go to home and show login popup (do not open notifications page).
Future<void> _handleNotificationTap(RemoteMessage message) async {
  debugPrint('FCM tap: ${message.notification?.title} | data: ${message.data}');
  final isAuth = await AuthGuard.isAuthenticated();
  if (isAuth) {
    AppRoutes.router.go('/notifications');
  } else {
    AppRoutes.router.go('/home?prompt=notifications'); // home + login popup only
  }
}

/// Background handler for data-only messages when app is terminated.
/// Must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background: ${message.messageId}');
}

/// Initialize Firebase Cloud Messaging: request permission and get FCM token.
/// Call after Firebase.initializeApp().
Future<void> _initFcm() async {
  final messaging = FirebaseMessaging.instance;

  // Request notification permission (iOS / Android 13+)
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    // Show notifications in foreground on iOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Subscribe to broadcast topic for ALL notifications
    await messaging.subscribeToTopic('all_users');
  }

  // Get FCM token (null if permission denied)
  final token = await messaging.getToken();
  if (token != null) {
    debugPrint('FCM token: $token');
    // TODO: send token to your backend (e.g. PATCH /profile with fcmToken)
  }

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('FCM token refreshed: $newToken');
    // TODO: send newToken to your backend
  });

  // Foreground: app is open when notification arrives — show in system shade (like Swiggy)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    NotificationBadgeService.addNotification(title: title, body: body);
    LocalNotificationService.showFromFcmMessage(message);
  });

  // Background tap: user tapped notification while app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    NotificationBadgeService.addNotification(title: title, body: body);
    // Do not clear badge here – clear only when user opens the notifications page
    _handleNotificationTap(message); // async: opens notifications or home with login popup
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize environment configuration
  await AppConfig.load();

  // Configure iOS scrolling behavior
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SharedPrefs().init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background handler before other FCM code
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM: request permission, topic, and message handlers
  await _initFcm();

  // Tap from scroll shade: go to notifications page only if logged in; else open home and show login popup
  await LocalNotificationService.init(
    onNotificationTap: () async {
      final isAuth = await AuthGuard.isAuthenticated();
      if (isAuth) {
        AppRoutes.router.go('/notifications');
      } else {
        AppRoutes.router.go('/home?prompt=notifications');
      }
    },
  );

  // Cold start: app opened by tapping notification when terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final title = initialMessage.notification?.title ?? 'Notification';
    final body = initialMessage.notification?.body ?? '';
    NotificationBadgeService.addNotification(title: title, body: body);
    // Do not clear badge here – clear only when user opens the notifications page
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleNotificationTap(initialMessage);
    });
  }

  // Token refresh will happen automatically when bearer token expires (401 error)
  // No need to refresh proactively on app startup

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(authRepository: AuthRepository())
            ..add(const LoginEvent.checkLoginStatus()),
        ),
        BlocProvider<OtpBloc>(
          create: (context) => OtpBloc(),
        ),
        BlocProvider<SignupBloc>(
            create: (context) =>
                SignupBloc(signupRepository: SignupRepository())),
        BlocProvider<AdvertisementBloc>(
            create: (context) =>
                AdvertisementBloc(repository: AddRepository())),

        BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(repository: ProfileRepo())),
        BlocProvider(
          create: (context) => BannerBloc(bannerRepository: BannerRepository())
            ..add(BannerEvent.fetchBanners()),
        ),
        // BlocProvider<SellerBloc>(
        //     create: (context) =>
        //         SellerBloc(repository: AdvertisementRepository())),
        BlocProvider<AddPostBloc>(
            create: (context) => AddPostBloc(repository: AddRepository())),
        BlocProvider<AdEditBloc>(
          create: (context) => AdEditBloc(repo: AddRepository()),
        ),
        BlocProvider<MyAdsBloc>(
          create: (context) => MyAdsBloc(repository: MyAdsRepo()),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) =>
              FavoriteBloc(favoriteRepository: FavoriteRepository()),
        ),
        BlocProvider<SellerProfileBloc>(
          create: (context) =>
              SellerProfileBloc(repository: SellerProfileRepository()),
        ),
        BlocProvider<ReportAdBloc>(
          create: (context) =>
              ReportAdBloc(reportRepository: ReportRepository()),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationRepository: NotificationRepository(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'ADO-DAD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          // iOS-specific scrolling configurations
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        routerConfig: AppRoutes.router,
        // ✅ This wraps every page with a connectivity gate
        // ✅ Shows only at first app open, before login, until real internet is available
        builder: (context, child) => StartupConnectivityGate(
          child: child ?? const SizedBox.shrink(),
          onBackOnline: () {
            // Optional warm-ups once online (before login UI proceeds)
            // context.read<BannerBloc>().add(BannerEvent.fetchBanners());
          },
        ),
      ),
    );
  }
}
