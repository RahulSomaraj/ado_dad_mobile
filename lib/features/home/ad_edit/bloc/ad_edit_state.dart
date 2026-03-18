part of 'ad_edit_bloc.dart';

@freezed
class AdEditState with _$AdEditState {
  const factory AdEditState.idle() = _Idle;
  const factory AdEditState.commercialVehicleTypesLoading() =
      _CommercialVehicleTypesLoading;
  const factory AdEditState.commercialVehicleTypesLoaded(
      List<CommercialVehicleType> items) = _CommercialVehicleTypesLoaded;
  const factory AdEditState.commercialVehicleTypesFailure(String message) =
      _CommercialVehicleTypesFailure;
  const factory AdEditState.saving() = _Saving;
  const factory AdEditState.success(AddModel updated) = _Success;
  const factory AdEditState.failure(String message) = _Failure;
}
