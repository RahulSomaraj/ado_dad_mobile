import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/home/commercial_vehicle_type_filter_bloc/commercial_vehicle_type_filter_bloc.dart';
import 'package:ado_dad_user/features/home/fuelType_filter_bloc/fuel_type_filter_bloc.dart';
import 'package:ado_dad_user/features/home/manufacturer_bloc/manufacturer_bloc.dart';
import 'package:ado_dad_user/features/home/model_filter_bloc/model_filter_bloc.dart';
import 'package:ado_dad_user/features/home/transmissionType_filter_bloc/transmission_type_filter_bloc.dart';
import 'package:ado_dad_user/features/home/ui/car_filters_page.dart';
import 'package:ado_dad_user/features/home/ui/property_filter_page.dart';
import 'package:ado_dad_user/features/home/ui/category_list_page.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/commercial_vehicle_form_edit.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/private_vehicle_form_edit.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/property_form_edit.dart';
import 'package:ado_dad_user/features/home/ui/edit_add_details/two_wheeler_form_edit.dart';
import 'package:ado_dad_user/features/home/ui/home.dart';
import 'package:ado_dad_user/features/home/ui/add_detail_page.dart';
import 'package:ado_dad_user/features/home/ui/sellerprofile/seller_profile_page.dart';
import 'package:ado_dad_user/features/home/ui/notifications.dart';
import 'package:ado_dad_user/features/login/ui/login.dart';
import 'package:ado_dad_user/features/login/ui/otp_login_page.dart';
import 'package:ado_dad_user/features/login/ui/otp_verification_page.dart';
import 'package:ado_dad_user/features/profile/MyAds/ui/my_ads_page.dart';
import 'package:ado_dad_user/features/profile/ui/profile.dart';
import 'package:ado_dad_user/features/profile/ui/my_activity_page.dart';
import 'package:ado_dad_user/common/widgets/scaffold_with_nav_bar.dart';
import 'package:ado_dad_user/features/profile/help/help.dart';
import 'package:ado_dad_user/features/profile/wishlist/wishlist_page.dart';
import 'package:ado_dad_user/features/search/ui/search.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_commercial_vehicle_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_private_vehicle_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_property_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_two_wheeler_form.dart';
import 'package:ado_dad_user/features/sell/ui/item_category.dart';
import 'package:ado_dad_user/features/sell/ui/seller.dart';
import 'package:ado_dad_user/features/signup/ui/signup.dart';
import 'package:ado_dad_user/features/splash/splash.dart';
import 'package:ado_dad_user/features/splash/splash_screen1.dart';
import 'package:ado_dad_user/features/chat/ui/chat_rooms_page.dart';
import 'package:ado_dad_user/features/chat/ui/chat_page.dart';
import 'package:ado_dad_user/features/chat/ui/chat_debug_page.dart';
import 'package:ado_dad_user/features/showroom/ui/showroom_users_page.dart';
import 'package:ado_dad_user/features/showroom/ui/showroom_user_ads_page.dart';
import 'package:ado_dad_user/features/showroom/bloc/showroom_bloc.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/repositories/showroom_repo.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  /// Use this context to show dialogs from app-level widgets (e.g. version check)
  /// that live above the Navigator in the tree.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.uri.toString();
      final redirectPath = await AuthGuard.checkRouteAccess(location);
      return redirectPath;
    },
    // Friendly fallback for unmatched routes or builder exceptions, instead of
    // GoRouter's raw red error screen (e.g. an empty/invalid '/chat/' path).
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
    routes: [
      GoRoute(path: '/', builder: (context, state) => Splash()),
      GoRoute(path: '/splash-1', builder: (context, state) => SplashScreen1()),
      GoRoute(path: '/splash-2', builder: (context, state) => SplashScreen2()),
      GoRoute(path: '/splash-3', builder: (context, state) => SplashScreen3()),
      GoRoute(path: '/splash-4', builder: (context, state) => SplashScreen4()),
      GoRoute(path: '/login', builder: (context, state) => const Login()),
      GoRoute(
          path: '/login-otp',
          builder: (context, state) => const OtpLoginPage()),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationPage(
            identifier: extra['identifier'] as String,
            isEmail: extra['isEmail'] as bool,
          );
        },
      ),
      // Persistent bottom-nav shell: Home · My Activity · Chat · Profile.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => Home(
                  showLoginPromptForNotifications:
                      state.uri.queryParameters['prompt'] == 'notifications',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-activity',
                builder: (context, state) => const MyActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat-rooms',
                builder: (context, state) {
                  final fromPage = state.uri.queryParameters['from'];
                  return ChatRoomsPage(fromPage: fromPage);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const Profile(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const Notifications(),
      ),
      GoRoute(path: '/logout', builder: (context, state) => const Login()),
      GoRoute(path: '/signup', builder: (context, state) => const Signup()),
      GoRoute(
          path: '/wishlist', builder: (context, state) => const WishlistPage()),
      GoRoute(path: '/help', builder: (context, state) => const Help()),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final previousRoute = state.uri.queryParameters['from'];
          return Search(previousRoute: previousRoute);
        },
      ),
      GoRoute(path: '/seller', builder: (context, state) => const Seller()),
      GoRoute(
          path: '/item-category',
          builder: (context, state) => const ItemCategory()),
      GoRoute(
        path: '/category-list-page',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId']!;
          final title = state.uri.queryParameters['title']!;
          return CategoryListPage(
            categoryId: categoryId,
            categoryTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/add-detail-page',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          // final adId = state.extra as String;
          return BlocProvider(
            create: (_) => AdDetailBloc(
              repository: AddRepository(),
            )..add(AdDetailEvent.fetch(ad.id)),
            child: AdDetailPage(ad: ad),
          );
        },
      ),
      GoRoute(
        path: '/seller-profile/:id',
        builder: (context, state) {
          final sellerId = state.pathParameters['id']!;

          // Get user data passed from the seller tile navigation
          final userData = state.extra as AdUser?;

          // Always use the seller ID from URL, but use userData for name/email if available
          final seller = AdUser(
            id: sellerId, // Always use seller ID from URL
            name: userData?.name ?? 'Seller',
            email: userData?.email,
            profilePic: userData?.profilePic,
            phone: userData?.phone,
          );

          return SellerProfilePage(
            seller: seller,
          );
        },
      ),
      GoRoute(
        path: '/add-two-wheeler-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return AddTwoWheelerForm(
            categoryTitle: extra['categoryTitle']!,
            categoryId: extra['categoryId']!,
          );
        },
      ),
      GoRoute(
        path: '/add-commercial-vehicle-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return AddCommercialVehicleForm(
            categoryTitle: extra['categoryTitle']!,
            categoryId: extra['categoryId']!,
          );
        },
      ),
      GoRoute(
        path: '/add-private-vehicle-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return AddPrivateVehicleForm(
            categoryTitle: extra['categoryTitle']!,
            categoryId: extra['categoryId']!,
          );
        },
      ),
      GoRoute(
        path: '/add-property-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return AddPropertyForm(
            categoryTitle: extra['categoryTitle']!,
            categoryId: extra['categoryId']!,
          );
        },
      ),
      GoRoute(
        path: '/edit-two-wheeler',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          return TwoWheelerFormEdit(ad: ad);
        },
      ),
      GoRoute(
        path: '/edit-private-vehicle',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          return PrivateVehicleFormEdit(ad: ad);
        },
      ),
      GoRoute(
        path: '/edit-commercial-vehicle',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          return CommercialVehicleFormEdit(ad: ad);
        },
      ),
      GoRoute(
        path: '/edit-property',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          return PropertyFormEdit(ad: ad);
        },
      ),
      GoRoute(
        path: '/car-filter',
        builder: (context, state) {
          final repo = context.read<AdvertisementBloc>().repository;
          final categoryId = state.uri.queryParameters['categoryId'];
          final categoryTitle = state.uri.queryParameters['title'];
          final currentFilters = state.extra as Map<String, dynamic>?;

          // Determine vehicleCategory based on categoryId
          // Note: Both "Car" and "Premium Vehicles" use categoryId 'private_vehicle'
          // Both should show 'passenger_car' manufacturers
          String? vehicleCategory;
          if (categoryId == 'two_wheeler') {
            vehicleCategory = 'two_wheeler';
          } else if (categoryId == 'private_vehicle' ||
              categoryId == 'commercial_vehicle') {
            vehicleCategory = 'passenger_car';
          }

          return MultiBlocProvider(
            providers: [
              if (categoryId == 'commercial_vehicle')
                BlocProvider(
                  create: (_) => CommercialVehicleTypeFilterBloc(repository: repo)
                    ..add(const CommercialVehicleTypeFilterEvent.load()),
                ),
              BlocProvider(
                create: (_) => ManufacturerBloc(repository: repo)
                  ..add(
                      ManufacturerEvent.load(vehicleCategory: vehicleCategory)),
              ),
              BlocProvider(
                create: (_) => FuelTypeFilterBloc(repository: repo)
                  ..add(const FuelTypeFilterEvent.load()),
              ),
              BlocProvider(
                create: (_) => TransmissionTypeFilterBloc(repository: repo)
                  ..add(const TransmissionTypeFilterEvent.load()),
              ),
              BlocProvider(
                create: (_) => ModelFilterBloc(repository: repo)
                  ..add(const ModelFilterEvent.load()),
              ),
            ],
            child: CarFiltersPage(
                categoryId: categoryId,
                categoryTitle: categoryTitle,
                currentFilters: currentFilters),
          );
        },
      ),
      GoRoute(
        path: '/property-filter',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final categoryTitle = state.uri.queryParameters['title'];
          final currentFilters = state.extra as Map<String, dynamic>?;
          return PropertyFiltersPage(
              categoryId: categoryId,
              categoryTitle: categoryTitle,
              currentFilters: currentFilters);
        },
      ),
      GoRoute(path: '/my-ads', builder: (context, state) => const MyAdsPage()),

      // Chat routes ('/chat-rooms' lives in the nav shell above)
      GoRoute(
          path: '/chat/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId']!;
            final otherUserName = state.uri.queryParameters['name'];
            final otherUserProfilePic = state.uri.queryParameters['profilePic'];
            final otherUserPhone = state.uri.queryParameters['phone'];
            final fromPage = state.uri.queryParameters['from'];
            final adId = state.uri.queryParameters['adId'];
            final adTitle = state.uri.queryParameters['adTitle'];
            final adPrice = int.tryParse(
                state.uri.queryParameters['price'] ?? '');
            return ChatPage(
              roomId: roomId,
              otherUserName: otherUserName,
              otherUserProfilePic: otherUserProfilePic,
              otherUserPhone: otherUserPhone,
              fromPage: fromPage,
              adId: adId,
              adTitle: adTitle,
              adPrice: adPrice,
            );
          }),
      GoRoute(
          path: '/chat-debug',
          builder: (context, state) => const ChatDebugPage()),

      // Showroom routes
      GoRoute(
          path: '/showroom-users',
          builder: (context, state) => const ShowroomUsersPage()),
      GoRoute(
          path: '/showroom-user-ads',
          builder: (context, state) {
            final userId = state.extra as String;
            return BlocProvider(
              create: (_) => ShowroomBloc(repository: ShowroomRepo()),
              child: ShowroomUserAdsPage(userId: userId),
            );
          }),
    ],
  );
}

/// Sensible fallback screen shown by [GoRouter.errorBuilder] when a route can't
/// be matched or a page builder throws, replacing the default red error page.
class _RouteErrorScreen extends StatelessWidget {
  final Exception? error;
  const _RouteErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Something went wrong'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: AppColors.greyColor),
              const SizedBox(height: 16),
              Text(
                'We couldn’t open that page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The link may be broken or the content is no longer available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.greyColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
