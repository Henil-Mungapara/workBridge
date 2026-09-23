import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';

/// Data representation of an administrative management module card.
class AdminDataModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String statusBadge;
  final VoidCallback? customAction;

  const AdminDataModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.statusBadge = 'Active',
    this.customAction,
  });
}

/// Professional Administrative Data Management Hub for WorkBridge.
///
/// Provides responsive grid cards for:
/// 1. 👤 Customers (Fully implemented: Add Customer dialog)
/// 2. 🧑‍🔧 Service Providers
/// 3. 📂 Categories
/// 4. 🛠 Services
/// 5. 📋 Bookings
/// 6. 💳 Payments
/// 7. ⭐ Reviews
/// 8. 🔔 Notifications
class AdminDataManagementScreen extends StatelessWidget {
  const AdminDataManagementScreen({super.key});

  List<AdminDataModule> _buildModules(BuildContext context) {
    return [
      AdminDataModule(
        id: 'customers',
        title: 'Customers',
        description: 'Manage registered customers & create new client accounts.',
        icon: Icons.people_alt_rounded,
        accentColor: const Color(0xFF0047AB),
        statusBadge: 'Add Customer Ready',
        customAction: () => UiHelper.showAddCustomerDialog(context),
      ),
      AdminDataModule(
        id: 'providers',
        title: 'Service Providers',
        description: 'Review technicians, verification badges & provider stats.',
        icon: Icons.engineering_rounded,
        accentColor: const Color(0xFF059669),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'categories',
        title: 'Categories',
        description: 'Configure service trades, categories & specializations.',
        icon: Icons.category_rounded,
        accentColor: const Color(0xFF7C3AED),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'services',
        title: 'Services',
        description: 'Manage offered services, catalogs & price ranges.',
        icon: Icons.home_repair_service_rounded,
        accentColor: const Color(0xFFEA580C),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'bookings',
        title: 'Bookings',
        description: 'Track live gig requests, allocations & completed orders.',
        icon: Icons.assignment_rounded,
        accentColor: const Color(0xFF2563EB),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'payments',
        title: 'Payments',
        description: 'Oversee platform transactions, payouts & gateway logs.',
        icon: Icons.payments_rounded,
        accentColor: const Color(0xFF0D9488),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'reviews',
        title: 'Reviews',
        description: 'Monitor customer ratings, feedback & moderation.',
        icon: Icons.star_rounded,
        accentColor: const Color(0xFFD97706),
        statusBadge: 'Next Phase',
      ),
      AdminDataModule(
        id: 'notifications',
        title: 'Notifications',
        description: 'Broadcast platform alerts, push updates & announcements.',
        icon: Icons.notifications_active_rounded,
        accentColor: const Color(0xFFE11D48),
        statusBadge: 'Next Phase',
      ),
    ];
  }

  void _onModuleTap(BuildContext context, AdminDataModule module) {
    if (module.customAction != null) {
      module.customAction!();
      return;
    }

    // Modal Bottom Sheet presenting module details and architecture readiness
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MediaQueryHelper.width(sheetCtx, 0.06),
            MediaQueryHelper.height(sheetCtx, 0.02),
            MediaQueryHelper.width(sheetCtx, 0.06),
            MediaQueryHelper.height(sheetCtx, 0.03),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: MediaQueryHelper.height(sheetCtx, 0.025)),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: module.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(module.icon, color: module.accentColor, size: 28),
                  ),
                  SizedBox(width: MediaQueryHelper.width(sheetCtx, 0.035)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: MediaQueryHelper.responsiveFont(sheetCtx, 18),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: module.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ready for Phase 2 Configuration',
                            style: AppTextStyles.caption.copyWith(
                              color: module.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: MediaQueryHelper.responsiveFont(sheetCtx, 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQueryHelper.height(sheetCtx, 0.02)),

              // Description
              Text(
                module.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mainText,
                  fontSize: MediaQueryHelper.responsiveFont(sheetCtx, 14),
                  height: 1.45,
                ),
              ),
              SizedBox(height: MediaQueryHelper.height(sheetCtx, 0.015)),

              // Architecture Context
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.secondaryText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This management module is structured and will be fully wired with database schema and filters in the upcoming implementation step.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: MediaQueryHelper.responsiveFont(sheetCtx, 11.5),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQueryHelper.height(sheetCtx, 0.025)),

              // Close / OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQueryHelper.height(sheetCtx, 0.014),
                    ),
                  ),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: Text(
                    'Understood',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.card,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = _buildModules(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.card, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Data Management',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.card,
                fontSize: MediaQueryHelper.responsiveFont(context, 16.5),
              ),
            ),
            Text(
              'WorkBridge Administration Hub',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.card.withValues(alpha: 0.75),
                fontSize: MediaQueryHelper.responsiveFont(context, 11),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.card),
            tooltip: 'Add Customer',
            onPressed: () => UiHelper.showAddCustomerDialog(context),
          ),
          UiHelper.horizontalSpace(context, 0.015),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQueryHelper.width(context, 0.045),
            vertical: MediaQueryHelper.height(context, 0.018),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(MediaQueryHelper.width(context, 0.045)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002B49), Color(0xFF0047AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047AB).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, size: 14, color: AppColors.card),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Data Management Console',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.card,
                                      fontWeight: FontWeight.w700,
                                      fontSize: MediaQueryHelper.responsiveFont(context, 11),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '8 Modules',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.card,
                              fontWeight: FontWeight.w800,
                              fontSize: MediaQueryHelper.responsiveFont(context, 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    UiHelper.verticalSpace(context, 0.015),
                    Text(
                      'Platform Management Hub',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.card,
                        fontWeight: FontWeight.w800,
                        fontSize: MediaQueryHelper.responsiveFont(context, 18),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.006),
                    Text(
                      'Manage registered accounts, platform catalogs, transactions, and service dispatch operations.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.card.withValues(alpha: 0.85),
                        fontSize: MediaQueryHelper.responsiveFont(context, 12),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.025),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Administrative Modules',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: MediaQueryHelper.responsiveFont(context, 16),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap card to operate',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: MediaQueryHelper.responsiveFont(context, 11),
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.015),

              // Responsive 2-Column Module Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.84,
                    ),
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return _buildModuleCard(context, module);
                    },
                  );
                },
              ),

              UiHelper.verticalSpace(context, 0.025),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, AdminDataModule module) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onModuleTap(context, module),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: module.accentColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon Container + Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: module.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        module.icon,
                        color: module.accentColor,
                        size: 24,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.secondaryText.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const Spacer(),

                // Title
                Text(
                  module.title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: MediaQueryHelper.responsiveFont(context, 14.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  module.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: MediaQueryHelper.responsiveFont(context, 11),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: module.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: module.accentColor.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: module.accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          module.statusBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: module.accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
