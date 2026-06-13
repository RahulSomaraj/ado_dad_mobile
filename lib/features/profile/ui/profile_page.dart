import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
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
import 'package:ado_dad_user/common/widgets/theme_mode_tile.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/change_password_dialog.dart';

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
  String _countryCode = "+1"; // Default country code

  Uint8List? _pickedImageBytes; // local preview
  String? _currentProfilePicUrl; // from API or after upload
  bool _isSaving = false;
  bool _isUpdatingProfile = false; // Track if we're updating profile
  UserProfile? _lastLoadedProfile; // Store last loaded profile to show on error

  // Change password dialog controllers
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();

  /// Clean error message by removing "Exception: ", "Exception" text, and square brackets
  String _cleanErrorMessage(String message) {
    String cleaned = message;
    // Remove "Exception: " prefix
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length);
    }
    // Remove "Exception: " if it appears anywhere
    cleaned = cleaned.replaceAll('Exception: ', '');
    // Remove standalone "Exception" word
    cleaned = cleaned.replaceAll(RegExp(r'\bException\b'), '');

    // Extract content from square brackets instead of removing them
    // If message is like "[property countryCode should not exist]", extract "property countryCode should not exist"
    final bracketMatch = RegExp(r'\[(.*?)\]').firstMatch(cleaned);
    if (bracketMatch != null && bracketMatch.group(1) != null) {
      cleaned = bracketMatch.group(1)!;
    } else {
      // If no brackets found, remove any remaining brackets
      cleaned = cleaned.replaceAll('[', '').replaceAll(']', '');
    }

    return cleaned.trim();
  }

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
      UserProfile originalProfile;

      if (currentState is Loaded) {
        // Use the loaded profile
        originalProfile = currentState.profile;
        // Update _lastLoadedProfile to keep it in sync
        _lastLoadedProfile = originalProfile;
      } else if (_lastLoadedProfile != null) {
        // If state is Error but we have last loaded profile, use it
        originalProfile = _lastLoadedProfile!;
        print("⚠️ Using last loaded profile due to error state");
      } else {
        // No profile data available, try to fetch it
        print("⚠️ No profile data available, fetching...");
        context.read<ProfileBloc>().add(const ProfileEvent.fetchProfile());
        throw 'Profile not loaded. Please wait a moment and try again.';
      }
      final updatedName = nameController.text.trim();
      final updatedEmail = emailController.text.trim();
      final updatedPhoneNumber = phoneController.text.trim();

      // Check what fields have actually changed
      final nameChanged = updatedName != originalProfile.name;
      final emailChanged = updatedEmail != originalProfile.email;
      final phoneChanged = updatedPhoneNumber != originalProfile.phoneNumber;
      final countryCodeChanged =
          _countryCode != (originalProfile.countryCode ?? "+1");
      final profilePicChanged = _pickedImageBytes != null;

      // If nothing changed, just exit editing mode
      if (!nameChanged &&
          !emailChanged &&
          !phoneChanged &&
          !countryCodeChanged &&
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
          !RegExp(r"^[0-9]+$").hasMatch(updatedPhoneNumber)) {
        throw 'Please enter a valid phone number';
      }

      // Build updated model with only changed fields
      final updatedProfile = UserProfile(
        id: userId,
        name: nameChanged ? updatedName : originalProfile.name,
        email: emailChanged ? updatedEmail : originalProfile.email,
        phoneNumber:
            phoneChanged ? updatedPhoneNumber : originalProfile.phoneNumber,
        countryCode:
            countryCodeChanged ? _countryCode : originalProfile.countryCode,
        type: "NU", // Keep type unchanged
        profilePic:
            profilePicChanged ? profilePicUrl : originalProfile.profilePic,
      );

      print("🔄 Changes detected:");
      print("  - Name: ${nameChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Email: ${emailChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Phone: ${phoneChanged ? 'CHANGED' : 'unchanged'}");
      print(
          "  - Country Code: ${countryCodeChanged ? 'CHANGED' : 'unchanged'}");
      print("  - Profile Pic: ${profilePicChanged ? 'CHANGED' : 'unchanged'}");

      // Dispatch update event
      context
          .read<ProfileBloc>()
          .add(ProfileEvent.updateProfile(updatedProfile));

      setState(() {
        isEditing = false;
        _pickedImageBytes = null;
      });

      // Success message will be shown in BlocConsumer listener after successful update
    } catch (e) {
      print("❌ Profile save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save failed: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade300.withOpacity(0.9),
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

    ChangePasswordDialog.show(
      context: context,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
      formKey: _changePasswordFormKey,
      isNewPasswordVisible: _isNewPasswordVisible,
      isConfirmPasswordVisible: _isConfirmPasswordVisible,
      onNewPasswordVisibilityChanged: (value) {
        setState(() {
          _isNewPasswordVisible = value;
        });
      },
      onConfirmPasswordVisibilityChanged: (value) {
        setState(() {
          _isConfirmPasswordVisible = value;
        });
      },
      onConfirm: () => _changePassword(),
      onIOSConfirm: () => _performChangePassword(),
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
                  // Show success message only after successful profile update
                  if (state is profile_bloc.Loaded && _isUpdatingProfile) {
                    _isUpdatingProfile = false; // Reset flag
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Profile updated successfully!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                  }

                  // Track when saving starts
                  if (state is profile_bloc.Saving) {
                    _isUpdatingProfile = true;
                  }

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
                      _isUpdatingProfile = false;
                      return; // Skip showing snackbar
                    }

                    // Check if error is related to "Delete My Data"
                    final isDeleteMyDataError =
                        state.message.toLowerCase().contains('delete') &&
                            state.message.toLowerCase().contains('data');

                    if (isDeleteMyDataError) {
                      // Navigate back to profile page and show error in red snackbar
                      _isUpdatingProfile = false;
                      context.go('/profile');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _cleanErrorMessage(state.message),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red.shade300.withOpacity(0.9),
                        ),
                      );
                    } else {
                      // Only show error message if it's a profile update error (not initial load error)
                      if (_isUpdatingProfile) {
                        _isUpdatingProfile = false; // Reset flag
                        // Show cleaned error message only once
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _cleanErrorMessage(state.message),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                Colors.red.shade300.withOpacity(0.9),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                      // For initial load errors, don't show snackbar here (let builder handle it)
                    }
                  }

                  if (state is profile_bloc.PasswordChanged) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Password changed successfully!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                    // Navigate back to profile page
                    context.go('/profile');
                  }

                  if (state is profile_bloc.DataDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Your data has been deleted successfully!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryColor,
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
                    _countryCode = state.profile.countryCode ?? "+1";

                    print(
                        "🔍 Original profile pic from API: ${state.profile.profilePic}");

                    // Keep the original profile pic value as is
                    _currentProfilePicUrl = state.profile.profilePic;

                    print(
                        "🔍 Processed profile pic URL: $_currentProfilePicUrl");
                    _seededOnce = true;
                  }

                  // Store last loaded profile to show on error
                  if (state is Loaded) {
                    _lastLoadedProfile = state.profile;
                  }
                },
                builder: (context, state) {
                  if (state is profile_bloc.Loading) {
                    return const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Handle error state - show profile card if we have last loaded profile
                  // Errors are already shown as snackbars in the listener
                  if (state is profile_bloc.Error) {
                    // Check if error is related to "Delete My Data"
                    final isDeleteMyDataError =
                        state.message.toLowerCase().contains('delete') &&
                            state.message.toLowerCase().contains('data');

                    // For delete my data errors, trigger a profile fetch
                    if (isDeleteMyDataError) {
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

                    // If we have a last loaded profile, show it (for profile update errors)
                    // This ensures the profile card is visible even when update fails
                    if (_lastLoadedProfile != null) {
                      // Update controllers with last loaded profile data
                      if (!isEditing) {
                        nameController.text = _lastLoadedProfile!.name;
                        emailController.text = _lastLoadedProfile!.email;
                        phoneController.text = _lastLoadedProfile!.phoneNumber;
                        _countryCode = _lastLoadedProfile!.countryCode ?? "+1";
                        _currentProfilePicUrl = _lastLoadedProfile!.profilePic;
                      }
                      // Continue to show profile content below
                    } else {
                      // No profile loaded yet, try to fetch it
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
                  }

                  // Show profile content when loaded, while saving, or on error (if we have last loaded profile)
                  if (state is Loaded ||
                      state is Saving ||
                      (state is profile_bloc.Error &&
                          _lastLoadedProfile != null)) {
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
                          countryCode: _countryCode,
                          onCountryCodeChanged: (code) {
                            setState(() {
                              _countryCode = code;
                            });
                          },
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
                              const ThemeModeTile(),
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
                                            'Failed to delete account: $e',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red.shade300
                                              .withOpacity(0.9),
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
                                            'Failed to delete my data: $e',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red.shade300
                                              .withOpacity(0.9),
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
        // Bottom navigation is now provided by the persistent shell.
      ),
    );
  }
}
