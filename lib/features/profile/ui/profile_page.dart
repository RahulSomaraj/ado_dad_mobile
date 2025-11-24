import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/password_validator.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart' as login_bloc;
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart'
    as profile_bloc;
import 'package:ado_dad_user/features/profile/bloc/profile_bloc.dart';
import 'package:ado_dad_user/models/profile_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_header.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_card.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_avatar.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_menu_item.dart';

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
    // Reset the seeded flag to allow fresh data loading when page opens
    _seededOnce = false;

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Fetch profile data using addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always fetch fresh data when the page opens, regardless of current bloc state
      // This fixes the issue where the bloc might be stuck in Loading or Error state
      // from a previous session
      context.read<ProfileBloc>().add(const ProfileEvent.fetchProfile());
    });
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
        SnackBar(
            content: Text(ErrorMessageUtil.getUserFriendlyMessage(
                'Failed to pick image: $e'))),
      );
    }
  }

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

    if (!kIsWeb && Platform.isIOS) {
      // iOS Cupertino Dialog
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return CupertinoAlertDialog(
                title: Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 22,
                      largeTablet: 26,
                      desktop: 30,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Container(
                  padding: EdgeInsets.only(
                    top: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 20,
                      largeTablet: 24,
                      desktop: 28,
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIOSPasswordField(
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
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 12,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                          ),
                          _buildIOSPasswordField(
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
                      );
                    },
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: false,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      // Manual validation for iOS
                      final newPasswordError =
                          PasswordValidator.validatePassword(
                        _newPasswordController.text,
                      );
                      final confirmPasswordError =
                          PasswordValidator.validateConfirmPassword(
                        _confirmPasswordController.text,
                        _newPasswordController.text,
                      );

                      if (newPasswordError != null ||
                          confirmPasswordError != null) {
                        // Show error message
                        showCupertinoDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: Text('Validation Error'),
                            content: Text(
                              newPasswordError ??
                                  confirmPasswordError ??
                                  'Please check your input',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context); // Close the password dialog
                      // Call the change password logic directly for iOS
                      _performChangePassword();
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    // Android/Other Platforms Material Dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.whiteColor,
              insetPadding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 40,
                  largeTablet: 60,
                  desktop: 80,
                ),
              ),
              title: Text(
                "Change Password",
                textAlign: TextAlign.center,
                style: AppTextstyle.title1.copyWith(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: AppTextstyle.title1.fontSize ?? 20,
                    tablet: 24,
                    largeTablet: 28,
                    desktop: 34,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 24,
                  tablet: 32,
                  largeTablet: 40,
                  desktop: 48,
                ),
                vertical: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 20,
                  tablet: 24,
                  largeTablet: 28,
                  desktop: 32,
                ),
              ),
              content: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 300,
                  tablet: 400,
                  largeTablet: 500,
                  desktop: 600,
                ),
                child: Form(
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
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 40,
                          tablet: 60,
                          largeTablet: 75,
                          desktop: 85,
                        ),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(AppColors.whiteColor),
                            side: WidgetStatePropertyAll(BorderSide(
                                color: Colors.grey[400]!, width: 1.0)),
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                vertical:
                                    GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24,
                                ),
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey[600],
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
                      ),
                    ),
                    SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 12,
                        tablet: 18,
                        largeTablet: 24,
                        desktop: 30,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 40,
                          tablet: 60,
                          largeTablet: 75,
                          desktop: 85,
                        ),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(AppColors.primaryColor),
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                vertical:
                                    GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24,
                                ),
                              ),
                            ),
                          ),
                          onPressed: () => _changePassword(),
                          child: Text(
                            "OK",
                            style: TextStyle(
                              color: AppColors.whiteColor,
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
          SnackBar(
              content: Text(ErrorMessageUtil.getUserFriendlyMessage(
                  'Failed to change password: $e'))),
        );
      }
    }
  }

  Future<void> _performChangePassword() async {
    try {
      context.read<ProfileBloc>().add(
            ProfileEvent.changePassword(_newPasswordController.text.trim()),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // System already handled the pop
        // Handle system back button press
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Stack(
          children: [
            SingleChildScrollView(
              child: BlocConsumer<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is profile_bloc.Error) {
                    // Check if error is related to token expiration (silent logout)
                    final isTokenExpirationError = state.message
                            .toLowerCase()
                            .contains('session_expired_silent') ||
                        state.message.toLowerCase().contains('token expired') ||
                        state.message
                            .toLowerCase()
                            .contains('automatic logout');

                    // Don't show error UI for token expiration - logout is already in progress
                    if (isTokenExpirationError) {
                      print(
                          '🔇 Suppressing token expiration error in ProfilePage - logout in progress');
                      return; // Skip showing snackbar
                    }

                    // Check if error is related to "Delete My Data"
                    final isDeleteMyDataError =
                        state.message.toLowerCase().contains('delete') &&
                            state.message.toLowerCase().contains('data');

                    if (isDeleteMyDataError) {
                      // Navigate back to profile page and show error in red snackbar
                      context.go('/profile');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ErrorMessageUtil.getUserFriendlyMessage(
                              state.message)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      // For other errors, show normal snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                ErrorMessageUtil.getUserFriendlyMessage(
                                    state.message))),
                      );
                    }
                  }

                  if (state is profile_bloc.PasswordChanged) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully!')),
                    );
                    // Navigate back to profile page
                    context.go('/profile');
                  }

                  if (state is profile_bloc.DataDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Your data has been deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate back to profile page and refresh profile data
                    context.go('/profile');
                    // Trigger profile refresh to show updated data
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context.read<ProfileBloc>().add(
                              const ProfileEvent.fetchProfile(),
                            );
                      }
                    });
                  }

                  // Reset seeded flag when loading starts to ensure fresh data is seeded
                  if (state is profile_bloc.Loading) {
                    _seededOnce = false;
                  }

                  // Seed controllers when data is loaded (and not while editing)
                  if (state is Loaded && !_seededOnce && !isEditing) {
                    nameController.text = state.profile.name;
                    emailController.text = state.profile.email;
                    phoneController.text = state.profile.phoneNumber;

                    print(
                        "🔍 Original profile pic from API: ${state.profile.profilePic}");

                    // Keep the original profile pic value as is
                    _currentProfilePicUrl = state.profile.profilePic;

                    print(
                        "🔍 Processed profile pic URL: $_currentProfilePicUrl");
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

                  // Handle error state with retry option
                  if (state is profile_bloc.Error) {
                    // Check if error is related to "Delete My Data" - don't show error UI for this
                    final isDeleteMyDataError =
                        state.message.toLowerCase().contains('delete') &&
                            state.message.toLowerCase().contains('data');

                    // For delete my data errors, don't show error UI (already handled in listener with navigation)
                    if (isDeleteMyDataError) {
                      // Trigger a profile fetch to show the profile page content
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.read<ProfileBloc>().add(
                                const ProfileEvent.fetchProfile(),
                              );
                        }
                      });
                      return const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // For other errors, show error UI with retry
                    return SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Reset seeded flag and retry
                                _seededOnce = false;
                                context.read<ProfileBloc>().add(
                                      const ProfileEvent.fetchProfile(),
                                    );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        const ProfileHeader(),

                        // Profile card
                        ProfileCard(
                          nameController: nameController,
                          emailController: emailController,
                          phoneController: phoneController,
                          isEditing: isEditing,
                          onEditTap: () => setState(() => isEditing = true),
                          onSaveTap: saveProfile,
                        ),

                        // Avatar
                        ProfileAvatar(
                          pickedImageBytes: _pickedImageBytes,
                          currentProfilePicUrl: _currentProfilePicUrl,
                          isEditing: isEditing,
                          onPickImage: _pickImage,
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
                              ProfileMenuItem(
                                  image:
                                      'assets/images/wishlist-profile-icon.png',
                                  title: "Wishlist",
                                  onTap: () => context.push('/wishlist')),
                              ProfileMenuItem(
                                  image: 'assets/images/add-profile-icon.png',
                                  title: "My Ads",
                                  onTap: () => context.push('/my-ads')),
                              ProfileMenuItem(
                                  image: 'assets/images/help-profile-icon.png',
                                  title: "Help and Support",
                                  onTap: () => context.push('/help')),
                              ProfileMenuItem(
                                  image: 'assets/images/profile-edit-icon.png',
                                  title: "Change Password",
                                  onTap: () => _showChangePasswordDialog()),
                              ProfileMenuItem(
                                image: 'assets/images/logout-profile-icon.png',
                                title: "Logout",
                                isLogout: true,
                                onTap: () async {
                                  final bool? confirm;
                                  if (!kIsWeb && Platform.isIOS) {
                                    confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) =>
                                          CupertinoAlertDialog(
                                        title: Text(
                                          "Logout",
                                          style: TextStyle(
                                            fontSize: GetResponsiveSize
                                                .getResponsiveFontSize(
                                              context,
                                              mobile: 18,
                                              tablet: 22,
                                              largeTablet: 26,
                                              desktop: 30,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          "Are you sure you want to logout?",
                                          style: TextStyle(
                                            fontSize: GetResponsiveSize
                                                .getResponsiveFontSize(
                                              context,
                                              mobile: 14,
                                              tablet: 16,
                                              largeTablet: 18,
                                              desktop: 20,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            isDefaultAction: false,
                                            onPressed: () => Navigator.pop(
                                                dialogContext, false),
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                color:
                                                    CupertinoColors.systemBlue,
                                                fontSize: GetResponsiveSize
                                                    .getResponsiveFontSize(
                                                  context,
                                                  mobile: 16,
                                                  tablet: 18,
                                                  largeTablet: 20,
                                                  desktop: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            onPressed: () => Navigator.pop(
                                                dialogContext, true),
                                            child: Text(
                                              "Logout",
                                              style: TextStyle(
                                                fontSize: GetResponsiveSize
                                                    .getResponsiveFontSize(
                                                  context,
                                                  mobile: 16,
                                                  tablet: 18,
                                                  largeTablet: 20,
                                                  desktop: 22,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            GetResponsiveSize
                                                .getResponsiveBorderRadius(
                                              context,
                                              mobile: 20,
                                              tablet: 24,
                                              largeTablet: 28,
                                              desktop: 32,
                                            ),
                                          ),
                                        ),
                                        backgroundColor: AppColors.whiteColor,
                                        insetPadding: EdgeInsets.symmetric(
                                          horizontal: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 16,
                                            tablet: 40,
                                            largeTablet: 60,
                                            desktop: 80,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 30,
                                            tablet: 40,
                                            largeTablet: 50,
                                            desktop: 60,
                                          ),
                                          vertical: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 10,
                                            tablet: 20,
                                            largeTablet: 24,
                                            desktop: 28,
                                          ),
                                        ),
                                        titlePadding: EdgeInsets.only(
                                          top: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 24,
                                            tablet: 28,
                                            largeTablet: 32,
                                            desktop: 36,
                                          ),
                                          bottom: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 16,
                                            tablet: 20,
                                            largeTablet: 24,
                                            desktop: 28,
                                          ),
                                        ),
                                        title: Text(
                                          "Logout",
                                          textAlign: TextAlign.center,
                                          style: AppTextstyle.title1.copyWith(
                                            fontSize: GetResponsiveSize
                                                .getResponsiveFontSize(
                                              context,
                                              mobile: AppTextstyle
                                                      .title1.fontSize ??
                                                  20,
                                              tablet: 24,
                                              largeTablet: 28,
                                              desktop: 34,
                                            ),
                                          ),
                                        ),
                                        content: SizedBox(
                                          width: GetResponsiveSize
                                              .getResponsiveSize(
                                            context,
                                            mobile: 300,
                                            tablet: 400,
                                            largeTablet: 500,
                                            desktop: 600,
                                          ),
                                          child: Text(
                                            "Are you sure you want to logout?",
                                            textAlign: TextAlign.center,
                                            style: AppTextstyle
                                                .sectionTitleTextStyle
                                                .copyWith(
                                              fontSize: GetResponsiveSize
                                                  .getResponsiveFontSize(
                                                context,
                                                mobile: AppTextstyle
                                                        .sectionTitleTextStyle
                                                        .fontSize ??
                                                    16,
                                                tablet: 20,
                                                largeTablet: 24,
                                                desktop: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.center,
                                        actionsPadding: EdgeInsets.only(
                                          left: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 30,
                                            tablet: 40,
                                            largeTablet: 50,
                                            desktop: 60,
                                          ),
                                          right: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 30,
                                            tablet: 40,
                                            largeTablet: 50,
                                            desktop: 60,
                                          ),
                                          top: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 8,
                                            tablet: 12,
                                            largeTablet: 16,
                                            desktop: 20,
                                          ),
                                          bottom: GetResponsiveSize
                                              .getResponsivePadding(
                                            context,
                                            mobile: 8,
                                            tablet: 12,
                                            largeTablet: 16,
                                            desktop: 20,
                                          ),
                                        ),
                                        actions: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile: 50,
                                                    tablet: 65,
                                                    largeTablet: 80,
                                                    desktop: 90,
                                                  ),
                                                  child: TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStatePropertyAll(
                                                              AppColors
                                                                  .whiteColor),
                                                      side: WidgetStatePropertyAll(
                                                          BorderSide(
                                                              color: Colors.red,
                                                              width: GetResponsiveSize
                                                                  .getResponsiveSize(
                                                                context,
                                                                mobile: 1.0,
                                                                tablet: 1.5,
                                                                largeTablet:
                                                                    2.0,
                                                                desktop: 2.5,
                                                              ))),
                                                      shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                        context,
                                                        mobile: 10,
                                                        tablet: 14,
                                                        largeTablet: 18,
                                                        desktop: 22,
                                                      )))),
                                                      padding:
                                                          WidgetStatePropertyAll(
                                                        EdgeInsets.symmetric(
                                                          vertical:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 14,
                                                            tablet: 18,
                                                            largeTablet: 22,
                                                            desktop: 26,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: GetResponsiveSize
                                                            .getResponsiveFontSize(
                                                          context,
                                                          mobile: 14,
                                                          tablet: 18,
                                                          largeTablet: 22,
                                                          desktop: 26,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: GetResponsiveSize
                                                    .getResponsiveSize(
                                                  context,
                                                  mobile: 12,
                                                  tablet: 18,
                                                  largeTablet: 24,
                                                  desktop: 30,
                                                ),
                                              ),
                                              Expanded(
                                                child: SizedBox(
                                                  height: GetResponsiveSize
                                                      .getResponsiveSize(
                                                    context,
                                                    mobile: 50,
                                                    tablet: 65,
                                                    largeTablet: 80,
                                                    desktop: 90,
                                                  ),
                                                  child: TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStatePropertyAll(
                                                              AppColors
                                                                  .redColor),
                                                      shape: WidgetStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                        context,
                                                        mobile: 10,
                                                        tablet: 14,
                                                        largeTablet: 18,
                                                        desktop: 22,
                                                      )))),
                                                      padding:
                                                          WidgetStatePropertyAll(
                                                        EdgeInsets.symmetric(
                                                          vertical:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 14,
                                                            tablet: 18,
                                                            largeTablet: 22,
                                                            desktop: 26,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: Text(
                                                      "Logout",
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .whiteColor,
                                                        fontSize: GetResponsiveSize
                                                            .getResponsiveFontSize(
                                                          context,
                                                          mobile: 14,
                                                          tablet: 18,
                                                          largeTablet: 22,
                                                          desktop: 26,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  if (confirm == true) {
                                    context.read<login_bloc.LoginBloc>().add(
                                        const login_bloc.LoginEvent.logout());
                                    context.go('/');
                                  }
                                },
                              ),
                              ProfileMenuItem(
                                image: 'assets/images/close.png',
                                title: "Delete Account",
                                isLogout: true,
                                onTap: () async {
                                  final TextEditingController _confirmCtl =
                                      TextEditingController();
                                  String? _errorText;

                                  bool? confirm;
                                  if (!kIsWeb && Platform.isIOS) {
                                    confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return StatefulBuilder(
                                          builder: (stateContext, setState) =>
                                              CupertinoAlertDialog(
                                            title: Text(
                                              "Delete Account",
                                              style: TextStyle(
                                                fontSize: GetResponsiveSize
                                                    .getResponsiveFontSize(
                                                  context,
                                                  mobile: 18,
                                                  tablet: 22,
                                                  largeTablet: 26,
                                                  desktop: 30,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            content: Container(
                                              padding: EdgeInsets.only(
                                                top: GetResponsiveSize
                                                    .getResponsivePadding(
                                                  context,
                                                  mobile: 16,
                                                  tablet: 20,
                                                  largeTablet: 24,
                                                  desktop: 28,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    "This will permanently delete your account and data. Continue?",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 14,
                                                        tablet: 16,
                                                        largeTablet: 18,
                                                        desktop: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 12,
                                                      tablet: 16,
                                                      largeTablet: 20,
                                                      desktop: 24,
                                                    ),
                                                  ),
                                                  Text(
                                                    "To confirm this, type 'DELETE'",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 13,
                                                        tablet: 15,
                                                        largeTablet: 17,
                                                        desktop: 19,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 8,
                                                      tablet: 12,
                                                      largeTablet: 16,
                                                      desktop: 20,
                                                    ),
                                                  ),
                                                  CupertinoTextField(
                                                    controller: _confirmCtl,
                                                    placeholder: "DELETE",
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: GetResponsiveSize
                                                          .getResponsivePadding(
                                                        context,
                                                        mobile: 12,
                                                        tablet: 16,
                                                        largeTablet: 20,
                                                        desktop: 24,
                                                      ),
                                                      vertical: GetResponsiveSize
                                                          .getResponsivePadding(
                                                        context,
                                                        mobile: 10,
                                                        tablet: 14,
                                                        largeTablet: 18,
                                                        desktop: 22,
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 16,
                                                        tablet: 18,
                                                        largeTablet: 20,
                                                        desktop: 22,
                                                      ),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: CupertinoColors
                                                          .systemGrey6,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    onChanged: (_) {
                                                      if (_errorText != null) {
                                                        setState(() =>
                                                            _errorText = null);
                                                      }
                                                    },
                                                  ),
                                                  if (_errorText != null)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: GetResponsiveSize
                                                            .getResponsiveSize(
                                                          context,
                                                          mobile: 8,
                                                          tablet: 10,
                                                          largeTablet: 12,
                                                          desktop: 14,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _errorText!,
                                                        style: TextStyle(
                                                          color: CupertinoColors
                                                              .systemRed,
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 14,
                                                            largeTablet: 16,
                                                            desktop: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              CupertinoDialogAction(
                                                isDefaultAction: false,
                                                onPressed: () => Navigator.pop(
                                                    dialogContext, false),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: CupertinoColors
                                                        .systemBlue,
                                                    fontSize: GetResponsiveSize
                                                        .getResponsiveFontSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 18,
                                                      largeTablet: 20,
                                                      desktop: 22,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              CupertinoDialogAction(
                                                isDefaultAction: false,
                                                isDestructiveAction: true,
                                                onPressed: () {
                                                  if (_confirmCtl.text.trim() !=
                                                      'DELETE') {
                                                    setState(() => _errorText =
                                                        'Please type DELETE');
                                                    return;
                                                  }
                                                  Navigator.pop(
                                                      dialogContext, true);
                                                },
                                                child: Text(
                                                  "Delete Account",
                                                  style: TextStyle(
                                                    fontSize: GetResponsiveSize
                                                        .getResponsiveFontSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 18,
                                                      largeTablet: 20,
                                                      desktop: 22,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) {
                                        return StatefulBuilder(
                                          builder: (ctx, setState) =>
                                              AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                GetResponsiveSize
                                                    .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 20,
                                                  tablet: 24,
                                                  largeTablet: 28,
                                                  desktop: 32,
                                                ),
                                              ),
                                            ),
                                            backgroundColor:
                                                AppColors.whiteColor,
                                            insetPadding: EdgeInsets.symmetric(
                                              horizontal: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 40,
                                                largeTablet: 60,
                                                desktop: 80,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              vertical: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 24,
                                                largeTablet: 28,
                                                desktop: 32,
                                              ),
                                            ),
                                            titlePadding: EdgeInsets.only(
                                              left: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              top: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 24,
                                                largeTablet: 28,
                                                desktop: 32,
                                              ),
                                              right: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                              bottom: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 0,
                                                tablet: 8,
                                                largeTablet: 12,
                                                desktop: 16,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Delete Account",
                                                    textAlign: TextAlign.center,
                                                    style: AppTextstyle.title1
                                                        .copyWith(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: AppTextstyle
                                                                .title1
                                                                .fontSize ??
                                                            20,
                                                        tablet: 24,
                                                        largeTablet: 28,
                                                        desktop: 34,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    size: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      largeTablet: 32,
                                                      desktop: 36,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                )
                                              ],
                                            ),
                                            content: SizedBox(
                                              width: GetResponsiveSize
                                                  .getResponsiveSize(
                                                context,
                                                mobile: 300,
                                                tablet: 400,
                                                largeTablet: 500,
                                                desktop: 600,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    "This will permanently delete your account and data. Continue?",
                                                    textAlign: TextAlign.center,
                                                    style: AppTextstyle
                                                        .sectionTitleTextStyle
                                                        .copyWith(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: AppTextstyle
                                                                .sectionTitleTextStyle
                                                                .fontSize ??
                                                            16,
                                                        tablet: 20,
                                                        largeTablet: 24,
                                                        desktop: 28,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 20,
                                                      largeTablet: 24,
                                                      desktop: 28,
                                                    ),
                                                  ),
                                                  Text(
                                                    "To confirm this, type 'DELETE'",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 14,
                                                        tablet: 18,
                                                        largeTablet: 22,
                                                        desktop: 26,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 8,
                                                      tablet: 12,
                                                      largeTablet: 16,
                                                      desktop: 20,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 56,
                                                      tablet: 65,
                                                      largeTablet: 75,
                                                      desktop: 85,
                                                    ),
                                                    child: TextField(
                                                      controller: _confirmCtl,
                                                      style: TextStyle(
                                                        fontSize: GetResponsiveSize
                                                            .getResponsiveFontSize(
                                                          context,
                                                          mobile: 16,
                                                          tablet: 20,
                                                          largeTablet: 22,
                                                          desktop: 26,
                                                        ),
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "DELETE",
                                                        hintStyle: TextStyle(
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 16,
                                                            tablet: 20,
                                                            largeTablet: 22,
                                                            desktop: 26,
                                                          ),
                                                        ),
                                                        errorText: _errorText,
                                                        errorStyle: TextStyle(
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 16,
                                                            largeTablet: 20,
                                                            desktop: 24,
                                                          ),
                                                        ),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  GetResponsiveSize
                                                                      .getResponsiveBorderRadius(
                                                            context,
                                                            mobile: 10,
                                                            tablet: 14,
                                                            largeTablet: 18,
                                                            desktop: 22,
                                                          )),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 18,
                                                            largeTablet: 24,
                                                            desktop: 30,
                                                          ),
                                                          vertical:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 16,
                                                            largeTablet: 20,
                                                            desktop: 24,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (_) {
                                                        if (_errorText !=
                                                            null) {
                                                          setState(() =>
                                                              _errorText =
                                                                  null);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actionsAlignment:
                                                MainAxisAlignment.center,
                                            actionsPadding: EdgeInsets.only(
                                              left: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              right: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              top: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                              bottom: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 50,
                                                        tablet: 65,
                                                        largeTablet: 80,
                                                        desktop: 90,
                                                      ),
                                                      child: TextButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStatePropertyAll(
                                                                  AppColors
                                                                      .whiteColor),
                                                          side: WidgetStatePropertyAll(
                                                              BorderSide(
                                                                  color: Colors
                                                                      .red,
                                                                  width: GetResponsiveSize
                                                                      .getResponsiveSize(
                                                                    context,
                                                                    mobile: 1.0,
                                                                    tablet: 1.5,
                                                                    largeTablet:
                                                                        2.0,
                                                                    desktop:
                                                                        2.5,
                                                                  ))),
                                                          shape:
                                                              WidgetStatePropertyAll(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                                context,
                                                                mobile: 10,
                                                                tablet: 14,
                                                                largeTablet: 18,
                                                                desktop: 22,
                                                              )),
                                                            ),
                                                          ),
                                                          padding:
                                                              WidgetStatePropertyAll(
                                                            EdgeInsets
                                                                .symmetric(
                                                              vertical:
                                                                  GetResponsiveSize
                                                                      .getResponsivePadding(
                                                                context,
                                                                mobile: 14,
                                                                tablet: 18,
                                                                largeTablet: 22,
                                                                desktop: 26,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child: Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize:
                                                                GetResponsiveSize
                                                                    .getResponsiveFontSize(
                                                              context,
                                                              mobile: 14,
                                                              tablet: 18,
                                                              largeTablet: 22,
                                                              desktop: 26,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 12,
                                                      tablet: 18,
                                                      largeTablet: 24,
                                                      desktop: 30,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 50,
                                                        tablet: 65,
                                                        largeTablet: 80,
                                                        desktop: 90,
                                                      ),
                                                      child: TextButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStatePropertyAll(
                                                                  AppColors
                                                                      .redColor),
                                                          shape:
                                                              WidgetStatePropertyAll(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                                context,
                                                                mobile: 10,
                                                                tablet: 14,
                                                                largeTablet: 18,
                                                                desktop: 22,
                                                              )),
                                                            ),
                                                          ),
                                                          padding:
                                                              WidgetStatePropertyAll(
                                                            EdgeInsets
                                                                .symmetric(
                                                              vertical:
                                                                  GetResponsiveSize
                                                                      .getResponsivePadding(
                                                                context,
                                                                mobile: 14,
                                                                tablet: 18,
                                                                largeTablet: 22,
                                                                desktop: 26,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          if (_confirmCtl.text
                                                                  .trim() !=
                                                              'DELETE') {
                                                            setState(() =>
                                                                _errorText =
                                                                    'Please type DELETE');
                                                            return;
                                                          }
                                                          Navigator.pop(
                                                              ctx, true);
                                                        },
                                                        child: Text(
                                                          "Delete Account",
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .whiteColor,
                                                            fontSize:
                                                                GetResponsiveSize
                                                                    .getResponsiveFontSize(
                                                              context,
                                                              mobile: 14,
                                                              tablet: 18,
                                                              largeTablet: 22,
                                                              desktop: 26,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  if (confirm == true) {
                                    try {
                                      await context
                                          .read<profile_bloc.ProfileBloc>()
                                          .deleteAccount();
                                      context.read<login_bloc.LoginBloc>().add(
                                          const login_bloc.LoginEvent.logout());
                                      context.go('/');
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                              ProfileMenuItem(
                                image: 'assets/images/close.png',
                                title: "Delete My Data",
                                isLogout: true,
                                onTap: () async {
                                  final TextEditingController _confirmCtl =
                                      TextEditingController();
                                  String? _errorText;

                                  bool? confirm;
                                  if (!kIsWeb && Platform.isIOS) {
                                    confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return StatefulBuilder(
                                          builder: (stateContext, setState) =>
                                              CupertinoAlertDialog(
                                            title: Text(
                                              "Delete My Data",
                                              style: TextStyle(
                                                fontSize: GetResponsiveSize
                                                    .getResponsiveFontSize(
                                                  context,
                                                  mobile: 18,
                                                  tablet: 22,
                                                  largeTablet: 26,
                                                  desktop: 30,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            content: Container(
                                              padding: EdgeInsets.only(
                                                top: GetResponsiveSize
                                                    .getResponsivePadding(
                                                  context,
                                                  mobile: 16,
                                                  tablet: 20,
                                                  largeTablet: 24,
                                                  desktop: 28,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    "This will permanently delete all your ads. Continue?",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 14,
                                                        tablet: 16,
                                                        largeTablet: 18,
                                                        desktop: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 12,
                                                      tablet: 16,
                                                      largeTablet: 20,
                                                      desktop: 24,
                                                    ),
                                                  ),
                                                  Text(
                                                    "To confirm this, type 'DELETE'",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 13,
                                                        tablet: 15,
                                                        largeTablet: 17,
                                                        desktop: 19,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 8,
                                                      tablet: 12,
                                                      largeTablet: 16,
                                                      desktop: 20,
                                                    ),
                                                  ),
                                                  CupertinoTextField(
                                                    controller: _confirmCtl,
                                                    placeholder: "DELETE",
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: GetResponsiveSize
                                                          .getResponsivePadding(
                                                        context,
                                                        mobile: 12,
                                                        tablet: 16,
                                                        largeTablet: 20,
                                                        desktop: 24,
                                                      ),
                                                      vertical: GetResponsiveSize
                                                          .getResponsivePadding(
                                                        context,
                                                        mobile: 10,
                                                        tablet: 14,
                                                        largeTablet: 18,
                                                        desktop: 22,
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 16,
                                                        tablet: 18,
                                                        largeTablet: 20,
                                                        desktop: 22,
                                                      ),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: CupertinoColors
                                                          .systemGrey6,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    onChanged: (_) {
                                                      if (_errorText != null) {
                                                        setState(() =>
                                                            _errorText = null);
                                                      }
                                                    },
                                                  ),
                                                  if (_errorText != null)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: GetResponsiveSize
                                                            .getResponsiveSize(
                                                          context,
                                                          mobile: 8,
                                                          tablet: 10,
                                                          largeTablet: 12,
                                                          desktop: 14,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _errorText!,
                                                        style: TextStyle(
                                                          color: CupertinoColors
                                                              .systemRed,
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 14,
                                                            largeTablet: 16,
                                                            desktop: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              CupertinoDialogAction(
                                                isDefaultAction: false,
                                                onPressed: () => Navigator.pop(
                                                    dialogContext, false),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: CupertinoColors
                                                        .systemBlue,
                                                    fontSize: GetResponsiveSize
                                                        .getResponsiveFontSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 18,
                                                      largeTablet: 20,
                                                      desktop: 22,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              CupertinoDialogAction(
                                                isDefaultAction: false,
                                                isDestructiveAction: true,
                                                onPressed: () {
                                                  if (_confirmCtl.text.trim() !=
                                                      'DELETE') {
                                                    setState(() => _errorText =
                                                        'Please type DELETE');
                                                    return;
                                                  }
                                                  Navigator.pop(
                                                      dialogContext, true);
                                                },
                                                child: Text(
                                                  "Delete My Data",
                                                  style: TextStyle(
                                                    fontSize: GetResponsiveSize
                                                        .getResponsiveFontSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 18,
                                                      largeTablet: 20,
                                                      desktop: 22,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) {
                                        return StatefulBuilder(
                                          builder: (ctx, setState) =>
                                              AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                GetResponsiveSize
                                                    .getResponsiveBorderRadius(
                                                  context,
                                                  mobile: 20,
                                                  tablet: 24,
                                                  largeTablet: 28,
                                                  desktop: 32,
                                                ),
                                              ),
                                            ),
                                            backgroundColor:
                                                AppColors.whiteColor,
                                            insetPadding: EdgeInsets.symmetric(
                                              horizontal: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 40,
                                                largeTablet: 60,
                                                desktop: 80,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              vertical: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 24,
                                                largeTablet: 28,
                                                desktop: 32,
                                              ),
                                            ),
                                            titlePadding: EdgeInsets.only(
                                              left: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              top: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 16,
                                                tablet: 24,
                                                largeTablet: 28,
                                                desktop: 32,
                                              ),
                                              right: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                              bottom: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 0,
                                                tablet: 8,
                                                largeTablet: 12,
                                                desktop: 16,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Delete My Data",
                                                    textAlign: TextAlign.center,
                                                    style: AppTextstyle.title1
                                                        .copyWith(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: AppTextstyle
                                                                .title1
                                                                .fontSize ??
                                                            20,
                                                        tablet: 24,
                                                        largeTablet: 28,
                                                        desktop: 34,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    size: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      largeTablet: 32,
                                                      desktop: 36,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                )
                                              ],
                                            ),
                                            content: SizedBox(
                                              width: GetResponsiveSize
                                                  .getResponsiveSize(
                                                context,
                                                mobile: 300,
                                                tablet: 400,
                                                largeTablet: 500,
                                                desktop: 600,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    "This will permanently delete all your ads. Continue?",
                                                    textAlign: TextAlign.center,
                                                    style: AppTextstyle
                                                        .sectionTitleTextStyle
                                                        .copyWith(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: AppTextstyle
                                                                .sectionTitleTextStyle
                                                                .fontSize ??
                                                            16,
                                                        tablet: 20,
                                                        largeTablet: 24,
                                                        desktop: 28,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 16,
                                                      tablet: 20,
                                                      largeTablet: 24,
                                                      desktop: 28,
                                                    ),
                                                  ),
                                                  Text(
                                                    "To confirm this, type 'DELETE'",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: GetResponsiveSize
                                                          .getResponsiveFontSize(
                                                        context,
                                                        mobile: 14,
                                                        tablet: 18,
                                                        largeTablet: 22,
                                                        desktop: 26,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 8,
                                                      tablet: 12,
                                                      largeTablet: 16,
                                                      desktop: 20,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 56,
                                                      tablet: 65,
                                                      largeTablet: 75,
                                                      desktop: 85,
                                                    ),
                                                    child: TextField(
                                                      controller: _confirmCtl,
                                                      style: TextStyle(
                                                        fontSize: GetResponsiveSize
                                                            .getResponsiveFontSize(
                                                          context,
                                                          mobile: 16,
                                                          tablet: 20,
                                                          largeTablet: 22,
                                                          desktop: 26,
                                                        ),
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "DELETE",
                                                        hintStyle: TextStyle(
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 16,
                                                            tablet: 20,
                                                            largeTablet: 22,
                                                            desktop: 26,
                                                          ),
                                                        ),
                                                        errorText: _errorText,
                                                        errorStyle: TextStyle(
                                                          fontSize:
                                                              GetResponsiveSize
                                                                  .getResponsiveFontSize(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 16,
                                                            largeTablet: 20,
                                                            desktop: 24,
                                                          ),
                                                        ),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  GetResponsiveSize
                                                                      .getResponsiveBorderRadius(
                                                            context,
                                                            mobile: 10,
                                                            tablet: 14,
                                                            largeTablet: 18,
                                                            desktop: 22,
                                                          )),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 18,
                                                            largeTablet: 24,
                                                            desktop: 30,
                                                          ),
                                                          vertical:
                                                              GetResponsiveSize
                                                                  .getResponsivePadding(
                                                            context,
                                                            mobile: 12,
                                                            tablet: 16,
                                                            largeTablet: 20,
                                                            desktop: 24,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (_) {
                                                        if (_errorText !=
                                                            null) {
                                                          setState(() =>
                                                              _errorText =
                                                                  null);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actionsAlignment:
                                                MainAxisAlignment.center,
                                            actionsPadding: EdgeInsets.only(
                                              left: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              right: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 24,
                                                tablet: 32,
                                                largeTablet: 40,
                                                desktop: 48,
                                              ),
                                              top: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                              bottom: GetResponsiveSize
                                                  .getResponsivePadding(
                                                context,
                                                mobile: 8,
                                                tablet: 12,
                                                largeTablet: 16,
                                                desktop: 20,
                                              ),
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 50,
                                                        tablet: 65,
                                                        largeTablet: 80,
                                                        desktop: 90,
                                                      ),
                                                      child: TextButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStatePropertyAll(
                                                                  AppColors
                                                                      .whiteColor),
                                                          side: WidgetStatePropertyAll(
                                                              BorderSide(
                                                                  color: Colors
                                                                      .red,
                                                                  width: GetResponsiveSize
                                                                      .getResponsiveSize(
                                                                    context,
                                                                    mobile: 1.0,
                                                                    tablet: 1.5,
                                                                    largeTablet:
                                                                        2.0,
                                                                    desktop:
                                                                        2.5,
                                                                  ))),
                                                          shape:
                                                              WidgetStatePropertyAll(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                                context,
                                                                mobile: 10,
                                                                tablet: 14,
                                                                largeTablet: 18,
                                                                desktop: 22,
                                                              )),
                                                            ),
                                                          ),
                                                          padding:
                                                              WidgetStatePropertyAll(
                                                            EdgeInsets
                                                                .symmetric(
                                                              vertical:
                                                                  GetResponsiveSize
                                                                      .getResponsivePadding(
                                                                context,
                                                                mobile: 14,
                                                                tablet: 18,
                                                                largeTablet: 22,
                                                                desktop: 26,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child: Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize:
                                                                GetResponsiveSize
                                                                    .getResponsiveFontSize(
                                                              context,
                                                              mobile: 14,
                                                              tablet: 18,
                                                              largeTablet: 22,
                                                              desktop: 26,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: GetResponsiveSize
                                                        .getResponsiveSize(
                                                      context,
                                                      mobile: 12,
                                                      tablet: 18,
                                                      largeTablet: 24,
                                                      desktop: 30,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: GetResponsiveSize
                                                          .getResponsiveSize(
                                                        context,
                                                        mobile: 50,
                                                        tablet: 65,
                                                        largeTablet: 80,
                                                        desktop: 90,
                                                      ),
                                                      child: TextButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              WidgetStatePropertyAll(
                                                                  AppColors
                                                                      .redColor),
                                                          shape:
                                                              WidgetStatePropertyAll(
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      GetResponsiveSize
                                                                          .getResponsiveBorderRadius(
                                                                context,
                                                                mobile: 10,
                                                                tablet: 14,
                                                                largeTablet: 18,
                                                                desktop: 22,
                                                              )),
                                                            ),
                                                          ),
                                                          padding:
                                                              WidgetStatePropertyAll(
                                                            EdgeInsets
                                                                .symmetric(
                                                              vertical:
                                                                  GetResponsiveSize
                                                                      .getResponsivePadding(
                                                                context,
                                                                mobile: 14,
                                                                tablet: 18,
                                                                largeTablet: 22,
                                                                desktop: 26,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          if (_confirmCtl.text
                                                                  .trim() !=
                                                              'DELETE') {
                                                            setState(() =>
                                                                _errorText =
                                                                    'Please type DELETE');
                                                            return;
                                                          }
                                                          Navigator.pop(
                                                              ctx, true);
                                                        },
                                                        child: Text(
                                                          "Delete My Data",
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .whiteColor,
                                                            fontSize:
                                                                GetResponsiveSize
                                                                    .getResponsiveFontSize(
                                                              context,
                                                              mobile: 14,
                                                              tablet: 18,
                                                              largeTablet: 22,
                                                              desktop: 26,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  if (confirm == true) {
                                    try {
                                      context
                                          .read<profile_bloc.ProfileBloc>()
                                          .add(const profile_bloc
                                              .ProfileEvent.deleteMyData());
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to delete my data: $e'),
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
                    return Center(
                        child: Text(ErrorMessageUtil.getUserFriendlyMessage(
                            state.message)));
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
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.only(bottom: 20),
          child: const BottomNavBar(),
        ),
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
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 56,
        tablet: 65,
        largeTablet: 75,
        desktop: 85,
      ),
      child: TextFormField(
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 12,
              tablet: 18,
              largeTablet: 24,
              desktop: 30,
            ),
            vertical: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 6,
              tablet: 8,
              largeTablet: 10,
              desktop: 12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 15,
                largeTablet: 17,
                desktop: 19,
              ),
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
        ),
        Container(
          height: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 44,
            tablet: 50,
            largeTablet: 56,
            desktop: 62,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  obscureText: !isVisible,
                  placeholder: label,
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 12,
                      tablet: 16,
                      largeTablet: 20,
                      desktop: 24,
                    ),
                    vertical: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 10,
                      tablet: 12,
                      largeTablet: 14,
                      desktop: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      largeTablet: 20,
                      desktop: 22,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 8,
                    tablet: 12,
                    largeTablet: 16,
                    desktop: 20,
                  ),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: onToggleVisibility,
                  child: Icon(
                    isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      largeTablet: 24,
                      desktop: 26,
                    ),
                    color: CupertinoColors.label,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(
              top: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 6,
                tablet: 8,
                largeTablet: 10,
                desktop: 12,
              ),
            ),
            child: Text(
              errorText,
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  largeTablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
      ],
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
