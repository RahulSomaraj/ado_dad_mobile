import 'package:ado_dad_user/models/notification_model.dart';
import 'package:ado_dad_user/repositories/notification_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_event.dart';
part 'notification_state.dart';
part 'notification_bloc.freezed.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository notificationRepository})
      : _repository = notificationRepository,
        super(const NotificationState.initial()) {
    on<NotificationEvent>(_onEvent);
  }

  final NotificationRepository _repository;
  static const int _pageSize = 10;

  Future<void> _onEvent(
    NotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await event.map(
      started: (_) async => add(const NotificationEvent.loadNotifications()),
      loadNotifications: (_) async => _loadFirstPage(emit),
      loadMoreNotifications: (_) async => _loadNextPage(emit),
    );
  }

  Future<void> _loadFirstPage(Emitter<NotificationState> emit) async {
    emit(const NotificationState.loading());
    try {
      final response = await _repository.getNotifications(
        page: 1,
        limit: _pageSize,
      );
      emit(NotificationState.loaded(
        response.data,
        response.page,
        response.totalPages,
        response.hasNext,
        response.hasPrev,
      ));
    } catch (e) {
      emit(NotificationState.error(
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString(),
      ));
    }
  }

  Future<void> _loadNextPage(Emitter<NotificationState> emit) async {
    final current = state;
    List<NotificationModel> items = [];
    int page = 1;
    int totalPages = 0;
    bool hasNext = false;
    bool hasPrev = false;

    current.whenOrNull(
      loaded: (i, p, tp, hn, hp) {
        items = List.from(i);
        page = p;
        totalPages = tp;
        hasNext = hn;
        hasPrev = hp;
      },
      loadingMore: (i, p, tp, hn, hp) {
        items = List.from(i);
        page = p;
        totalPages = tp;
        hasNext = hn;
        hasPrev = hp;
      },
    );

    if (items.isEmpty || !hasNext) return;

    emit(NotificationState.loadingMore(
      items,
      page,
      totalPages,
      hasNext,
      hasPrev,
    ));

    try {
      final nextPage = page + 1;
      final response = await _repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );
      final newItems = [...items, ...response.data];
      emit(NotificationState.loaded(
        newItems,
        response.page,
        response.totalPages,
        response.hasNext,
        response.hasPrev,
      ));
    } catch (e) {
      // Restore loaded state so list remains visible; UI can show snackbar for error
      emit(NotificationState.loaded(
        items,
        page,
        totalPages,
        hasNext,
        hasPrev,
      ));
    }
  }
}
