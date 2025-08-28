import 'package:ado_dad_user/models/advertisement_post_model/vehicle_manufacturer_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'manufacturer_event.dart';
part 'manufacturer_state.dart';
part 'manufacturer_bloc.freezed.dart';

class ManufacturerBloc extends Bloc<ManufacturerEvent, ManufacturerState> {
  final AddRepository repository;
  ManufacturerBloc({required this.repository})
      : super(const ManufacturerState.initial()) {
    on<_LoadManufacturers>(_onLoad);
  }

  Future<void> _onLoad(
      _LoadManufacturers event, Emitter<ManufacturerState> emit) async {
    emit(const ManufacturerState.loading());
    try {
      final list = await repository.fetchManufacturers();
      emit(ManufacturerState.loaded(list));
    } catch (e) {
      emit(ManufacturerState.error('Failed to load brands: $e'));
    }
  }
}
