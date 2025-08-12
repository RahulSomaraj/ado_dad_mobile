part of 'add_post_bloc.dart';

@freezed
class AddPostEvent with _$AddPostEvent {
  const factory AddPostEvent.started() = _Started;
  const factory AddPostEvent.postAd({
    required String category,
    required Map<String, dynamic> data,
  }) = _PostAd;
}
