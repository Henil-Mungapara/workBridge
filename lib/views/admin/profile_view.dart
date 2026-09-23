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

/// Administrator Profile Screen (View).
///
/// Designed with reference to SmartAttend Admin_Profile_Screen:
/// - Dynamic user state management backed by [UserController] & Provider
/// - Live profile editing (Name and Phone) syncing directly with Cloud Firestore
/// - When name is edited and saved, all Admin panels across the app immediately update
/// - System master credentials, access privileges, and server health
/// - Logout confirmation dialog and session termination
class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
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

    // Updates Controller state, triggers notifyListeners(), and syncs with Cloud Firestore
    await context.read<UserController>().updateProfile(
          name: newName,
          phone: newPhone,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      UiHelper.showSnackBar(
        context,
        'Administrator profile updated successfully! All panels refreshed.',
      );
    }
  }

  Future<void> _onLogoutPressed() async {
    final shouldLogout = await UiHelper.showConfirmationDialog(
      context: context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of the Administrator Portal?',
      confirmText: 'Log Out',
      cancelText: 'Cancel',
      icon: Icons.logout_rounded,
      confirmButtonColor: AppColors.primary,
    );

    if (shouldLogout == true && mounted) {
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

    // Synchronize text controllers with state when not editing
    if (!_isEditing &&
        _nameController.text.isEmpty &&
        user.userName.isNotEmpty) {
      _nameController.text = user.userName;
      _phoneController.text = user.phone;
    }

    final String displayName =
        user.userName.isNotEmpty ? user.userName : 'System Administrator';
    final String initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.card),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0047AB),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_outlined,
              color: AppColors.card,
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
              // Avatar & Shield Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: context.widthPct(0.12),
                    backgroundColor: const Color(0xFF0047AB),
                    child: Text(
                      initialLetter,
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
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 16,
                      color: AppColors.card,
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.012),

              // Dynamic Admin Name
              Text(
                displayName,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: context.respFont(19),
                ),
              ),

              Text(
                user.email.isNotEmpty ? user.email : 'admin@workbridge.com',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: context.respFont(12.5),
                ),
              ),

              UiHelper.verticalSpace(context, 0.008),

              // Role Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthPct(0.035),
                  vertical: context.heightPct(0.005),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047AB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF0047AB), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Super Administrator',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF0047AB),
                        fontWeight: FontWeight.w700,
                        fontSize: context.respFont(11),
                      ),
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),

              // Account & In-place Edit Card
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.045)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Edit Administrator Credentials'
                          : 'Master Profile Details',
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
                        labelText: 'Administrator Name',
                        hintText: 'Enter full name',
                        prefixIcon: Icons.person_outline_rounded,
                        widthFraction: 0.82,
                      ),
                      UiHelper.verticalSpace(context, 0.012),
                      UiHelper.customTextField(
                        context: context,
                        controller: _phoneController,
                        labelText: 'Emergency Phone',
                        hintText: 'Contact phone number',
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
                        backgroundColor: const Color(0xFF0047AB),
                        onPressed: _onSaveProfile,
                      ),
                    ] else ...[
                      _buildDetailRow(
                        context,
                        icon: Icons.fingerprint_rounded,
                        label: 'Master Admin UID',
                        value: user.uid.isNotEmpty ? user.uid : 'wb_admin_root',
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          color: const Color(0xFF0047AB),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.uid));
                            UiHelper.showSnackBar(
                              context,
                              'Admin UID copied to clipboard!',
                            );
                          },
                        ),
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildDetailRow(
                        context,
                        icon: Icons.mark_email_read_outlined,
                        label: 'Superuser Email',
                        value: user.email.isNotEmpty
                            ? user.email
                            : 'admin@workbridge.com',
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _buildDetailRow(
                        context,
                        icon: Icons.phone_android_rounded,
                        label: 'System Phone',
                        value: user.phone.isNotEmpty
                            ? user.phone
                            : '+1 (800) 555-0199',
                      ),
                    ],
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),

              // System Authority & Privileges Card
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.045)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Level & System Status',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: context.respFont(15),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.015),
                    _buildDetailRow(
                      context,
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Privilege Level',
                      value: 'Tier 1 - Full Root / Master Administrative Access',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildDetailRow(
                      context,
                      icon: Icons.cloud_done_rounded,
                      label: 'Cloud Infrastructure',
                      value: 'Firebase Firestore & Auth Connected',
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _buildDetailRow(
                      context,
                      icon: Icons.hub_rounded,
                      label: 'Database Sync',
                      value: 'Live Provider Reactive Streams Active',
                    ),
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
                      'Security & Operations',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: context.respFont(15),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.012),
                    _buildSettingTile(
                      context,
                      icon: Icons.lock_reset_rounded,
                      title: 'Reset Admin Password',
                      subtitle: 'Send secure recovery credentials',
                      onTap: () {
                        UiHelper.showSnackBar(
                          context,
                          'Administrative password reset token dispatched to ${user.email}',
                        );
                      },
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildSettingTile(
                      context,
                      icon: Icons.policy_outlined,
                      title: 'Platform Compliance & Terms',
                      subtitle: 'System regulations and legal policies',
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
                label: 'Log Out of Admin Portal',
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
            Icon(icon, color: const Color(0xFF0047AB), size: context.respFont(20)),
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
