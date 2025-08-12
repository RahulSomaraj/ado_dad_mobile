part of 'add_post_bloc.dart';

@freezed
class AddPostState with _$AddPostState {
  const factory AddPostState.initial() = _Initial;
  const factory AddPostState.loading() = _Loading;
  const factory AddPostState.success() = _Success;
  const factory AddPostState.failure(String message) = _Failure;
}
