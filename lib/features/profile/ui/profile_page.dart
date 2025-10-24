import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/password_validator.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart' as login_bloc;
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart'
    as profile_bloc;
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool _seededOnce = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  Uint8List? _pickedImageBytes; // local preview
  String? _currentProfilePicUrl; // from API or after upload
  bool _isSaving = false;

  // Change password dialog controllers
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileEvent.fetchProfile());

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (res != null && res.files.single.bytes != null) {
          setState(() => _pickedImageBytes = res.files.single.bytes);
        }
      } else {
        final picker = ImagePicker();
        final XFile? file = await picker.pickImage(
          source:
              ImageSource.gallery, // or show a bottom sheet for camera/gallery
          imageQuality: 88,
          maxWidth: 1200,
        );
        if (file != null) {
          final bytes = await file.readAsBytes();
          setState(() => _pickedImageBytes = bytes);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  // Future<void> saveProfile() async {
  //   try {
  //     setState(() => _isSaving = true);

  //     final userId = await SharedPrefs().getUserId();
  //     if (userId == null || userId.isEmpty) {
  //       throw 'User ID is missing';
  //     }

  //     // Validate phone number format before sending request
  //     final phoneNumber = phoneController.text.trim();
  //     if (phoneNumber.isNotEmpty &&
  //         !RegExp(r"^[0-9]{10}$").hasMatch(phoneNumber)) {
  //       throw 'Please enter a valid 10-digit phone number';
  //     }

  //     // Validate email format
  //     final email = emailController.text.trim();
  //     if (email.isNotEmpty &&
  //         !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
  //             .hasMatch(email)) {
  //       throw 'Please enter a valid email address';
  //     }

  //     // 1) If user selected a new image, upload it first
  //     String? profilePicUrl = _currentProfilePicUrl;
  //     print("🔍 Current profile pic URL: $_currentProfilePicUrl");
  //     print("🔍 Picked image bytes: ${_pickedImageBytes != null}");

  //     if (_pickedImageBytes != null) {
  //       final repo = context.read<ProfileBloc>().repository;
  //       profilePicUrl = await repo.uploadImageToS3(_pickedImageBytes!);
  //       print("🔍 New uploaded profile pic URL: $profilePicUrl");
  //     }

  //     // Only omit profile picture if it's null or empty - allow all other values including 'default-profile-pic-url'
  //     if (profilePicUrl != null && profilePicUrl.isEmpty) {
  //       profilePicUrl = null; // Set to null so it's omitted from the request
  //       print("🔍 Empty profile picture URL, omitting from request");
  //     }

  //     print("🔍 Final profile pic URL to send: $profilePicUrl");

  //     // 2) Build updated model
  //     final updatedProfile = UserProfile(
  //       id: userId,
  //       name: nameController.text.trim(),
  //       email: email,
  //       phoneNumber: phoneNumber,
  //       type: "NU",
  //       profilePic: profilePicUrl, // can be null if user never set one
  //     );

  //     // 3) Dispatch update (this will also save to SharedPrefs via your bloc)
  //     context
  //         .read<ProfileBloc>()
  //         .add(ProfileEvent.updateProfile(updatedProfile));

  //     setState(() {
  //       isEditing = false;
  //       _pickedImageBytes = null; // clear local selection
  //       _currentProfilePicUrl = profilePicUrl; // reflect latest
  //     });
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Save failed: $e')),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isSaving = false);
  //   }
  // }

  Future<void> saveProfile() async {
    try {
      setState(() => _isSaving = true);
      final userId = await SharedPrefs().getUserId();
      if (userId == null || userId.isEmpty) throw 'User ID missing';

      String? profilePicUrl = _currentProfilePicUrl;

      // Upload new image if picked
      if (_pickedImageBytes != null) {
        final repo = context.read<ProfileBloc>().repository;
        profilePicUrl = await repo.uploadImageToS3(_pickedImageBytes!);
        print("📸 Uploaded new profile pic: $profilePicUrl");
        _currentProfilePicUrl = profilePicUrl;
      }

      // Build updated model
      final updatedProfile = UserProfile(
        id: userId,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        type: "NU",
        profilePic: profilePicUrl, // ✅ always include
      );

      // Dispatch update event
      context
          .read<ProfileBloc>()
          .add(ProfileEvent.updateProfile(updatedProfile));

      setState(() {
        isEditing = false;
        _pickedImageBytes = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showChangePasswordDialog() {
    // Reset form state
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _isNewPasswordVisible = false;
    _isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.whiteColor,
              title: Text(
                "Change Password",
                textAlign: TextAlign.center,
                style: AppTextstyle.title1,
              ),
              content: Form(
                key: _changePasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: "New Password",
                      isVisible: _isNewPasswordVisible,
                      onToggleVisibility: () {
                        setDialogState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                      validator: PasswordValidator.validatePassword,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      isVisible: _isConfirmPasswordVisible,
                      onToggleVisibility: () {
                        setDialogState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) =>
                          PasswordValidator.validateConfirmPassword(
                        value,
                        _newPasswordController.text,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(AppColors.whiteColor),
                          side: WidgetStatePropertyAll(
                              BorderSide(color: Colors.grey[400]!, width: 1.0)),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(AppColors.primaryColor),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                        ),
                        onPressed: () => _changePassword(),
                        child: const Text(
                          "OK",
                          style: TextStyle(color: AppColors.whiteColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (_changePasswordFormKey.currentState!.validate()) {
      try {
        context.read<ProfileBloc>().add(
              ProfileEvent.changePassword(_newPasswordController.text.trim()),
            );
        Navigator.pop(context); // Close the dialog
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: BlocConsumer<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is profile_bloc.Error) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                }

                if (state is profile_bloc.PasswordChanged) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password changed successfully!')),
                  );
                  // Navigate back to profile page
                  context.go('/profile');
                }

                // Seed controllers ONLY once per load (and not while editing)
                if (state is Loaded && !_seededOnce && !isEditing) {
                  nameController.text = state.profile.name;
                  emailController.text = state.profile.email;
                  phoneController.text = state.profile.phoneNumber;

                  print(
                      "🔍 Original profile pic from API: ${state.profile.profilePic}");

                  // Keep the original profile pic value as is
                  _currentProfilePicUrl = state.profile.profilePic;

                  print("🔍 Processed profile pic URL: $_currentProfilePicUrl");
                  _seededOnce = true;
                }
              },
              builder: (context, state) {
                if (state is profile_bloc.Loading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is Loaded || state is Saving) {
                  // if (state is Loaded) {
                  //   nameController.text = state.profile.name;
                  //   emailController.text = state.profile.email;
                  //   phoneController.text = state.profile.phoneNumber;
                  //   _currentProfilePicUrl = state.profile.profilePic;
                  // }

                  return Stack(
                    children: [
                      Container(height: 1100),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),

                      // Header
                      Positioned(
                        top: 50,
                        left: 16,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(context),
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              iconSize: 28,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile card
                      Positioned(
                        top: 120,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () {
                                    if (isEditing) {
                                      saveProfile();
                                    } else {
                                      setState(() => isEditing = true);
                                    }
                                  },
                                  child: isEditing
                                      ? Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/profile-edit-icon.png',
                                        ),
                                ),
                              ),
                              buildLabel("Full Name"),
                              buildTextField(nameController, isEditing),
                              buildLabel("Email"),
                              buildTextField(emailController, isEditing),
                              buildLabel("Phone Number"),
                              buildTextField(phoneController, isEditing),
                            ],
                          ),
                        ),
                      ),

                      // Avatar (supports: existing URL, just-picked bytes, or empty)
                      Positioned(
                        top: 75,
                        left: MediaQuery.of(context).size.width / 2 - 50,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.greyColor,
                              backgroundImage: _pickedImageBytes != null
                                  ? MemoryImage(_pickedImageBytes!)
                                  : (_currentProfilePicUrl != null &&
                                          _currentProfilePicUrl!.isNotEmpty &&
                                          _currentProfilePicUrl !=
                                              'default-profile-pic-url')
                                      ? NetworkImage(_currentProfilePicUrl!)
                                          as ImageProvider
                                      : null,
                              child: (_pickedImageBytes == null &&
                                      (_currentProfilePicUrl == null ||
                                          _currentProfilePicUrl!.isEmpty ||
                                          _currentProfilePicUrl ==
                                              'default-profile-pic-url'))
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                            ),
                            if (isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(Icons.edit, size: 18),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Menu list
                      Positioned(
                        top: 430,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            buildMenuItem(
                                'assets/images/wishlist-profile-icon.png',
                                "Wishlist",
                                onTap: () => context.push('/wishlist')),
                            buildMenuItem(
                                'assets/images/add-profile-icon.png', "My Ads",
                                onTap: () => context.push('/my-ads')),
                            buildMenuItem(
                                'assets/images/help-profile-icon.png', "Help"),
                            buildMenuItem('assets/images/profile-edit-icon.png',
                                "Change Password",
                                onTap: () => _showChangePasswordDialog()),
                            buildMenuItem(
                              'assets/images/logout-profile-icon.png',
                              "Logout",
                              isLogout: true,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    backgroundColor: AppColors.whiteColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 10),
                                    title: Text(
                                      "Logout",
                                      textAlign: TextAlign.center,
                                      style: AppTextstyle.title1,
                                    ),
                                    content: Text(
                                      "Are you sure you want to logout?",
                                      textAlign: TextAlign.center,
                                      style: AppTextstyle.sectionTitleTextStyle,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actions: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                                style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                            AppColors
                                                                .whiteColor),
                                                    side:
                                                        WidgetStatePropertyAll(
                                                            BorderSide(
                                                                color:
                                                                    Colors.red,
                                                                width: 1.0)),
                                                    shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)))),
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextButton(
                                                style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                            AppColors.redColor),
                                                    shape: WidgetStatePropertyAll(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)))),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text(
                                                  "Logout",
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.whiteColor),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  context.read<login_bloc.LoginBloc>().add(
                                      const login_bloc.LoginEvent.logout());
                                  context.go('/');
                                }
                              },
                            ),
                            // const SizedBox(
                            //     height: 100), // Add space for bottom nav
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (state is Error) {
                  return Center(child: Text("Error: ${state.message}"));
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Simple full-screen saving overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const BottomNavBar(),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, bool isEditable) {
    // Check if this is the phone number field
    final isPhoneField = controller == phoneController;

    return TextFormField(
      controller: controller,
      enabled: isEditable,
      style: TextStyle(fontWeight: FontWeight.bold),
      keyboardType: isPhoneField ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhoneField
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget buildMenuItem(String image, String title,
      {bool isLogout = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isLogout ? Colors.red[50] : Colors.grey[200],
              ),
              child: Center(
                child: Image.asset(
                  image,
                  color: isLogout ? AppColors.redColor : AppColors.primaryColor,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLogout ? Colors.red : Colors.black,
              ),
            ),
            trailing:
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const double _barHeight = 60; // a bit taller to fit big icon
  static const double _vPad = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _barHeight,
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: _vPad),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home'),
            _navItem(context, 'assets/images/search-icon.png',
                '/search?from=/profile'),
            _navItem(context, 'assets/images/seller-icon.png', '/seller',
                iconSize: 36),
            _navItem(context, 'assets/images/chat-icon.png',
                '/chat-rooms?from=profile'),
            _navItem(context, 'assets/images/profile-icon.png', '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String image,
    String? route, {
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: () {
        if (route != null && route.contains('/chat-rooms')) {
          context.go(route);
        } else if (route != null) {
          context.push(route);
        }
      },
      child: Center(
        // Fix the rendered size exactly
        child: SizedBox.square(
          dimension: iconSize,
          child: Image.asset(
            image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
