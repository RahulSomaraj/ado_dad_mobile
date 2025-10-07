import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/connectivity_checker.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/home/ad_edit/bloc/ad_edit_bloc.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/signup/bloc/signup_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/home/favorite/bloc/favorite_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/repositories/favorite_repo.dart';
import 'package:ado_dad_user/repositories/banner_repo.dart';
import 'package:ado_dad_user/repositories/login_repository.dart';
import 'package:ado_dad_user/repositories/profile_repo.dart';
import 'package:ado_dad_user/repositories/signup_repository.dart';
import 'package:ado_dad_user/repositories/socket_service.dart';
import 'package:ado_dad_user/features/profile/MyAds/bloc/my_ads_bloc.dart';
import 'package:ado_dad_user/repositories/my_ads_repo.dart';
import 'package:ado_dad_user/features/home/ui/sellerprofile/bloc/bloc/seller_profile_bloc.dart';
import 'package:ado_dad_user/repositories/seller_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs().init();
  final socketService = SocketService();
  socketService.connect();
  runApp(MyApp(socketService: socketService));
}

class MyApp extends StatelessWidget {
  final SocketService socketService;
  const MyApp({super.key, required this.socketService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(authRepository: AuthRepository())
            ..add(const LoginEvent.checkLoginStatus()),
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
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc()..add(const ChatEvent.connect()),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) =>
              FavoriteBloc(favoriteRepository: FavoriteRepository()),
        ),
        BlocProvider<SellerProfileBloc>(
          create: (context) =>
              SellerProfileBloc(repository: SellerProfileRepository()),
        ),
      ],
      child: MaterialApp.router(
        title: 'ADO-DAD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: AppRoutes.router,
        // ✅ This wraps every page with a connectivity gate
        // ✅ Shows only at first app open, before login, until real internet is available
        builder: (context, child) => StartupConnectivityGate(
          child: child ?? const SizedBox.shrink(),
          onBackOnline: () {
            // Optional warm-ups once online (before login UI proceeds)
            // context.read<BannerBloc>().add(BannerEvent.fetchBanners());
            // socketService.connect();
          },
        ),
      ),
    );
  }
}
