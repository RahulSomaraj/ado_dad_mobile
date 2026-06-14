import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/notification_badge_service.dart';
import 'package:ado_dad_user/features/home/notification_bloc/bloc/notification_bloc.dart';
import 'package:ado_dad_user/models/notification_model.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Clear notification badge only when user actually opens this page
    NotificationBadgeService.markAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationBloc>().add(
              const NotificationEvent.loadNotifications(),
            );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bloc = context.read<NotificationBloc>();
    final state = bloc.state;
    state.maybeWhen(
      loaded: (_, __, ___, hasNext, ____) {
        if (hasNext &&
            _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200) {
          bloc.add(const NotificationEvent.loadMoreNotifications());
        }
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 28,
              largeTablet: 32,
              desktop: 36,
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: AppTextstyle.title1.copyWith(
            color: Colors.white,
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 18,
              tablet: 22,
              largeTablet: 24,
              desktop: 26,
            ),
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final items = state.maybeWhen(
                loaded: (items, _, __, ___, ____) => items,
                loadingMore: (items, _, __, ___, ____) => items,
                orElse: () => const <NotificationModel>[],
              );
              if (items.isEmpty) return const SizedBox.shrink();
              return ValueListenableBuilder<Set<String>>(
                valueListenable:
                    NotificationBadgeService.readNotificationIds,
                builder: (context, readIds, _) {
                  final hasUnread = items.any(
                    (n) => !NotificationBadgeService.isNotificationRead(n.id),
                  );
                  if (!hasUnread) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () =>
                        NotificationBadgeService.markAllNotificationsAsRead(
                      items.map((n) => n.id),
                    ),
                    icon: const Icon(Icons.done_all,
                        size: 18, color: Colors.white),
                    label: Text(
                      'Mark all read',
                      style: AppTextstyle.changeCategoryButtonTextStyle
                          .copyWith(color: Colors.white, fontSize: 12.5),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SkeletonList(),
            loading: () => const SkeletonList(),
            loadingMore: (items, _, __, ___, ____) => _notificationList(
              context,
              items: items,
              isLoadingMore: true,
            ),
            loaded: (items, _, __, hasNext, ___) => _notificationList(
              context,
              items: items,
              hasNext: hasNext,
            ),
            error: (message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.greyColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<NotificationBloc>().add(
                            const NotificationEvent.loadNotifications(),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationList(
    BuildContext context, {
    required List<NotificationModel> items,
    bool isLoadingMore = false,
    bool hasNext = false,
  }) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: NotificationBadgeService.dismissedNotificationIds,
      builder: (context, dismissedIds, _) {
        final visible = items
            .where((n) => !NotificationBadgeService.isNotificationDismissed(n.id))
            .toList();

        if (visible.isEmpty) return const _EmptyState();

        return ValueListenableBuilder<Set<String>>(
          valueListenable: NotificationBadgeService.readNotificationIds,
          builder: (context, readIds, __) {
            // Build a flat row list: date-section headers interleaved with
            // items. Recomputed on read-state changes so "N new" counts stay
            // in sync with "Mark all read".
            final entries = _buildEntries(visible);
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: entries.length + (isLoadingMore || hasNext ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == entries.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: isLoadingMore
                          ? const SizedBox(
                              height: 32,
                              width: 32,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  );
                }

                final entry = entries[i];
                if (entry.isHeader) {
                  return _SectionHeader(
                    label: entry.headerLabel!,
                    newCount: entry.headerNewCount,
                  );
                }

                final n = entry.notification!;
                final isRead =
                    NotificationBadgeService.isNotificationRead(n.id);
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: _dismissBackground(),
                  onDismissed: (_) =>
                      NotificationBadgeService.dismissNotification(n.id),
                  child: _NotificationTile(
                    notification: n,
                    isRead: isRead,
                    onTap: () =>
                        NotificationBadgeService.markNotificationAsRead(n.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _dismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.only(right: 22),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: AppColors.redColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 20),
          SizedBox(width: 6),
          Text('Dismiss',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Groups items into Today / Yesterday / Earlier sections, preserving the
  /// incoming (newest-first) order, and returns a flat list of rows.
  List<_ListEntry> _buildEntries(List<NotificationModel> items) {
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    for (final n in items) {
      final d = n.createdAt.toLocal();
      if (!d.isBefore(startOfToday)) {
        today.add(n);
      } else if (!d.isBefore(startOfYesterday)) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    final entries = <_ListEntry>[];
    void addSection(String label, List<NotificationModel> group) {
      if (group.isEmpty) return;
      final newCount = group
          .where((n) => !NotificationBadgeService.isNotificationRead(n.id))
          .length;
      entries.add(_ListEntry.header(label, newCount));
      for (final n in group) {
        entries.add(_ListEntry.item(n));
      }
    }

    addSection('Today', today);
    addSection('Yesterday', yesterday);
    addSection('Earlier', earlier);
    return entries;
  }
}

/// One row in the flat list — either a date header or a notification.
class _ListEntry {
  final String? headerLabel;
  final int headerNewCount;
  final NotificationModel? notification;

  _ListEntry.header(this.headerLabel, this.headerNewCount) : notification = null;
  _ListEntry.item(this.notification)
      : headerLabel = null,
        headerNewCount = 0;

  bool get isHeader => headerLabel != null;
}

/// Visual category derived from a notification's priority / type.
class _NotifKind {
  final IconData icon;
  final Color color;
  final Color softColor;
  final String label;
  const _NotifKind(this.icon, this.color, this.softColor, this.label);

  static _NotifKind of(NotificationModel n) {
    final priority = n.data.priority.toUpperCase();
    final type =
        (n.data.data?.type ?? n.data.targetType).toUpperCase();

    if (priority == 'HIGH' || priority == 'URGENT' || type.contains('ALERT')) {
      return _NotifKind(Icons.error_outline, AppColors.redColor,
          const Color(0xFFFDECEC), 'Alert');
    }
    if (type.contains('ORDER') ||
        type.contains('DELIVER') ||
        type.contains('SUCCESS') ||
        type.contains('PAYMENT')) {
      return const _NotifKind(Icons.check_circle_outline, Color(0xFF28A745),
          Color(0xFFE7F6EB), 'Update');
    }
    if (type.contains('PROMO') ||
        type.contains('OFFER') ||
        type.contains('DEAL') ||
        type.contains('DISCOUNT')) {
      return _NotifKind(Icons.local_offer_outlined, AppColors.primaryColor,
          const Color(0xFFECEBFD), 'Promo');
    }
    // default / informational
    return _NotifKind(Icons.notifications_none, const Color(0xFFF0A93B),
        const Color(0xFFFCF1E1), 'Info');
  }
}

/// Date-section header (Today / Yesterday / Earlier).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.newCount});

  final String label;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextstyle.categoryLabelTextStyle.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.dividerColor)),
          if (newCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$newCount new',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state shown when there are no notifications.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none,
                  size: 40, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 18),
            Text(
              "You're all caught up",
              style: AppTextstyle.sectionTitleTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'New notifications about offers, orders and price drops will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single notification card. Type icon, title, body, tag + relative time,
/// optional media preview, and an unread dot/accent for unread items.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final NotificationModel notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMedia = notification.hasMedia;
    final media = notification.data.media;
    final mediaType = media?.type.toUpperCase() ?? '';
    final kind = _NotifKind.of(notification);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? AppColors.dividerColor
                : AppColors.primaryColor.withValues(alpha: 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kind.softColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(kind.icon, color: kind.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextstyle.sectionTitleTextStyle.copyWith(
                            fontSize: 14.5,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: AppColors.blackColor1,
                        fontSize: 13,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kind.softColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kind.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: kind.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.greyColor,
                        ),
                      ),
                    ],
                  ),
                  if (hasMedia && media != null && media.url.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (mediaType == 'IMAGE')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          media.url,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.dividerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.greyColor),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.dividerColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const CircularProgressIndicator(),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              mediaType == 'VIDEO'
                                  ? Icons.videocam_outlined
                                  : Icons.audiotrack_outlined,
                              size: 26,
                              color: AppColors.greyColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                mediaType == 'VIDEO' ? 'Video' : 'Audio',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.blackColor1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Human-friendly relative time: "Just now", "2h ago", "Yesterday, 4:12 PM",
  /// or an abbreviated date for older items.
  String _relativeTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 &&
        local.day == now.day &&
        local.month == now.month) {
      return '${diff.inHours}h ago';
    }

    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    if (!local.isBefore(startOfYesterday) && local.isBefore(startOfToday)) {
      return 'Yesterday, ${_formatTime(local)}';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[local.month - 1];
    return local.year == now.year
        ? '$m ${local.day}'
        : '$m ${local.day}, ${local.year}';
  }

  String _formatTime(DateTime dt) {
    final h24 = dt.hour;
    final period = h24 >= 12 ? 'PM' : 'AM';
    var h = h24 % 12;
    if (h == 0) h = 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$h:$mm $period';
  }
}
