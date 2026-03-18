import 'package:ado_dad_user/models/advertisement_post_model/commercial_vehicle_type_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commercial_vehicle_type_filter_event.dart';
part 'commercial_vehicle_type_filter_state.dart';
part 'commercial_vehicle_type_filter_bloc.freezed.dart';

class CommercialVehicleTypeFilterBloc extends Bloc<CommercialVehicleTypeFilterEvent,
    CommercialVehicleTypeFilterState> {
  final AddRepository repository;

  CommercialVehicleTypeFilterBloc({required this.repository})
      : super(const CommercialVehicleTypeFilterState.initial()) {
    on<_LoadCommercialVehicleTypes>(_onLoad);
  }

  Future<void> _onLoad(
    _LoadCommercialVehicleTypes event,
    Emitter<CommercialVehicleTypeFilterState> emit,
  ) async {
    emit(const CommercialVehicleTypeFilterState.loading());
    try {
      final items = await repository.fetchCommercialVehicleTypes();
      emit(CommercialVehicleTypeFilterState.loaded(items));
    } catch (e) {
      emit(CommercialVehicleTypeFilterState.error(
          'Failed to load commercial vehicle types: $e'));
    }
  }
}

