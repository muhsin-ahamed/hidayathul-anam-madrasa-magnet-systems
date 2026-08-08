// super_admin_settings_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/controllers/auth_controller.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../models/models.dart';
import '../../theme/theme_manager.dart';
import '../../widgets/responsive.dart';
import '../../widgets/image_crop_dialog.dart';

class SuperAdminSettingsPage extends StatefulWidget {
  const SuperAdminSettingsPage({super.key});

  @override
  State<SuperAdminSettingsPage> createState() => _SuperAdminSettingsPageState();
}

class _SuperAdminSettingsPageState extends State<SuperAdminSettingsPage> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isUploadingAvatar = false;
  bool _isUpdatingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickCropAndUploadImage(ImageSource? source) async {
    final authController = context.read<AuthController>();
    final profileRepo = context.read<ProfileRepository>();
    final profile = authController.currentProfile;
    if (profile == null) return;

    try {
      String? fileName;
      Uint8List? rawBytes;

      if (source != null) {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(source: source, imageQuality: 90);
        if (xFile == null) return;
        fileName = xFile.name;
        rawBytes = await xFile.readAsBytes();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final pickedFile = result.files.first;
        fileName = pickedFile.name;
        rawBytes = pickedFile.bytes;
      }

      if (rawBytes == null || rawBytes.isEmpty) return;

      // File size validation (Max 10 MB)
      if (rawBytes.lengthInBytes > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size exceeds 10 MB limit. Please select a smaller image.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Extension validation
      final String safeName = fileName.isNotEmpty ? fileName : 'image.png';
      final ext = safeName.toLowerCase().split('.').last;
      const validExts = ['jpg', 'jpeg', 'png', 'webp'];
      if (!validExts.contains(ext)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid format. Supported formats: JPG, JPEG, PNG, WEBP.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Image Cropping Step
      Uint8List? croppedBytes;
      if (mounted) {
        croppedBytes = await showDialog<Uint8List>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => CropImageDialog(imageBytes: rawBytes!),
        );
      }

      if (croppedBytes == null) return; // User cancelled cropping

      final Uint8List uploadBytes = croppedBytes;
      final String uploadFileName = 'cropped_$safeName';

      setState(() => _isUploadingAvatar = true);

      final avatarUrl = await profileRepo.uploadProfileAvatar(
        profile.id,
        uploadBytes,
        uploadFileName,
      );

      final updatedProfile = profile.copyWith(avatarUrl: avatarUrl);
      authController.updateCurrentProfile(updatedProfile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture cropped & updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Avatar upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showAvatarSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Select Profile Picture Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF0F172A)),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickCropAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0F172A)),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickCropAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined, color: Color(0xFF0F172A)),
                  title: const Text('Choose from Files'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickCropAndUploadImage(null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeManager.themeModeNotifier,
          builder: (context, currentMode, _) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Select Theme', style: TextStyle(fontWeight: FontWeight.bold)),
              content: RadioGroup<ThemeMode>(
                groupValue: currentMode,
                onChanged: (val) {
                  if (val != null) {
                    ThemeManager.setThemeMode(val);
                    Navigator.pop(ctx);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    RadioListTile<ThemeMode>(
                      title: Text('Light'),
                      secondary: Icon(Icons.light_mode_outlined),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark'),
                      secondary: Icon(Icons.dark_mode_outlined),
                      value: ThemeMode.dark,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('System Default'),
                      secondary: Icon(Icons.brightness_auto_outlined),
                      value: ThemeMode.system,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(Profile profile) {
    final nameCtrl = TextEditingController(text: profile.fullName);
    final emailCtrl = TextEditingController(text: profile.email ?? '');
    final phoneCtrl = TextEditingController(text: profile.phone ?? '');
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Super Admin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final newName = nameCtrl.text.trim();
                          if (newName.isEmpty) {
                            setDialogState(() => dialogError = 'Full Name is required.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            final profileRepo = context.read<ProfileRepository>();
                            final authController = context.read<AuthController>();
                            final updatedProfile = profile.copyWith(
                              fullName: newName,
                              email: emailCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              updatedAt: DateTime.now(),
                            );
                            final messenger = ScaffoldMessenger.of(context);
                            await profileRepo.updateProfile(updatedProfile);
                            authController.updateCurrentProfile(updatedProfile);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Super Admin profile updated successfully!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      setState(() => _passwordError = 'Please enter your current password.');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _passwordError = 'New password must be at least 8 characters long.');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      setState(() => _passwordError = 'New password must contain at least one uppercase letter.');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(newPass)) {
      setState(() => _passwordError = 'New password must contain at least one lowercase letter.');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPass)) {
      setState(() => _passwordError = 'New password must contain at least one number.');
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPass)) {
      setState(() => _passwordError = 'New password must contain at least one special character.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _passwordError = 'New passwords do not match.');
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
    });

    try {
      final authController = context.read<AuthController>();
      await authController.changePassword(currentPass, newPass);

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please log in again.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

      await authController.logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPassword = false);
      }
    }
  }

  void _handleLogout() async {
    final authController = context.read<AuthController>();
    await authController.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'SA';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final authController = context.watch<AuthController>();
    final profile = authController.currentProfile;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFC6C6CD);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF45464D);

    final adminName = profile?.fullName ?? 'Super Admin';
    final adminEmail = profile?.email ?? 'admin@portal.edu';

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40.0 : 20.0,
              vertical: isDesktop ? 36.0 : 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Super Admin Settings',
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage administrator profile, system preferences, security credentials, and portal settings.',
                  style: TextStyle(
                    fontSize: 15,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 28),

                // CARD 1: PROFILE SUMMARY & AVATAR
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _isUploadingAvatar ? null : _showAvatarSourcePicker,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: const Color(0xFF131B2E),
                                  backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.trim().isNotEmpty)
                                      ? NetworkImage(getFullImageUrl(profile.avatarUrl))
                                      : null,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      : (profile?.avatarUrl == null || profile!.avatarUrl!.trim().isEmpty)
                                          ? Text(
                                              _getInitials(adminName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.crop,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  adminEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Chip(
                                      avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                                      label: const Text('Super Administrator'),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    Chip(
                                      avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                      label: const Text('Active Account'),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isUploadingAvatar ? null : _showAvatarSourcePicker,
                            icon: const Icon(Icons.crop, size: 18),
                            label: const Text('Crop & Change Picture'),
                          ),
                          FilledButton.icon(
                            onPressed: profile != null ? () => _showEditProfileDialog(profile) : null,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CARD 2: PREFERENCES & THEME
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeManager.themeModeNotifier,
                        builder: (context, mode, _) {
                          return ListTile(
                            leading: Icon(
                              ThemeManager.getThemeIcon(mode),
                              color: const Color(0xFF0F172A),
                            ),
                            title: const Text('Appearance Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Current: ${ThemeManager.getThemeLabel(mode)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showThemeSelectionDialog,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CARD 3: SECURITY & PASSWORD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_passwordError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: !_showCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                              color: secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() => _showCurrentPassword = !_showCurrentPassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: !_showNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          helperText: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showNewPassword ? Icons.visibility : Icons.visibility_off,
                              color: secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() => _showNewPassword = !_showNewPassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() => _showConfirmPassword = !_showConfirmPassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isUpdatingPassword ? null : _updatePassword,
                            child: _isUpdatingPassword
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Update Password'),
                          ),
                          OutlinedButton(
                            onPressed: _isUpdatingPassword
                                ? null
                                : () {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                    setState(() => _passwordError = null);
                                  },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // CARD 5: LOGOUT
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout Account',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Sign out of your super admin session'),
                    onTap: _handleLogout,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
