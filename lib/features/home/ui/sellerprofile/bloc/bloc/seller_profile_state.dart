part of 'seller_profile_bloc.dart';

@freezed
class SellerProfileState with _$SellerProfileState {
  const factory SellerProfileState.initial() = _Initial;
  const factory SellerProfileState.loading() = _Loading;
  const factory SellerProfileState.loaded({
    required List<AddModel> ads,
    required bool hasNext,
    required int page,
    @Default(false) bool isPaging,
  }) = _Loaded;
  const factory SellerProfileState.error(String message) = _Error;
}
