import 'dart:typed_data';

import 'package:ado_dad_user/models/advertisement/advertisement_model.dart';
import 'package:ado_dad_user/repositories/advertiselemt_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'seller_event.dart';
part 'seller_state.dart';
part 'seller_bloc.freezed.dart';

class SellerBloc extends Bloc<SellerEvent, SellerState> {
  final AdvertisementRepository repository;
  SellerBloc({required this.repository}) : super(const SellerState.initial()) {
    on<_AddAdvertisement>(_onAddAdvertisement);

    on<_UploadImageToS3>(_onUploadImage);

    on<_UpdateImageUrls>(_updateImageUrls);

    on<_UpdatePersonalInfo>(_onUpdatePersonalInfo);
  }

  // Add advertisement
  Future<void> _onAddAdvertisement(
      _AddAdvertisement event, Emitter<SellerState> emit) async {
    emit(const SellerState.loading());

    try {
      final newAdvertisement =
          await repository.addAdvertisement(event.advertisement);
      print('??????????????????test?????????????????????????');
      if (newAdvertisement != null) {
        emit(SellerState.success(newAdvertisement));
        print("✅ Created Ad ID: ${newAdvertisement.id}");
      } else {
        emit(const SellerState.failure("Failed to receive valid response"));
      }

      // emit(SellerState.success(newAdvertisement!));
    } catch (e) {
      print('exception:................$e');
      emit(SellerState.failure("Failed to add advertisement"));
    }
  }

  /// Upload image to S3 using repository's unified method
  Future<void> _onUploadImage(
    _UploadImageToS3 event,
    Emitter<SellerState> emit,
  ) async {
    emit(const SellerState.loading());
    try {
      final String? imageUrl = await repository.uploadImageToS3(event.image);
      if (imageUrl != null) {
        emit(SellerState.successImageUpload(imageUrl));
      } else {
        emit(const SellerState.failure("Upload failed: No URL returned"));
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      emit(SellerState.failure("Upload error: ${e.toString()}"));
    }
  }

  /// Update image URLs in advertisement
  Future<void> _updateImageUrls(
    _UpdateImageUrls event,
    Emitter<SellerState> emit,
  ) async {
    emit(const SellerState.loading());
    try {
      await repository.updateAdvertisementImages(
        advertisementId: event.adId,
        imageUrls: event.imageUrls,
      );
      print('✅ Image URLs updated for adId: ${event.adId}');
      emit(SellerState.successImageUpload(
        event.imageUrls.isNotEmpty ? event.imageUrls.first : '',
      ));
    } catch (e) {
      print('❌ Failed to update image URLs: $e');
      emit(SellerState.failure("Failed to update image URLs"));
    }
  }

  Future<void> _onUpdatePersonalInfo(
    _UpdatePersonalInfo event,
    Emitter<SellerState> emit,
  ) async {
    emit(const SellerState.loading());
    try {
      await repository.updatePersonalInfo(
          advertisementId: event.adId,
          fullName: event.fullName,
          phoneNumber: event.phoneNumber,
          state: event.state,
          city: event.city,
          district: event.district);
      emit(const SellerState.successMessage(
          "Personal info updated successfully"));
    } catch (e) {
      emit(SellerState.failure("Failed to update personal info: $e"));
    }
  }
}
