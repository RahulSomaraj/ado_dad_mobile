import 'package:ado_dad_user/features/chat/ui/chat_thread_page.dart';
import 'package:ado_dad_user/features/chat/ui/messages_page.dart';
import 'package:ado_dad_user/features/chat/ui/chat_connection_test.dart';
import 'package:ado_dad_user/features/chat/ui/socket_debug_page.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
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
import 'package:ado_dad_user/features/login/ui/login.dart';
import 'package:ado_dad_user/features/profile/MyAds/ui/my_ads_page.dart';
import 'package:ado_dad_user/features/profile/ui/profile.dart';
import 'package:ado_dad_user/features/profile/wishlist/wishlist_page.dart';
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
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      // Chat routes
      GoRoute(
        path: '/messages',
        builder: (c, s) {
          final previousRoute = s.uri.queryParameters['from'];
          return MessagesPage(previousRoute: previousRoute);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (c, s) {
          final data = s.extra as ChatThread?;
          return ChatThreadPage(
            peerName: data?.name ?? 'Chat',
            avatarUrl: data?.avatarUrl ?? '',
            threadId: s.pathParameters['id']!,
          );
        },
      ),

      // Chat socket test route
      GoRoute(
        path: '/chat-test',
        builder: (context, state) => const ChatConnectionTest(),
      ),

      // Socket debug route
      GoRoute(
        path: '/socket-debug',
        builder: (context, state) => const SocketDebugPage(),
      ),

      // Legacy chat route for backward compatibility
      // GoRoute(path: '/chat', builder: (context, state) => const MessagesPage()),
      GoRoute(path: '/profile', builder: (context, state) => const Profile()),
      GoRoute(
          path: '/wishlist', builder: (context, state) => const WishlistPage()),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final previousRoute = state.uri.queryParameters['from'];
          return Search(previousRoute: previousRoute);
        },
      ),
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
        path: '/add-detail-page',
        builder: (context, state) {
          final ad = state.extra as AddModel;
          // final adId = state.extra as String;
          return BlocProvider(
            create: (_) => AdDetailBloc(repository: AddRepository())
              ..add(AdDetailEvent.fetch(ad.id)),
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

          // Use passed user data or fallback to basic data
          final seller = userData ??
              AdUser(
                id: sellerId,
                name: 'Seller',
                email: null,
              );

          // TODO: Replace with actual API call to fetch seller's ads
          // For now, using empty list
          final sellerAds = <AddModel>[];

          return SellerProfilePage(
            seller: seller,
            ads: sellerAds,
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

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => ManufacturerBloc(repository: repo)
                  ..add(const ManufacturerEvent.load()),
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
            child: const CarFiltersPage(),
          );
        },
      ),
      GoRoute(
        path: '/property-filter',
        builder: (context, state) => const PropertyFiltersPage(),
      ),
      GoRoute(path: '/my-ads', builder: (context, state) => const MyAdsPage()),
    ],
  );
}
