import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
      postAd: (e) => _handlePostAd(e, emit),
    );
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
