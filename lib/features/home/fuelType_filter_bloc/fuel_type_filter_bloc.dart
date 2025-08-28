import 'package:ado_dad_user/models/advertisement_post_model/vehicle_fuel_type_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuel_type_filter_event.dart';
part 'fuel_type_filter_state.dart';
part 'fuel_type_filter_bloc.freezed.dart';

class FuelTypeFilterBloc
    extends Bloc<FuelTypeFilterEvent, FuelTypeFilterState> {
  final AddRepository repository;
  FuelTypeFilterBloc({required this.repository})
      : super(const FuelTypeFilterState.initial()) {
    on<_LoadFuelTypes>(_onLoad);
  }

  Future<void> _onLoad(
      _LoadFuelTypes event, Emitter<FuelTypeFilterState> emit) async {
    emit(const FuelTypeFilterState.loading());
    try {
      final list = await repository.fetchVehicleFuelTypes();
      emit(FuelTypeFilterState.loaded(list));
    } catch (e) {
      emit(FuelTypeFilterState.error('Failed to load fuel types: $e'));
    }
  }
}
