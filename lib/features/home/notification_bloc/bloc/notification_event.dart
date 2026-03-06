part of 'notification_bloc.dart';

@freezed
class NotificationEvent with _$NotificationEvent {
  const factory NotificationEvent.started() = _Started;
  /// Load first page (or refresh).
  const factory NotificationEvent.loadNotifications() = _LoadNotifications;
  /// Load next page (pagination).
  const factory NotificationEvent.loadMoreNotifications() =
      _LoadMoreNotifications;
}