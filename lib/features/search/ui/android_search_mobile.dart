import 'package:ado_dad_user/features/search/ui/search_page.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AndroidSearchMobile extends StatelessWidget {
  final String? previousRoute;
  const AndroidSearchMobile({super.key, this.previousRoute});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdvertisementBloc(repository: AddRepository()),
      child: SearchPage(previousRoute: previousRoute),
    );
  }
}
