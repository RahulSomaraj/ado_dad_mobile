import 'package:ado_dad_user/models/banner_model.dart';
import 'package:ado_dad_user/repositories/banner_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner_event.dart';
part 'banner_state.dart';
part 'banner_bloc.freezed.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerRepository bannerRepository;
  BannerBloc({required this.bannerRepository})
      : super(const BannerState.initial()) {
    on<FetchBanners>((event, emit) async {
      emit(const BannerState.loading());

      try {
        final List<BannerModel> banners = await bannerRepository.fetchBanners();
        emit(BannerState.loaded(banners));
      } catch (e) {
        // Emit user-friendly message instead of raw exception
        emit(BannerState.error(
            "Unable to load banners at the moment. Please try again later."));
      }
    });
  }
}
