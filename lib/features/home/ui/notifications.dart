import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/app_colors.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
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
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No notifications yet.',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<Set<String>>(
      valueListenable: NotificationBadgeService.readNotificationIds,
      builder: (context, readIds, _) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: items.length + (isLoadingMore || hasNext ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: isLoadingMore
                      ? const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              );
            }
            final n = items[i];
            final isRead = NotificationBadgeService.isNotificationRead(n.id);
            return _NotificationTile(
              notification: n,
              isRead: isRead,
              onTap: () => NotificationBadgeService.markNotificationAsRead(n.id),
            );
          },
        );
      },
    );
  }
}

/// Single simple tile for every notification. Two shades: unread vs read. Shows media when present.
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: AppTextstyle.sectionTitleTextStyle.copyWith(
                fontSize: 15,
              ),
            ),
            if (notification.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notification.body,
                style: TextStyle(
                  color: AppColors.greyColor,
                  fontSize: 14,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hasMedia && media != null && media.url.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (mediaType == 'IMAGE')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    media.url,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey.shade600),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const CircularProgressIndicator(),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mediaType == 'VIDEO'
                            ? Icons.videocam_outlined
                            : Icons.audiotrack_outlined,
                        size: 28,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mediaType == 'VIDEO' ? 'Video' : 'Audio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
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
    );
  }
}
