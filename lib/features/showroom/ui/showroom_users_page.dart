import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/models/showroom_user_model.dart';
import 'package:ado_dad_user/repositories/showroom_repo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchShowroomUsers();
  }

  Future<void> _fetchShowroomUsers() async {
    try {
      print('🚀 Starting to fetch showroom users...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await _showroomRepo.fetchShowroomUsers();
      print('✅ Successfully fetched ${users.length} showroom users');

      setState(() {
        _showroomUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error in _fetchShowroomUsers: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ Exception message: ${e.toString()}');
      }

      setState(() {
        _error = e.toString();
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
          ? const Center(child: CircularProgressIndicator())
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
                          ErrorMessageUtil.getUserFriendlyMessage(_error!),
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
                          onPressed: _fetchShowroomUsers,
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
                      onRefresh: _fetchShowroomUsers,
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
                  image: user.profilePic != null
                      ? DecorationImage(
                          image: NetworkImage(user.profilePic!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profilePic == null
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
                        user.phoneNumber!,
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
