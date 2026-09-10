import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/services/auth_service.dart';
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
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_label.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/profile_text_field.dart';
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
  bool _isChangingPassword = false; // Track if a password change is in flight
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
        debugPrint("⚠️ Using last loaded profile due to error state");
      } else {
        // No profile data available, try to fetch it
        debugPrint("⚠️ No profile data available, fetching...");
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
          debugPrint("📸 Uploaded new profile pic: $profilePicUrl");
          _currentProfilePicUrl = profilePicUrl;
        } catch (uploadError) {
          debugPrint("❌ Profile picture upload failed: $uploadError");
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

      debugPrint("🔄 Changes detected:");
      debugPrint("  - Name: ${nameChanged ? 'CHANGED' : 'unchanged'}");
      debugPrint("  - Email: ${emailChanged ? 'CHANGED' : 'unchanged'}");
      debugPrint("  - Phone: ${phoneChanged ? 'CHANGED' : 'unchanged'}");
      debugPrint(
          "  - Country Code: ${countryCodeChanged ? 'CHANGED' : 'unchanged'}");
      debugPrint("  - Profile Pic: ${profilePicChanged ? 'CHANGED' : 'unchanged'}");

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
      debugPrint("❌ Profile save error: $e");
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
        // Close the dialog first so the result snackbar is visible.
        Navigator.pop(context);
        context.read<ProfileBloc>().add(
              ProfileEvent.changePassword(_newPasswordController.text.trim()),
            );
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
        backgroundColor: AppColors.whiteColor,
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

                  // Track when a password change starts, so its failure is
                  // reported instead of being swallowed by the profile-update
                  // guard below.
                  if (state is profile_bloc.ChangingPassword) {
                    _isChangingPassword = true;
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
                      debugPrint(
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
                    } else if (_isChangingPassword) {
                      // Password change failed: show the real server message
                      // and put the page back into a loaded state.
                      _isChangingPassword = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _cleanErrorMessage(state.message),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red.shade300.withOpacity(0.9),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context
                              .read<ProfileBloc>()
                              .add(const ProfileEvent.fetchProfile());
                        }
                      });
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
                    _isChangingPassword = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Password changed successfully!',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryColor,
                      ),
                    );
                    // Already on the profile page: reload it so the bloc
                    // leaves the PasswordChanged state (which renders nothing).
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context
                            .read<ProfileBloc>()
                            .add(const ProfileEvent.fetchProfile());
                      }
                    });
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

                    debugPrint(
                        "🔍 Original profile pic from API: ${state.profile.profilePic}");

                    // Keep the original profile pic value as is
                    _currentProfilePicUrl = state.profile.profilePic;

                    debugPrint(
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
                  // Transient states (password change, data delete) must
                  // keep rendering the last loaded profile — otherwise the
                  // builder falls through to SizedBox.shrink() and the whole
                  // page goes blank.
                  final isTransientWithProfile =
                      (state is profile_bloc.ChangingPassword ||
                              state is profile_bloc.PasswordChanged ||
                              state is profile_bloc.DeletingData ||
                              state is profile_bloc.DataDeleted) &&
                          _lastLoadedProfile != null;

                  if (state is Loaded ||
                      state is Saving ||
                      isTransientWithProfile ||
                      (state is profile_bloc.Error &&
                          _lastLoadedProfile != null)) {
                    // if (state is Loaded) {
                    //   nameController.text = state.profile.name;
                    //   emailController.text = state.profile.email;
                    //   phoneController.text = state.profile.phoneNumber;
                    //   _currentProfilePicUrl = state.profile.profilePic;
                    // }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Flat app bar — wireframe: "Profile" + settings gear
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            MediaQuery.of(context).padding.top + 8,
                            8,
                            8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Profile",
                                style: TextStyle(
                                  color: AppColors.blackColor,
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
                              const Spacer(),
                              InkWell(
                                onTap: () =>
                                    setState(() => isEditing = !isEditing),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 40,
                                    tablet: 56,
                                    largeTablet: 62,
                                    desktop: 68,
                                  ),
                                  height: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 40,
                                    tablet: 56,
                                    largeTablet: 62,
                                    desktop: 68,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: AppColors.isDark
                                        ? Colors.white10
                                        : const Color(0xFFF1F2F6),
                                  ),
                                  child: Icon(
                                    Icons.settings_outlined,
                                    color: AppColors.blackColor,
                                    size: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 22,
                                      tablet: 30,
                                      largeTablet: 34,
                                      desktop: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.dividerColor),

                        // Compact hero — avatar + name/email + Edit (wireframe)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: isEditing ? _pickImage : null,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius:
                                          GetResponsiveSize.getResponsiveSize(
                                        context,
                                        mobile: 32,
                                        tablet: 44,
                                        largeTablet: 52,
                                        desktop: 58,
                                      ),
                                      backgroundColor: AppColors.greyColor,
                                      backgroundImage: _pickedImageBytes != null
                                          ? MemoryImage(_pickedImageBytes!)
                                          : (_currentProfilePicUrl != null &&
                                                  _currentProfilePicUrl!
                                                      .isNotEmpty &&
                                                  _currentProfilePicUrl !=
                                                      'default-profile-pic-url' &&
                                                  _currentProfilePicUrl!
                                                      .startsWith('http'))
                                              ? NetworkImage(
                                                      _currentProfilePicUrl!)
                                                  as ImageProvider
                                              : null,
                                      child: (_pickedImageBytes == null &&
                                              (_currentProfilePicUrl == null ||
                                                  _currentProfilePicUrl!
                                                      .isEmpty ||
                                                  _currentProfilePicUrl ==
                                                      'default-profile-pic-url' ||
                                                  !_currentProfilePicUrl!
                                                      .startsWith('http')))
                                          ? Icon(Icons.person,
                                              size: GetResponsiveSize
                                                  .getResponsiveSize(
                                                context,
                                                mobile: 34,
                                                tablet: 46,
                                                largeTablet: 54,
                                                desktop: 60,
                                              ),
                                              color: Colors.white)
                                          : null,
                                    ),
                                    if (isEditing)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryColor,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 1.5),
                                          ),
                                          child: const Icon(Icons.edit,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name + email
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            nameController.text.isEmpty
                                                ? 'Your name'
                                                : nameController.text,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.blackColor,
                                              fontSize: GetResponsiveSize
                                                  .getResponsiveFontSize(
                                                context,
                                                mobile: 16,
                                                tablet: 20,
                                                largeTablet: 24,
                                                desktop: 26,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.verified,
                                            color: AppColors.primaryColor,
                                            size: GetResponsiveSize
                                                .getResponsiveSize(
                                              context,
                                              mobile: 16,
                                              tablet: 20,
                                              largeTablet: 24,
                                              desktop: 26,
                                            )),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      emailController.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.greyColor,
                                        fontSize: GetResponsiveSize
                                            .getResponsiveFontSize(
                                          context,
                                          mobile: 12,
                                          tablet: 15,
                                          largeTablet: 17,
                                          desktop: 19,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Edit / Save pill
                              GestureDetector(
                                onTap: isEditing
                                    ? saveProfile
                                    : () => setState(() => isEditing = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? AppColors.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 1),
                                  ),
                                  child: Text(
                                    isEditing ? 'Save' : 'Edit',
                                    style: TextStyle(
                                      color: isEditing
                                          ? Colors.white
                                          : AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: GetResponsiveSize
                                          .getResponsiveFontSize(
                                        context,
                                        mobile: 13,
                                        tablet: 16,
                                        largeTablet: 18,
                                        desktop: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Editable fields appear inline only while editing
                        if (isEditing)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: AppColors.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const ProfileLabel(text: "Full Name"),
                                  ProfileTextField(
                                    controller: nameController,
                                    isEditable: isEditing,
                                  ),
                                  const ProfileLabel(text: "Email"),
                                  ProfileTextField(
                                    controller: emailController,
                                    isEditable: isEditing,
                                  ),
                                  const ProfileLabel(text: "Phone Number"),
                                  ProfileTextField(
                                    controller: phoneController,
                                    isEditable: isEditing,
                                    isPhoneField: true,
                                    countryCode: _countryCode,
                                    onCountryCodeChanged: (code) {
                                      setState(() {
                                        _countryCode = code;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Stats (kpis) — My ads / Wishlist / Chats
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                          child: const _ProfileStatsStrip(),
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.dividerColor),
                        // Menu list — flat full-width rows (all menus kept)
                              ProfileMenuItem(
                                  image: 'assets/images/add-profile-icon.png',
                                  title: "My Activities",
                                  onTap: () => context.go('/my-activity')),
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
                                      builder: (dialogContext) => AlertDialog(
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
                                                            dialogContext,
                                                            false),
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
                                                            dialogContext, true),
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
                                    // Reset the LoginBloc state, then perform a
                                    // fully-awaited logout (disconnects socket,
                                    // clears stored tokens/user data) BEFORE
                                    // navigating. We route to '/home' so the
                                    // user lands on the home screen as a guest
                                    // (no token). Navigating before the data was
                                    // cleared (or to the splash, which adds its
                                    // own timer) was why logout appeared not to
                                    // work.
                                    context.read<login_bloc.LoginBloc>().add(
                                        const login_bloc.LoginEvent.logout());
                                    await AuthService().logout(
                                        redirectTo: '/home');
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
                                      // Fully-awaited logout clears tokens/user
                                      // data, then routes to '/home' as a guest.
                                      // Previously this navigated to the splash
                                      // before the data was cleared, leaving the
                                      // user appearing logged in.
                                      await AuthService().logout(
                                          redirectTo: '/home');
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
                                showDivider: false,
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

/// Profile stats shortcuts: My ads · Wishlist · Chats, with live counts read
/// from the global blocs (loads are kicked off on first build).
class _ProfileStatsStrip extends StatefulWidget {
  const _ProfileStatsStrip();

  @override
  State<_ProfileStatsStrip> createState() => _ProfileStatsStripState();
}

class _ProfileStatsStripState extends State<_ProfileStatsStrip> {
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await AddRepository().fetchProfileStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _kpi(_stats?['ads'], 'My ads', () => context.push('/my-ads')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(_stats?['wishlist'], 'Wishlist',
              () => context.push('/wishlist')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpi(
              _stats?['chats'], 'Chats', () => context.go('/chat-rooms')),
        ),
      ],
    );
  }

  Widget _kpi(int? count, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count == null ? '—' : '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.greyColor),
            ),
          ],
        ),
      ),
    );
  }
}
