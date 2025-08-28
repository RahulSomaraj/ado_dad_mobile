import 'package:ado_dad_user/models/advertisement_post_model/vehicle_transmission_type_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transmission_type_filter_event.dart';
part 'transmission_type_filter_state.dart';
part 'transmission_type_filter_bloc.freezed.dart';

class TransmissionTypeFilterBloc
    extends Bloc<TransmissionTypeFilterEvent, TransmissionTypeFilterState> {
  final AddRepository repository;
  TransmissionTypeFilterBloc({required this.repository})
      : super(const TransmissionTypeFilterState.initial()) {
    on<_LoadTransmissionTypes>(_onLoad);
  }

  Future<void> _onLoad(_LoadTransmissionTypes event,
      Emitter<TransmissionTypeFilterState> emit) async {
    emit(const TransmissionTypeFilterState.loading());
    try {
      final list = await repository.fetchVehicleTransmissionTypes();
      emit(TransmissionTypeFilterState.loaded(list));
    } catch (e) {
      emit(TransmissionTypeFilterState.error(
          'Failed to load transmission types: $e'));
    }
  }
}
