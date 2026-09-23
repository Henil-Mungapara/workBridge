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
import '../../models/user_model.dart';

/// Service Provider Dashboard Screen (View).
/// Features real-time Firestore synchronization, atomic concurrency handling
/// (5-provider race condition prevention), live incoming requests feed,
/// and re-opening of jobs upon provider cancellation.
class ProviderDashboardView extends StatefulWidget {
  const ProviderDashboardView({super.key});

  @override
  State<ProviderDashboardView> createState() => _ProviderDashboardViewState();
}

class _ProviderDashboardViewState extends State<ProviderDashboardView> {
  int _currentIndex = 0;
  bool _isOnline = true;
  final ServiceRequestService _requestService = ServiceRequestService();

  Future<void> _handleToggleOnline(bool val, String providerId) async {
    setState(() => _isOnline = val);
    await _requestService.updateProviderOnlineStatus(
      providerId: providerId,
      isOnline: val,
    );
    if (mounted) {
      UiHelper.showSnackBar(
        context,
        val
            ? 'You are now Online & receiving job alerts'
            : 'You are now Offline. Incoming alerts paused.',
      );
    }
  }

  Future<void> _handleAcceptRequest(ServiceRequestModel request, UserModel provider) async {
    try {
      final success = await _requestService.acceptRequest(
        requestId: request.id,
        provider: provider,
      );
      if (success && mounted) {
        UiHelper.showSnackBar(
          context,
          'Accepted service gig for ${request.customerName}! View in My Gigs 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Request Unavailable', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception:', '').trim(),
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineRequest(ServiceRequestModel request, String providerId) async {
    try {
      await _requestService.declineRequest(
        requestId: request.id,
        providerId: providerId,
      );
      if (mounted) {
        UiHelper.showSnackBar(context, 'Declined job request for ${request.customerName}');
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(context, 'Error declining: $e', isError: true);
      }
    }
  }

  Future<void> _handleCancelAcceptedGig(ServiceRequestModel gig, String providerId) async {
    final reasonController = TextEditingController(text: 'Scheduling conflict / Emergency');

    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Cancel Accepted Gig', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancelling this gig will automatically re-open it so other verified Karigars in this category can accept it.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Gig'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      try {
        await _requestService.cancelAcceptedJob(
          requestId: gig.id,
          providerId: providerId,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          UiHelper.showSnackBar(
            context,
            'Gig cancelled. It has been re-opened for other available Karigars.',
          );
        }
      } catch (e) {
        if (mounted) {
          UiHelper.showSnackBar(context, 'Failed to cancel gig: $e', isError: true);
        }
      }
    }
  }

  Future<void> _handleCompleteGig(ServiceRequestModel gig) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Complete Service Gig', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Confirm completion of work for ${gig.customerName}? This will add ${AppCurrency.symbol}${gig.estimatedAmount.toStringAsFixed(0)} to your total earnings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _requestService.updateJobStatus(
          requestId: gig.id,
          status: RequestStatus.completed,
        );
        if (mounted) {
          UiHelper.showSnackBar(
            context,
            'Gig completed! ${AppCurrency.symbol}${gig.estimatedAmount.toStringAsFixed(0)} credited to earnings 🎉',
          );
        }
      } catch (e) {
        if (mounted) {
          UiHelper.showSnackBar(context, 'Error completing gig: $e', isError: true);
        }
      }
    }
  }

  Future<void> _handleStartJob(ServiceRequestModel gig) async {
    try {
      await _requestService.updateJobStatus(
        requestId: gig.id,
        status: RequestStatus.inProgress,
      );
      if (mounted) {
        UiHelper.showSnackBar(context, 'Job marked as In Progress');
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final user = userController.user;
    final String displayName =
        userController.userName.isNotEmpty ? userController.userName : 'Service Provider';
    final String initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';
    final List<String> rawAssigned = userController.userCategories.isNotEmpty
        ? userController.userCategories
        : const ['Electrical'];
    final assignedCategories = ServiceCategory.filterAssigned(rawAssigned);

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
                Navigator.of(context).pushNamed(AppRoutes.providerProfile);
              },
              child: CircleAvatar(
                radius: context.widthPct(0.048),
                backgroundColor: AppColors.accent,
                child: Text(
                  initialLetter,
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
                    'Provider Portal',
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
          // Online / Offline Status Toggle
          Container(
            margin: EdgeInsets.symmetric(vertical: context.heightPct(0.012)),
            padding: EdgeInsets.symmetric(
              horizontal: context.widthPct(0.025),
            ),
            decoration: BoxDecoration(
              color: _isOnline
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.secondaryText.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: _isOnline ? AppColors.success : AppColors.secondaryText,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor:
                      _isOnline ? AppColors.success : AppColors.secondaryText,
                ),
                UiHelper.horizontalSpace(context, 0.015),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color:
                        _isOnline ? AppColors.success : AppColors.secondaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: context.respFont(11),
                  ),
                ),
                Switch(
                  value: _isOnline,
                  activeTrackColor: AppColors.success,
                  onChanged: (val) => _handleToggleOnline(val, user.uid),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.providerProfile);
            },
          ),
          UiHelper.horizontalSpace(context, 0.015),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 1
            ? _buildActiveGigsTab(user)
            : _currentIndex == 2
                ? _buildRequestsTab(user, rawAssigned)
                : _buildDashboardHome(user, displayName, assignedCategories, rawAssigned),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.providerProfile);
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
            icon: Icon(Icons.handyman_rounded),
            label: 'My Gigs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Dashboard Home ──────────────────────────────────────────────────

  Widget _buildDashboardHome(
    UserModel user,
    String displayName,
    List<ServiceCategory> assignedCategories,
    List<String> rawAssigned,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPct(0.045),
        vertical: context.heightPct(0.018),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Hero Card
          Container(
            width: context.widthPct(0.91),
            padding: EdgeInsets.all(context.widthPct(0.045)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.widthPct(0.025),
                        vertical: context.heightPct(0.005),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        'SERVICE PROVIDER',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontSize: context.respFont(10.5),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '4.92 ★ (Verified)',
                          style: TextStyle(
                            color: AppColors.card,
                            fontWeight: FontWeight.w600,
                            fontSize: context.respFont(11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                UiHelper.verticalSpace(context, 0.015),
                Text(
                  'Welcome, $displayName',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.card,
                    fontWeight: FontWeight.w700,
                    fontSize: context.respFont(18),
                  ),
                ),
                UiHelper.verticalSpace(context, 0.006),
                Text(
                  _isOnline
                      ? 'You are active and receiving service gig alerts in real-time.'
                      : 'You are offline. Switch toggle to receive new client bookings.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.card.withValues(alpha: 0.8),
                    fontSize: context.respFont(12),
                  ),
                ),
              ],
            ),
          ),

          UiHelper.verticalSpace(context, 0.025),

          // Dynamic KPI Metric Cards backed by Firestore
          StreamBuilder<List<ServiceRequestModel>>(
            stream: _requestService.streamProviderActiveJobs(user.uid),
            builder: (context, activeSnapshot) {
              final activeJobs = activeSnapshot.data ?? [];

              return StreamBuilder<List<ServiceRequestModel>>(
                stream: _requestService.streamProviderCompletedJobs(user.uid),
                builder: (context, completedSnapshot) {
                  final completedJobs = completedSnapshot.data ?? [];
                  final totalEarnings = completedJobs.fold<double>(
                      0.0, (sum, j) => sum + j.estimatedAmount);

                  return Column(
                    children: [
                      // KPI Metric Cards - Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              title: 'Active Gigs',
                              value: '${activeJobs.length} Ongoing',
                              icon: Icons.assignment_turned_in_rounded,
                              iconColor: AppColors.accent,
                              onTap: () {
                                setState(() => _currentIndex = 1);
                              },
                            ),
                          ),
                          UiHelper.horizontalSpace(context, 0.03),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              title: 'Total Earnings',
                              value: '${AppCurrency.symbol}${totalEarnings.toStringAsFixed(0)}',
                              icon: AppCurrency.icon,
                              iconColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      UiHelper.verticalSpace(context, 0.015),

                      // KPI Metric Cards - Row 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              title: 'Completed Jobs',
                              value: '${completedJobs.length} Tasks',
                              icon: Icons.check_circle_rounded,
                              iconColor: Colors.blue.shade700,
                            ),
                          ),
                          UiHelper.horizontalSpace(context, 0.03),
                          Expanded(
                            child: _buildKpiCard(
                              context,
                              title: 'Acceptance Rate',
                              value: '98.5%',
                              icon: Icons.trending_up_rounded,
                              iconColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),

          UiHelper.verticalSpace(context, 0.025),

          // My Assigned Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Assigned Categories',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: context.respFont(15.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${assignedCategories.length} Active',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: context.respFont(11),
                  ),
                ),
              ),
            ],
          ),

          UiHelper.verticalSpace(context, 0.012),

          if (assignedCategories.isEmpty)
            Container(
              width: context.widthPct(0.91),
              padding: EdgeInsets.all(context.widthPct(0.04)),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No specific category assigned. You will receive all open broadcast requests.',
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignedCategories.length,
              separatorBuilder: (_, __) => UiHelper.verticalSpace(context, 0.01),
              itemBuilder: (context, index) {
                final cat = assignedCategories[index];
                return Container(
                  padding: EdgeInsets.all(context.widthPct(0.035)),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cat.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.accentColor, size: 24),
                      ),
                      UiHelper.horizontalSpace(context, 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: context.respFont(14),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 11, color: AppColors.success),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: context.respFont(10),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            UiHelper.verticalSpace(context, 0.003),
                            Text(
                              cat.description,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: context.respFont(11),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          UiHelper.verticalSpace(context, 0.025),

          // Incoming Service Requests Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Incoming Job Requests',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: context.respFont(15.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              ),
            ],
          ),

          UiHelper.verticalSpace(context, 0.01),

          // Live Incoming Requests Stream (Limit to first 3 in dashboard home)
          _buildLiveIncomingRequestsStream(user, rawAssigned, limit: 3),

          UiHelper.verticalSpace(context, 0.025),

          // Profile Shortcut Banner
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
                    Icons.badge_rounded,
                    color: AppColors.accent,
                  ),
                ),
                UiHelper.horizontalSpace(context, 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider Profile & Verification',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: context.respFont(14),
                        ),
                      ),
                      Text(
                        'Edit your trade categories, phone & credentials',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: context.respFont(11.5),
                        ),
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
                    Navigator.of(context).pushNamed(AppRoutes.providerProfile);
                  },
                ),
              ],
            ),
          ),

          UiHelper.verticalSpace(context, 0.02),
        ],
      ),
    );
  }

  // ── Tab 1: My Active Gigs Tab ──────────────────────────────────────────────

  Widget _buildActiveGigsTab(UserModel user) {
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamProviderActiveJobs(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        final gigs = snapshot.data ?? [];

        if (gigs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handyman_outlined, size: 56, color: AppColors.secondaryText),
                  const SizedBox(height: 16),
                  Text(
                    'No active gigs right now',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Accept incoming client requests to start working on new gigs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: context.widthPct(0.045),
            vertical: context.heightPct(0.02),
          ),
          itemCount: gigs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final gig = gigs[index];
            return _buildActiveGigCard(gig, user.uid);
          },
        );
      },
    );
  }

  Widget _buildActiveGigCard(ServiceRequestModel gig, String providerId) {
    final bool isInProgress = gig.status == RequestStatus.inProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isInProgress ? AppColors.accent : AppColors.border),
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
                  gig.serviceTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${AppCurrency.symbol}${gig.estimatedAmount.toStringAsFixed(0)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Client: ${gig.customerName} • ${gig.customerPhone}',
            style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gig.customerAddress,
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (gig.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              gig.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.mainText),
            ),
          ],
          const SizedBox(height: 14),

          // Actions Row
          Row(
            children: [
              // Cancel Gig (re-opens for other providers!)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _handleCancelAcceptedGig(gig, providerId),
                child: const Text('Cancel Gig'),
              ),
              const Spacer(),
              if (!isInProgress)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleStartJob(gig),
                  child: const Text('Start Work'),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleCompleteGig(gig),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Complete Gig'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Incoming Requests Full Tab ──────────────────────────────────────

  Widget _buildRequestsTab(UserModel user, List<String> rawAssigned) {
    return _buildLiveIncomingRequestsStream(user, rawAssigned, isFullTab: true);
  }

  Widget _buildLiveIncomingRequestsStream(
    UserModel user,
    List<String> rawAssigned, {
    int? limit,
    bool isFullTab = false,
  }) {
    if (!_isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.secondaryText, size: 36),
            const SizedBox(height: 8),
            const Text(
              'You are currently Offline',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Switch your status to Online using the header toggle to see incoming gigs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamProviderIncomingRequests(
        providerId: user.uid,
        providerCategories: rawAssigned,
        isOnline: _isOnline,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: AppColors.accent),
          ));
        }

        final requests = snapshot.data ?? [];
        final displayList = (limit != null && requests.length > limit)
            ? requests.take(limit).toList()
            : requests;

        if (displayList.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.done_all_rounded, color: AppColors.success, size: context.respFont(36)),
                UiHelper.verticalSpace(context, 0.01),
                Text(
                  'All caught up!',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'No pending requests right now. Keep yourself online for new incoming gigs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: !isFullTab,
          physics: isFullTab ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          padding: isFullTab ? const EdgeInsets.all(16) : EdgeInsets.zero,
          itemCount: displayList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = displayList[index];
            return _buildIncomingRequestCard(item, user);
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestCard(ServiceRequestModel item, UserModel provider) {
    return Container(
      padding: EdgeInsets.all(context.widthPct(0.04)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.serviceTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: context.respFont(14),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppCurrency.symbol}${item.estimatedAmount.toStringAsFixed(0)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  fontSize: context.respFont(15),
                ),
              ),
            ],
          ),
          UiHelper.verticalSpace(context, 0.006),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isBroadcast
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isBroadcast ? 'Random Karigar' : 'Direct Request to You',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.isBroadcast ? AppColors.accent : Colors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person_pin_rounded, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(
                item.customerName,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          UiHelper.verticalSpace(context, 0.006),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.customerAddress,
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            UiHelper.verticalSpace(context, 0.006),
            Text(
              item.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.mainText),
            ),
          ],
          UiHelper.verticalSpace(context, 0.012),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleDeclineRequest(item, provider.uid),
                  child: const Text('Decline'),
                ),
              ),
              UiHelper.horizontalSpace(context, 0.03),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleAcceptRequest(item, provider),
                  child: const Text('Accept Gig'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
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
                fontSize: context.respFont(18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
