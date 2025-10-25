import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
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
        title: Text('Showrooms', style: AppTextstyle.appbarText),
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchShowroomUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _showroomUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No showroom users found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchShowroomUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to showroom user's ads list
          context.push('/showroom-user-ads', extra: user.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                backgroundImage: user.profilePic != null
                    ? NetworkImage(user.profilePic!)
                    : null,
                child: user.profilePic == null
                    ? Icon(
                        Icons.business,
                        size: 30,
                        color: AppColors.primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextstyle.sectionTitleTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTextstyle.categoryLabelTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.phoneNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phoneNumber!,
                        style: AppTextstyle.categoryLabelTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
