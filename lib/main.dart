import 'package:ado_dad_user/common/app_routes.dart';
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
import 'package:ado_dad_user/repositories/add_repo.dart';
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
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  // Set up global error handlers before zone
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ [FLUTTER ERROR] ${details.exception}');
    print('❌ [FLUTTER ERROR] Stack: ${details.stack}');

    FlutterError.presentError(details);
  };

  // Set up zone error handler for async errors
  // IMPORTANT: ensureInitialized() must be called inside the same zone as runApp()
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock orientation to portrait mode only
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      print('✅ [MAIN] Orientation locked');
      debugPrint('✅ [MAIN] Orientation locked');

      // Initialize environment configuration
      await AppConfig.load();
      print('✅ [MAIN] AppConfig loaded');
      debugPrint('✅ [MAIN] AppConfig loaded');

      // Configure iOS scrolling behavior
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
      print('✅ [MAIN] SystemUIOverlayStyle configured');
      debugPrint('✅ [MAIN] SystemUIOverlayStyle configured');

      // Initialize SharedPreferences
      // On iOS, add a longer delay to ensure native channel is ready
      // This prevents "channel-error" on iOS while keeping Android fast
      // The delay also helps avoid conflicts with connectivity plugin initialization
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Initialize SharedPreferences (with automatic retry on iOS if needed)
      // If initialization fails, it will retry automatically when first accessed
      await SharedPrefs().init();

      // On iOS, add a small delay after initialization to let channel stabilize
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      runApp(const MyApp());
    } catch (e, stackTrace) {
      print('❌ [MAIN] ERROR during initialization: $e');
      print('❌ [MAIN] Stack trace: $stackTrace');
      debugPrint('❌ [MAIN] ERROR during initialization: $e');
      debugPrint('❌ [MAIN] Stack trace: $stackTrace');
      // Still try to run the app even if initialization fails
      runApp(const MyApp());
    }
  }, (error, stackTrace) {
    print('❌ [ZONE ERROR] $error');
    print('❌ [ZONE ERROR] Stack: $stackTrace');
    debugPrint('❌ [ZONE ERROR] $error');
    debugPrint('❌ [ZONE ERROR] Stack: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            return LoginBloc(authRepository: AuthRepository())
              ..add(const LoginEvent.checkLoginStatus());
          },
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
        builder: (context, child) {
          // Ensure child is never null - show splash screen if router hasn't initialized yet
          final childWidget = child ??
              const Scaffold(
                backgroundColor:
                    Colors.red, // Red background to see if this is shown
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );

          return StartupConnectivityGate(
            child: childWidget,
            onBackOnline: () {
              // Optional warm-ups once online (before login UI proceeds)
              // context.read<BannerBloc>().add(BannerEvent.fetchBanners());
            },
          );
        },
      ),
    );
  }
}
