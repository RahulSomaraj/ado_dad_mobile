import 'package:ado_dad_user/features/chat/ui/chat.dart';
import 'package:ado_dad_user/features/home/ui/car_filters_page.dart';
import 'package:ado_dad_user/features/home/ui/category_list_page.dart';
import 'package:ado_dad_user/features/home/ui/home.dart';
import 'package:ado_dad_user/features/home/ui/vehicle_detail_page.dart';
import 'package:ado_dad_user/features/login/ui/login.dart';
import 'package:ado_dad_user/features/profile/ui/profile.dart';
import 'package:ado_dad_user/features/search/ui/search.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_commercial_vehicle_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_private_vehicle_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_property_form.dart';
import 'package:ado_dad_user/features/sell/ui/form/add_two_wheeler_form.dart';
import 'package:ado_dad_user/features/seller/ui/add_advertisement_form1.dart';
import 'package:ado_dad_user/features/sell/ui/item_category.dart';
import 'package:ado_dad_user/features/seller/ui/property_category_selection.dart';
import 'package:ado_dad_user/features/sell/ui/seller.dart';
import 'package:ado_dad_user/features/seller/ui/vehicle_essential_details_form.dart';
import 'package:ado_dad_user/features/seller/ui/vehicle_more_detail_form.dart';
import 'package:ado_dad_user/features/seller/ui/vehicle_personal_detail_form.dart';
import 'package:ado_dad_user/features/signup/ui/signup.dart';
import 'package:ado_dad_user/features/splash/splash.dart';
import 'package:ado_dad_user/features/splash/splash_screen1.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => Splash()),
      GoRoute(path: '/splash-1', builder: (context, state) => SplashScreen1()),
      GoRoute(path: '/splash-2', builder: (context, state) => SplashScreen2()),
      GoRoute(path: '/splash-3', builder: (context, state) => SplashScreen3()),
      GoRoute(path: '/splash-4', builder: (context, state) => SplashScreen4()),
      GoRoute(path: '/login', builder: (context, state) => const Login()),
      GoRoute(path: '/home', builder: (context, state) => const Home()),
      GoRoute(path: '/logout', builder: (context, state) => const Login()),
      GoRoute(path: '/signup', builder: (context, state) => const Signup()),
      GoRoute(path: '/chat', builder: (context, state) => const Chat()),
      GoRoute(path: '/profile', builder: (context, state) => const Profile()),
      GoRoute(path: '/search', builder: (context, state) => const Search()),
      GoRoute(path: '/seller', builder: (context, state) => const Seller()),
      GoRoute(
        path: '/vehicle-form',
        builder: (context, state) {
          final String category =
              state.uri.queryParameters['category'] ?? 'Vehicle';
          return VehicleEssentialDetails(categoryTitle: category);
        },
      ),
      GoRoute(
        path: '/advertisement-form1',
        builder: (context, state) {
          final String category =
              state.uri.queryParameters['category'] ?? 'Vehicle';
          return AddAdvertisementForm1(categoryTitle: category);
        },
      ),
      GoRoute(
          path: '/item-category',
          builder: (context, state) => const ItemCategory()),
      GoRoute(
        path: '/vehicle-more-detail',
        builder: (context, state) {
          final adId = state.extra as String;
          return VehicleMoreDetailForm(advertisementId: adId);
        },
        // builder: (context, state) => const VehicleMoreDetailForm()
      ),
      // GoRoute(
      //     path: '/vehicle-personal-detail',
      //     builder: (context, state) => const VehiclePersonalDetailForm()),
      // GoRoute(
      //   path: '/vehicle-personal-detail',
      //   builder: (context, state) {
      //     final adId = state.extra as String;
      //     return VehiclePersonalDetailForm(addId: adId);
      //   },
      //   // builder: (context, state) => const VehicleMoreDetailForm()
      // ),
      GoRoute(
        path: '/vehicle-personal-detail/:adId',
        builder: (context, state) {
          final adId = state.pathParameters['adId']!;
          return VehiclePersonalDetailForm(addId: adId);
        },
      ),

      GoRoute(
          path: '/property-category-selection',
          builder: (context, state) => const PropertyCategorySelection()),
      // GoRoute(
      //   path: '/category-list-page',
      //   builder: (context, state) {
      //     final String category =
      //         state.uri.queryParameters['category'] ?? 'Vehicle';
      //     return CategoryListPage(categoryTitle: category);
      //   },
      // ),
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
          path: '/vehicle-detail-page',
          builder: (context, state) => const VehicleDetailPage()),
      // GoRoute(
      //   path: '/vehicle-detail-page',
      //   builder: (context, state) {
      //     final vehicle = state.extra as Vehicle;
      //     return VehicleDetailPage(vehicle: vehicle);
      //   },
      // ),
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
          path: '/car-filter',
          builder: (context, state) => const CarFiltersPage()),
    ],
  );
}
