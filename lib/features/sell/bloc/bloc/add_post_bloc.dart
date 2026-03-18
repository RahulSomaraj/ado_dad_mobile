import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ado_dad_user/models/advertisement_post_model/commercial_vehicle_type_model.dart';

part 'add_post_event.dart';
part 'add_post_state.dart';
part 'add_post_bloc.freezed.dart';

class AddPostBloc extends Bloc<AddPostEvent, AddPostState> {
  final AddRepository repository;
  AddPostBloc({required this.repository})
      : super(const AddPostState.initial()) {
    on<AddPostEvent>(_mapAdPostEventToState);
  }

  Future<void> _mapAdPostEventToState(
      AddPostEvent event, Emitter<AddPostState> emit) async {
    await event.map(
      started: (_) async {
        emit(const AddPostState.initial());
      },
      loadCommercialVehicleTypes: (e) => _handleLoadCommercialVehicleTypes(e, emit),
      postAd: (e) => _handlePostAd(e, emit),
    );
  }

  Future<void> _handleLoadCommercialVehicleTypes(
    _LoadCommercialVehicleTypes event,
    Emitter<AddPostState> emit,
  ) async {
    emit(const AddPostState.commercialVehicleTypesLoading());
    try {
      final items = await repository.fetchCommercialVehicleTypes();
      emit(AddPostState.commercialVehicleTypesLoaded(items));
    } catch (e) {
      emit(AddPostState.commercialVehicleTypesFailure(e.toString()));
    }
  }

  Future<void> _handlePostAd(_PostAd event, Emitter<AddPostState> emit) async {
    emit(const AddPostState.loading());
    try {
      await repository.postAd(
        category: event.category,
        data: event.data,
      );
      emit(const AddPostState.success());
    } catch (e) {
      emit(AddPostState.failure(e.toString()));
    }
  }
}
