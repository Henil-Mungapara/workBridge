import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/service_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import 'create_booking_modal.dart';
import 'customer_bookings_view.dart';

/// Customer Dashboard Screen (View).
/// Features live metrics from Firestore, dual-mode Karigar dispatch
/// (Random Karigar vs Specific Karigar), and real-time active bookings tracking.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;
  final ServiceRequestService _requestService = ServiceRequestService();

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final String displayName = userController.userName.isNotEmpty
        ? userController.userName
        : 'Valued Customer';
    final String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W';

    // If "Bookings" tab is selected, render CustomerBookingsView directly
    if (_currentIndex == 2) {
      return CustomerBookingsView(
        onBackToDashboard: () => setState(() => _currentIndex = 0),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.profile);
              },
              child: CircleAvatar(
                radius: context.widthPct(0.048),
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.card,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            UiHelper.horizontalSpace(context, 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                      fontSize: context.respFont(11),
                    ),
                  ),
                  Text(
                    displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: context.respFont(15.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {
              UiHelper.showSnackBar(context, 'No new notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          UiHelper.horizontalSpace(context, 0.015),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.widthPct(0.045),
            vertical: context.heightPct(0.018),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Banner
              Container(
                width: context.widthPct(0.91),
                padding: EdgeInsets.all(context.widthPct(0.045)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.widthPct(0.025),
                            vertical: context.heightPct(0.005),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            userController.role.replaceAll('_', ' ').toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              fontSize: context.respFont(10.5),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.accent,
                          size: context.respFont(18),
                        ),
                      ],
                    ),
                    UiHelper.verticalSpace(context, 0.015),
                    Text(
                      'Ready to bridge opportunities, $displayName?',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.card,
                        fontWeight: FontWeight.w700,
                        fontSize: context.respFont(18),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.006),
                    Text(
                      'Hire verified Karigars quickly with on-demand service dispatch.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.card.withValues(alpha: 0.85),
                        fontSize: context.respFont(12),
                      ),
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.025),

              // Live Dynamic Metrics Stream
              StreamBuilder<List<ServiceRequestModel>>(
                stream: _requestService.streamCustomerRequests(userController.uid),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];
                  final activeRequests = requests.where((r) =>
                      r.status == RequestStatus.pending ||
                      r.status == RequestStatus.accepted ||
                      r.status == RequestStatus.inProgress).toList();
                  final completedRequests = requests.where((r) =>
                      r.status == RequestStatus.completed).toList();
                  final totalSpent = completedRequests.fold<double>(
                      0.0, (sum, r) => sum + r.estimatedAmount);

                  return Column(
                    children: [
                      // Metrics Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Active Bookings',
                              value: '${activeRequests.length}',
                              icon: Icons.calendar_today_rounded,
                              iconColor: AppColors.accent,
                              onTap: () {
                                setState(() => _currentIndex = 2);
                              },
                            ),
                          ),
                          UiHelper.horizontalSpace(context, 0.03),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Spent',
                              value: '${AppCurrency.symbol}${totalSpent.toStringAsFixed(0)}',
                              icon: AppCurrency.icon,
                              iconColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      UiHelper.verticalSpace(context, 0.015),

                      // Metrics Row 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Completed',
                              value: '${completedRequests.length}',
                              icon: Icons.task_alt_rounded,
                              iconColor: Colors.amber.shade700,
                              onTap: () {
                                setState(() => _currentIndex = 2);
                              },
                            ),
                          ),
                          UiHelper.horizontalSpace(context, 0.03),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'User Rating',
                              value: '4.9 ★',
                              icon: Icons.star_rounded,
                              iconColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              UiHelper.verticalSpace(context, 0.025),

              // Service Categories Header with View All Option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Service Categories',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: context.respFont(16),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap any service to request Random or Specific Karigar',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: context.respFont(11),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showAllCategoriesModal(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: context.respFont(11.5),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: context.respFont(10),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.015),

              // Categories Grid (All 8 Categories)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ServiceCategory.all8Categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) {
                  return _buildCategoryItem(
                    context,
                    ServiceCategory.all8Categories[index],
                  );
                },
              ),

              UiHelper.verticalSpace(context, 0.025),

              // Profile Shortcut Card
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.04)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.widthPct(0.025)),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    UiHelper.horizontalSpace(context, 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: context.respFont(14),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userController.email.isNotEmpty
                                ? userController.email
                                : 'Manage info, verify security & view UID',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: context.respFont(11.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.profile);
                      },
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.profile);
          } else if (index == 1) {
            _showAllCategoriesModal(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.secondaryText,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(context.widthPct(0.04)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: context.respFont(11.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                UiHelper.horizontalSpace(context, 0.015),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: context.respFont(16)),
                ),
              ],
            ),
            UiHelper.verticalSpace(context, 0.01),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontSize: context.respFont(19),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, ServiceCategory category) {
    return InkWell(
      onTap: () {
        CreateBookingModal.show(
          context: context,
          category: category,
          onBookingCreated: () {
            setState(() => _currentIndex = 2);
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.widthPct(0.16),
            height: context.widthPct(0.16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                category.icon,
                color: category.accentColor,
                size: context.respFont(23),
              ),
            ),
          ),
          UiHelper.verticalSpace(context, 0.006),
          SizedBox(
            width: context.widthPct(0.2),
            child: Text(
              category.name,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
                fontSize: context.respFont(10.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllCategoriesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Service Categories',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '8 categories available for instant booking',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ServiceCategory.all8Categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = ServiceCategory.all8Categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cat.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.accentColor, size: 24),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Instant Book',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          cat.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondaryText),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        CreateBookingModal.show(
                          context: context,
                          category: cat,
                          onBookingCreated: () {
                            setState(() => _currentIndex = 2);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
