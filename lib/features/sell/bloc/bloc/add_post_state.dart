part of 'add_post_bloc.dart';

@freezed
class AddPostState with _$AddPostState {
  const factory AddPostState.initial() = _Initial;
  const factory AddPostState.loading() = _Loading;
  const factory AddPostState.commercialVehicleTypesLoading() =
      _CommercialVehicleTypesLoading;
  const factory AddPostState.commercialVehicleTypesLoaded(
      List<CommercialVehicleType> items) = _CommercialVehicleTypesLoaded;
  const factory AddPostState.commercialVehicleTypesFailure(String message) =
      _CommercialVehicleTypesFailure;
  const factory AddPostState.success() = _Success;
  const factory AddPostState.failure(String message) = _Failure;
}
