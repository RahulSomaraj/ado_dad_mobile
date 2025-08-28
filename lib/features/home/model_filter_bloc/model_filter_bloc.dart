import 'package:ado_dad_user/models/advertisement_post_model/vehilce_model.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_filter_event.dart';
part 'model_filter_state.dart';
part 'model_filter_bloc.freezed.dart';

class ModelFilterBloc extends Bloc<ModelFilterEvent, ModelFilterState> {
  final AddRepository repository;
  ModelFilterBloc({required this.repository})
      : super(const ModelFilterState.initial()) {
    on<_LoadModels>(_onLoad);
  }

  Future<void> _onLoad(
      _LoadModels event, Emitter<ModelFilterState> emit) async {
    emit(const ModelFilterState.loading());
    try {
      final list = await repository.fetchModals();
      emit(ModelFilterState.loaded(list));
    } catch (e) {
      emit(ModelFilterState.error('Failed to load models: $e'));
    }
  }
}
