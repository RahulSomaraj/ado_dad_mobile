part of 'seller_bloc.dart';

@freezed
class SellerState with _$SellerState {
  const factory SellerState.initial() = Initial;
  const factory SellerState.loading() = Loading;
  const factory SellerState.success(AdvertisementModel advertisement) =
      AddAvertisementSuccess;

  // const factory SellerState.successImageUpload() = _UploadImageSuccess;
  const factory SellerState.successImageUpload(String imageUrl) =
      _SuccessImageUpload;

  const factory SellerState.failure(String error) = Failure;
  const factory SellerState.successMessage(String message) = _SuccessMessage;
}
