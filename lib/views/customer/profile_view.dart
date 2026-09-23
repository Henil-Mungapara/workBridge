import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';

/// Customer Profile Screen (View).
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserController>();
    _nameController.text = user.userName;
    _phoneController.text = user.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSaveProfile() async {
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isEmpty) {
      UiHelper.showSnackBar(context, 'Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await context.read<UserController>().updateProfile(
          name: newName,
          phone: newPhone,
        );

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (mounted) {
      UiHelper.showSnackBar(context, 'Profile updated successfully!');
    }
  }

  Future<void> _onLogoutPressed() async {
    final shouldLogout = await UiHelper.showConfirmationDialog(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of WorkBridge?',
      confirmText: 'Log Out',
      cancelText: 'Cancel',
      icon: Icons.logout_rounded,
      confirmButtonColor: AppColors.primary,
    );

    if (shouldLogout == true && mounted) {
      // Sets isLoggOut=true, signs out from Firebase, resets session
      await context.read<UserController>().logout();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();

    if (!_isEditing) {
      _nameController.text = user.userName;
      _phoneController.text = user.phone;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UiHelper.customAppBar(
        context: context,
        title: 'My Profile',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _nameController.text = user.userName;
                  _phoneController.text = user.phone;
                }
              });
            },
          ),
          UiHelper.horizontalSpace(context, 0.02),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.widthPct(0.045),
            vertical: context.heightPct(0.015),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar & Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: context.widthPct(0.12),
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.userName.isNotEmpty
                          ? user.userName[0].toUpperCase()
                          : 'W',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.card,
                        fontSize: context.respFont(30),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.card,
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.012),

              Text(
                user.userName,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: context.respFont(19),
                ),
              ),

              Text(
                user.email,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: context.respFont(12.5),
                ),
              ),

              UiHelper.verticalSpace(context, 0.008),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthPct(0.03),
                  vertical: context.heightPct(0.004),
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Text(
                  'Verified ${user.role == 'service_provider' ? 'Service Provider' : (user.role.isEmpty ? 'Customer' : user.role[0].toUpperCase() + user.role.substring(1))}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: context.respFont(11),
                  ),
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),

              // Details & Edit Section
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.045)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Profile Details' : 'Account Credentials',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: context.respFont(15),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.015),

                    if (_isEditing) ...[
                      UiHelper.customTextField(
                        context: context,
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Your full name',
                        prefixIcon: Icons.person_outline_rounded,
                        widthFraction: 0.82,
                      ),
                      UiHelper.verticalSpace(context, 0.012),
                      UiHelper.customTextField(
                        context: context,
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Your mobile number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        widthFraction: 0.82,
                      ),
                      UiHelper.verticalSpace(context, 0.018),
                      UiHelper.primaryButton(
                        context: context,
                        text: 'Save Changes',
                        icon: Icons.save_rounded,
                        isLoading: _isSaving,
                        widthFraction: 0.82,
                        heightFraction: 0.055,
                        backgroundColor: AppColors.accent,
                        onPressed: _onSaveProfile,
                      ),
                    ] else ...[
                      _buildDetailRow(
                        context,
                        icon: Icons.fingerprint_rounded,
                        label: 'User ID (UID)',
                        value: user.uid,
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          color: AppColors.accent,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.uid));
                            UiHelper.showSnackBar(context, 'User ID copied to clipboard!');
                          },
                        ),
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildDetailRow(
                        context,
                        icon: Icons.mail_outline_rounded,
                        label: 'Email Address',
                        value: user.email,
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildDetailRow(
                        context,
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: user.phone,
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_rounded,
                        label: 'Member Since',
                        value: user.createdAt.length >= 10
                            ? user.createdAt.substring(0, 10)
                            : 'Active',
                      ),
                    ],
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),

              // Security & Settings
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.045)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security & Settings',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: context.respFont(15),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.015),
                    _buildSettingTile(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your security credentials',
                      onTap: () {
                        UiHelper.showSnackBar(context, 'Password reset link sent to your email.');
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildSettingTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Terms & Privacy',
                      subtitle: 'Review policies and agreements',
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
                      },
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.025),

              // Logout Button
              UiHelper.logoutButton(
                context: context,
                onPressed: _onLogoutPressed,
                label: 'Log Out of WorkBridge',
              ),

              UiHelper.verticalSpace(context, 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondaryText, size: context.respFont(19)),
        UiHelper.horizontalSpace(context, 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: context.respFont(11),
                ),
              ),
              UiHelper.verticalSpace(context, 0.003),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                  fontSize: context.respFont(13.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.heightPct(0.006)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: context.respFont(20)),
            UiHelper.horizontalSpace(context, 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                      fontSize: context.respFont(13.5),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: context.respFont(11),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
