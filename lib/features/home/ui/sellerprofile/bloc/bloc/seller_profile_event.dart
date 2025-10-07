part of 'seller_profile_bloc.dart';

@freezed
class SellerProfileEvent with _$SellerProfileEvent {
  const factory SellerProfileEvent.fetchUserAds(String userId) = _FetchUserAds;
  const factory SellerProfileEvent.loadMore(String userId) = _LoadMore;
}
