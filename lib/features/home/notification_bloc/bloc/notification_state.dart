part of 'notification_bloc.dart';

@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState.initial() = _Initial;
  const factory NotificationState.loading() = _Loading;
  const factory NotificationState.loadingMore(
    List<NotificationModel> items,
    int page,
    int totalPages,
    bool hasNext,
    bool hasPrev,
  ) = _LoadingMore;
  const factory NotificationState.loaded(
    List<NotificationModel> items,
    int page,
    int totalPages,
    bool hasNext,
    bool hasPrev,
  ) = _Loaded;
  const factory NotificationState.error(String message) = _Error;
}
