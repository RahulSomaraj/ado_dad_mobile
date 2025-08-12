part of 'seller_bloc.dart';

@freezed
class SellerEvent with _$SellerEvent {
  const factory SellerEvent.started() = _Started;
  const factory SellerEvent.addAdvertisement(AdvertisementModel advertisement) =
      _AddAdvertisement;
  // const factory SellerEvent.uploadImage(File imageFile) = _UploadImage;
  const factory SellerEvent.uploadImageToS3(Uint8List image) = _UploadImageToS3;
  const factory SellerEvent.updateImageUrls({
    required String adId,
    required List<String> imageUrls,
  }) = _UpdateImageUrls;
  const factory SellerEvent.updatePersonalInfo({
    required String adId,
    required String fullName,
    required String phoneNumber,
    required String state,
    required String city,
    required String district,
  }) = _UpdatePersonalInfo;
}
