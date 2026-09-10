import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/models/showroom_user_model.dart';
import 'package:ado_dad_user/repositories/showroom_repo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A profile picture is only usable as a [NetworkImage] when it is a
/// non-empty http(s) URL; anything else falls back to a placeholder icon.
bool _isValidImageUrl(String? url) {
  final value = url?.trim() ?? '';
  return value.isNotEmpty && value.startsWith('http');
}

class ShowroomUsersPage extends StatefulWidget {
  const ShowroomUsersPage({super.key});

  @override
  State<ShowroomUsersPage> createState() => _ShowroomUsersPageState();
}

class _ShowroomUsersPageState extends State<ShowroomUsersPage> {
  final ShowroomRepo _showroomRepo = ShowroomRepo();
  List<ShowroomUser> _showroomUsers = [];
  bool _isLoading = true;
  String? _error;
  bool _didDependencyRefetch = false;

  String _maskPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    final visible = digitsOnly.length >= 3
        ? digitsOnly.substring(digitsOnly.length - 3)
        : digitsOnly;
    final maskedCount = (digitsOnly.length - visible.length).clamp(0, 1000);
    return '${'*' * maskedCount}$visible';
  }

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check auth when returning from login (e.g., after successful login redirect)
    // This ensures data is fetched if user logged in and was redirected back
    if (_didDependencyRefetch) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didDependencyRefetch) return;
      if (!_isLoading && _showroomUsers.isEmpty && _error == null) {
        _didDependencyRefetch = true;
        _checkAuthAndFetch();
      }
    });
  }

  Future<void> _checkAuthAndFetch() async {
    // Check authentication status
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!mounted) return;

    // Fetch showroom users - use public endpoint if not authenticated, authenticated endpoint if authenticated
    _fetchShowroomUsers(isAuthenticated: isAuthenticated);
  }

  Future<void> _fetchShowroomUsers({required bool isAuthenticated}) async {
    try {
      debugPrint(
          '🚀 Starting to fetch showroom users (authenticated: $isAuthenticated)...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use authenticated endpoint if user is logged in, public endpoint if not
      final users = isAuthenticated
          ? await _showroomRepo.fetchShowroomUsers()
          : await _showroomRepo.fetchPublicShowroomUsers();

      debugPrint('✅ Successfully fetched ${users.length} showroom users');

      if (!mounted) return;
      setState(() {
        _showroomUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error in _fetchShowroomUsers: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      // Extract user-friendly error message
      String errorMessage =
          "Unable to load showroom users. Please try again later.";

      if (e is Exception) {
        final exceptionMessage = e.toString();
        debugPrint('❌ Exception message: $exceptionMessage');

        // Extract the actual error message from Exception: "message"
        // Remove "Exception: " prefix if present
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.split('Exception: ').last.trim();
        } else if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring(11).trim();
        } else {
          // If it's just the message without "Exception:" prefix, use it directly
          errorMessage = exceptionMessage.trim();
        }

        // Ensure we have a meaningful message
        if (errorMessage.isEmpty || errorMessage == 'null') {
          errorMessage =
              "Unable to load showroom users. Please try again later.";
        }
      } else {
        // For non-Exception errors, use a generic message
        errorMessage = "An unexpected error occurred. Please try again later.";
      }

      if (!mounted) return;
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 30,
              largeTablet: 32,
              desktop: 36,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Showrooms',
          style: AppTextstyle.appbarText.copyWith(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: AppTextstyle.appbarText.fontSize ?? 20,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
        ),
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const SkeletonList()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      GetResponsiveSize.getResponsivePadding(
                        context,
                        mobile: 16,
                        tablet: 24,
                        largeTablet: 32,
                        desktop: 40,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: $_error',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 18,
                              largeTablet: 22,
                              desktop: 26,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final isAuthenticated =
                                await AuthGuard.isAuthenticated();
                            _fetchShowroomUsers(
                                isAuthenticated: isAuthenticated);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 16,
                                tablet: 24,
                                largeTablet: 32,
                                desktop: 40,
                              ),
                              vertical: GetResponsiveSize.getResponsivePadding(
                                context,
                                mobile: 12,
                                tablet: 16,
                                largeTablet: 20,
                                desktop: 24,
                              ),
                            ),
                            minimumSize: Size(
                              0,
                              GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 40,
                                tablet: 55,
                                largeTablet: 65,
                                desktop: 75,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GetResponsiveSize.getResponsiveBorderRadius(
                                  context,
                                  mobile: 8,
                                  tablet: 10,
                                  largeTablet: 12,
                                  desktop: 14,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _showroomUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No showroom users found',
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 24,
                            desktop: 28,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final isAuthenticated =
                            await AuthGuard.isAuthenticated();
                        await _fetchShowroomUsers(
                            isAuthenticated: isAuthenticated);
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(
                          GetResponsiveSize.getResponsivePadding(
                            context,
                            mobile: 16,
                            tablet: 24,
                            largeTablet: 32,
                            desktop: 40,
                          ),
                        ),
                        itemCount: _showroomUsers.length,
                        itemBuilder: (context, index) {
                          final user = _showroomUsers[index];
                          return _buildShowroomUserCard(user);
                        },
                      ),
                    ),
    );
  }

  Widget _buildShowroomUserCard(ShowroomUser user) {
    return Card(
      margin: EdgeInsets.only(
        bottom: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 12,
          tablet: 18,
          largeTablet: 24,
          desktop: 30,
        ),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 20,
            desktop: 24,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to showroom user's ads list
          context.push('/showroom-user-ads', extra: user.id);
        },
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 20,
            desktop: 24,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 22,
              largeTablet: 28,
              desktop: 34,
            ),
          ),
          child: Row(
            children: [
              // Profile Image
              Container(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 60,
                  tablet: 90,
                  largeTablet: 110,
                  desktop: 130,
                ),
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 60,
                  tablet: 90,
                  largeTablet: 110,
                  desktop: 130,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withOpacity(0.1),
                  image: _isValidImageUrl(user.profilePic)
                      ? DecorationImage(
                          image: NetworkImage(user.profilePic!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !_isValidImageUrl(user.profilePic)
                    ? Icon(
                        Icons.business,
                        size: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 30,
                          tablet: 45,
                          largeTablet: 55,
                          desktop: 65,
                        ),
                        color: AppColors.primaryColor,
                      )
                    : null,
              ),
              SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 24,
                  largeTablet: 30,
                  desktop: 36,
                ),
              ),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextstyle.sectionTitleTextStyle.copyWith(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 22,
                          largeTablet: 28,
                          desktop: 34,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 4,
                        tablet: 8,
                        largeTablet: 12,
                        desktop: 16,
                      ),
                    ),
                    Text(
                      user.email,
                      style: AppTextstyle.categoryLabelTextStyle.copyWith(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.phoneNumber != null) ...[
                      SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 2,
                          tablet: 6,
                          largeTablet: 10,
                          desktop: 14,
                        ),
                      ),
                      Text(
                        _maskPhoneNumber(user.phoneNumber!),
                        style: AppTextstyle.categoryLabelTextStyle.copyWith(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 18,
                            largeTablet: 22,
                            desktop: 26,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 22,
                  largeTablet: 28,
                  desktop: 34,
                ),
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
