import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/home/banner_bloc/banner_bloc.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/features/sell/bloc/bloc/add_post_bloc.dart';
import 'package:ado_dad_user/features/signup/bloc/signup_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:ado_dad_user/repositories/banner_repo.dart';
import 'package:ado_dad_user/repositories/login_repository.dart';
import 'package:ado_dad_user/repositories/profile_repo.dart';
import 'package:ado_dad_user/repositories/signup_repository.dart';
import 'package:ado_dad_user/repositories/socket_service.dart';
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
        BlocProvider(
          create: (context) =>
              ChatBloc(socketService: socketService), // ✅ Provide ChatBloc
        ),
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
      ],
      child: MaterialApp.router(
        title: 'ADO-DAD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
