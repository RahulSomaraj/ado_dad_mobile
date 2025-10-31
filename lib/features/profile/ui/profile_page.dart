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
import 'package:ado_dad_user/common/get_responsive_size.dart';
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

      // Get current profile state to compare changes
      final currentState = context.read<ProfileBloc>().state;
      if (currentState is! Loaded) {
        throw 'Profile not loaded. Please refresh and try again.';
      }

      final originalProfile = currentState.profile;
      final updatedName = nameController.text.trim();
      final updatedEmail = emailController.text.trim();
      final updatedPhoneNumber = phoneController.text.trim();

      // Check what fields have actually changed
      final nameChanged = updatedName != originalProfile.name;
      final emailChanged = updatedEmail != originalProfile.email;
      final phoneChanged = updatedPhoneNumber != originalProfile.phoneNumber;
      final profilePicChanged = _pickedImageBytes != null;

      // If nothing changed, just exit editing mode
      if (!nameChanged &&
          !emailChanged &&
          !phoneChanged &&
          !profilePicChanged) {
        setState(() {
          isEditing = false;
          _pickedImageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes detected.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String? profilePicUrl = _currentProfilePicUrl;

      // Upload new image if picked
      if (_pickedImageBytes != null) {
        try {
          final repo = context.read<ProfileBloc>().repository;
          profilePicUrl = await repo.uploadImageToS3(_pickedImageBytes!);
          print("📸 Uploaded new profile pic: $profilePicUrl");
          _currentProfilePicUrl = profilePicUrl;
        } catch (uploadError) {
          print("❌ Profile picture upload failed: $uploadError");
          throw 'Failed to upload profile picture. Please try again.';
        }
      }

      // Validate email format if provided and changed
      if (emailChanged &&
          updatedEmail.isNotEmpty &&
          !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
              .hasMatch(updatedEmail)) {
        throw 'Please enter a valid email address';
      }

      // Validate phone number format if provided and changed
      if (phoneChanged &&
          updatedPhoneNumber.isNotEmpty &&
          !RegExp(r"^[0-9]{10}$").hasMatch(updatedPhoneNumber)) {
        throw 'Please enter a valid 10-digit phone number';
      }

      // Build updated model with only changed fields
      final updatedProfile = UserProfile(
        id: userId,
        name: nameChanged ? updatedName : originalProfile.name,
        email: emailChanged ? updatedEmail : originalProfile.email,
        phoneNumber:
            phoneChanged ? updatedPhoneNumber : originalProfile.phoneNumber,
        type: "NU", // Keep type unchanged
        profilePic:
            profilePicChanged ? profilePicUrl : originalProfile.profilePic,
      );

      print("🔄 Changes detected:");
      print("  - Name: ${nameChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Email: ${emailChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Phone: ${phoneChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Profile Pic: ${profilePicChanged ? 'CHANGED' : 'unchanged'}");

      // Dispatch update event
      context
          .read<ProfileBloc>()
          .add(ProfileEvent.updateProfile(updatedProfile));

      setState(() {
        isEditing = false;
        _pickedImageBytes = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Profile save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                      SizedBox(
                        height: MediaQuery.of(context).size.height +
                            GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 500,
                              tablet: 300,
                              largeTablet: 500,
                              desktop: 1000,
                            ),
                      ),
                      Container(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 250, // keep phone unchanged
                          tablet: 340,
                          largeTablet: 400,
                          desktop: 440,
                        ),
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
                              iconSize: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 28,
                                tablet: 36,
                                largeTablet: 40,
                                desktop: 42,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    GetResponsiveSize.getResponsiveFontSize(
                                  context,
                                  mobile: 20,
                                  tablet: 26,
                                  largeTablet: 30,
                                  desktop: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile card
                      Positioned(
                        top: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 120,
                          tablet: 150,
                          largeTablet: 180,
                          desktop: 200,
                        ),
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: EdgeInsets.all(
                            GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 16,
                              tablet: 20,
                              largeTablet: 24,
                              desktop: 26,
                            ),
                          ),
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
                                          padding: EdgeInsets.all(
                                            GetResponsiveSize.getResponsiveSize(
                                              context,
                                              mobile: 8,
                                              tablet: 12,
                                              largeTablet: 14,
                                              desktop: 14,
                                            ),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: GetResponsiveSize
                                                .getResponsiveSize(
                                              context,
                                              mobile: 20,
                                              tablet: 28,
                                              largeTablet: 32,
                                              desktop: 34,
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          width: GetResponsiveSize
                                              .getResponsiveSize(
                                            context,
                                            mobile: 24,
                                            tablet: 36,
                                            largeTablet: 42,
                                            desktop: 44,
                                          ),
                                          height: GetResponsiveSize
                                              .getResponsiveSize(
                                            context,
                                            mobile: 24,
                                            tablet: 36,
                                            largeTablet: 42,
                                            desktop: 44,
                                          ),
                                          child: Image.asset(
                                            'assets/images/profile-edit-icon.png',
                                            fit: BoxFit.contain,
                                          ),
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
                        top: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 75, // unchanged on phones
                          tablet: 70,
                          largeTablet: 80,
                          desktop: 85,
                        ),
                        left: MediaQuery.of(context).size.width / 2 -
                            GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 50,
                              tablet: 65,
                              largeTablet: 80,
                              desktop: 90,
                            ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 50,
                                tablet: 80,
                                largeTablet: 100,
                                desktop: 110,
                              ),
                              backgroundColor: AppColors.greyColor,
                              backgroundImage: _pickedImageBytes != null
                                  ? MemoryImage(_pickedImageBytes!)
                                  : (_currentProfilePicUrl != null &&
                                          _currentProfilePicUrl!.isNotEmpty &&
                                          _currentProfilePicUrl !=
                                              'default-profile-pic-url' &&
                                          _currentProfilePicUrl!
                                              .startsWith('http'))
                                      ? NetworkImage(_currentProfilePicUrl!)
                                          as ImageProvider
                                      : null,
                              child: (_pickedImageBytes == null &&
                                      (_currentProfilePicUrl == null ||
                                          _currentProfilePicUrl!.isEmpty ||
                                          _currentProfilePicUrl ==
                                              'default-profile-pic-url' ||
                                          !_currentProfilePicUrl!
                                              .startsWith('http')))
                                  ? Icon(Icons.person,
                                      size: GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 50,
                                        tablet: 80,
                                        largeTablet: 96,
                                        desktop: 110,
                                      ),
                                      color: Colors.white)
                                  : null,
                            ),
                            if (isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 6,
                                        tablet: 8,
                                        largeTablet: 10,
                                        desktop: 10,
                                      ),
                                    ),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 18,
                                        tablet: 26,
                                        largeTablet: 30,
                                        desktop: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Menu list
                      Positioned(
                        top: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 430,
                          tablet: 530,
                          largeTablet: 550,
                          desktop: 600,
                        ),
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
                            buildMenuItem(
                              'assets/images/close.png',
                              "Delete Account",
                              isLogout: true,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) {
                                    final TextEditingController _confirmCtl =
                                        TextEditingController();
                                    String? _errorText;
                                    return StatefulBuilder(
                                      builder: (ctx, setState) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        backgroundColor: AppColors.whiteColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                        titlePadding: const EdgeInsets.only(
                                            left: 24,
                                            top: 16,
                                            right: 8,
                                            bottom: 0),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Delete Account",
                                                textAlign: TextAlign.center,
                                                style: AppTextstyle.title1,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                            )
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              "This will permanently delete your account and data. Continue?",
                                              textAlign: TextAlign.center,
                                              style: AppTextstyle
                                                  .sectionTitleTextStyle,
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              "To confirm this, type 'DELETE'",
                                              textAlign: TextAlign.left,
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: _confirmCtl,
                                              decoration: InputDecoration(
                                                hintText: "DELETE",
                                                errorText: _errorText,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                              ),
                                              onChanged: (_) {
                                                if (_errorText != null) {
                                                  setState(
                                                      () => _errorText = null);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.center,
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
                                                            AppColors.redColor),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (_confirmCtl.text
                                                            .trim() !=
                                                        'DELETE') {
                                                      setState(() => _errorText =
                                                          'Please type DELETE');
                                                      return;
                                                    }
                                                    Navigator.pop(ctx, true);
                                                  },
                                                  child: const Text(
                                                    "Delete Account",
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .whiteColor),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                                if (confirm == true) {
                                  try {
                                    await context
                                        .read<profile_bloc.ProfileBloc>()
                                        .deleteAccount();
                                    context.read<login_bloc.LoginBloc>().add(
                                        const login_bloc.LoginEvent.logout());
                                    context.go('/');
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to delete account: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 100,
                                tablet: 120,
                                largeTablet: 160,
                                desktop: 180,
                              ),
                            ),
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
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 14,
            tablet: 22,
            largeTablet: 24,
            desktop: 24,
          ),
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
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 24,
          largeTablet: 26,
          desktop: 26,
        ),
      ),
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
          padding: EdgeInsets.symmetric(
            vertical: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 10,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
          child: ListTile(
            leading: Builder(builder: (context) {
              final double boxSize = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 44,
                tablet: 70,
                largeTablet: 75,
                desktop: 80,
              );
              return SizedBox(
                width: boxSize,
                height: boxSize,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isLogout ? Colors.red[50] : Colors.grey[200],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 24,
                        tablet: 38,
                        largeTablet: 42,
                        desktop: 46,
                      ),
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 24,
                        tablet: 38,
                        largeTablet: 42,
                        desktop: 46,
                      ),
                      child: Image.asset(
                        image,
                        color: isLogout
                            ? AppColors.redColor
                            : AppColors.primaryColor,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLogout ? Colors.red : Colors.black,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 24,
                  largeTablet: 26,
                  desktop: 26,
                ),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 18,
                tablet: 24,
                largeTablet: 26,
                desktop: 28,
              ),
              color: Colors.grey,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const double _vPad = 10;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 0,
      tablet: 24,
      largeTablet: 32,
      desktop: 40,
    );
    final double barWidth = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 300,
      tablet: screenWidth - (horizontalMargin * 2),
      largeTablet: screenWidth - (horizontalMargin * 2),
      desktop: screenWidth - (horizontalMargin * 2),
    );
    final double barHeight = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 60,
      tablet: 80,
      largeTablet: 85,
      desktop: 90,
    );
    final double baseIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 20,
      tablet: 35,
      largeTablet: 40,
      desktop: 40,
    );
    final double addIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 36,
      tablet: 50,
      largeTablet: 50,
      desktop: 54,
    );
    return Container(
      height: barHeight,
      width: barWidth,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: _vPad,
            tablet: 15,
            largeTablet: 17,
            desktop: 17,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/search-icon.png',
                '/search?from=/profile',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/seller-icon.png', '/seller',
                iconSize: addIconSize),
            _navItem(context, 'assets/images/chat-icon.png',
                '/chat-rooms?from=profile',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/profile-icon.png', '/profile',
                iconSize: baseIconSize),
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
