import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/live_tracking_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/service_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../tracking/live_tracking_map_view.dart';

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
  String _selectedRequestsFilter = 'all';

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
    // 1. Mandatory Location Permission Enforcement for Provider
    final hasLocation = await LocationService().checkAndEnforceLocationPermission(
      context: context,
      roleTitle: 'Service Provider',
      actionReason: 'accept this gig, capture your starting location, and provide live customer tracking',
    );

    if (!hasLocation) {
      if (mounted) {
        UiHelper.showSnackBar(
          context,
          'Location Required: Please turn on device location to accept service requests.',
          isError: true,
        );
      }
      return;
    }

    // 2. Capture Starting Location
    AppLocationData startLocation;
    try {
      startLocation = await LocationService().getCurrentLocation();
    } catch (_) {
      startLocation = AppLocationData(
        latitude: LocationService.defaultLat,
        longitude: LocationService.defaultLng,
        address: 'Gondal Bypass, Gondal, Gujarat',
        city: 'Gondal',
        timestamp: DateTime.now(),
      );
    }

    try {
      final success = await _requestService.acceptRequest(
        requestId: request.id,
        provider: provider,
        providerStartLocation: startLocation,
      );
      if (success && mounted) {
        UiHelper.showSnackBar(
          context,
          'Accepted service gig for ${request.customerName}! Starting location recorded in Firestore & Realtime DB 🎉',
        );

        final openMap = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.navigation_rounded, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start Route & Tracking?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Job accepted! Customer is at ${request.customerCity ?? "Gondal"} (${request.customerAddress}).\n\n'
                'Would you like to open the live navigation map now to begin route tracking?',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ),
            actionsOverflowButtonSpacing: 8,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Later in My Gigs'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Open Live Map'),
              ),
            ],
          ),
        );

        if (openMap == true && mounted) {
          LiveTrackingMapView.open(
            context: context,
            request: request.copyWith(
              assignedProviderId: provider.uid,
              assignedProviderName: provider.name,
              assignedProviderPhone: provider.phone,
              providerStartLocation: startLocation.toMap(),
              trackingStatus: TrackingState.enRoute,
            ),
            isProviderView: true,
          );
        }
        if (mounted) {
          setState(() => _currentIndex = 1);
        }
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
                Expanded(
                  child: Text('Request Unavailable', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                e.toString().replaceAll('Exception:', '').trim(),
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
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
            Expanded(
              child: Text('Cancel Accepted Gig', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
        ),
        actionsOverflowButtonSpacing: 8,
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

  Future<void> _handleMarkArrived(ServiceRequestModel gig) async {
    try {
      await _requestService.markProviderArrived(requestId: gig.id);
      if (mounted) {
        UiHelper.showSnackBar(
          context,
          'Status set to "Arrived"! Client has been notified you are outside 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(context, 'Error updating arrival status: $e', isError: true);
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
            Expanded(
              child: Text('Complete Service Gig', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Confirm completion of work for ${gig.customerName}? This will add ${AppCurrency.symbol}${gig.estimatedAmount.toStringAsFixed(0)} to your total earnings.',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
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
        AppLocationData endLocation;
        try {
          endLocation = await LocationService().getCurrentLocation();
        } catch (_) {
          endLocation = AppLocationData(
            latitude: LocationService.defaultLat,
            longitude: LocationService.defaultLng,
            address: LocationService.defaultAddress,
            city: LocationService.defaultCity,
            timestamp: DateTime.now(),
          );
        }
        await _requestService.updateJobStatus(
          requestId: gig.id,
          status: RequestStatus.completed,
          providerEndLocation: endLocation,
        );
        if (mounted) {
          UiHelper.showSnackBar(
            context,
            'Gig completed! Final location recorded at ${endLocation.city}. ${AppCurrency.symbol}${gig.estimatedAmount.toStringAsFixed(0)} credited to earnings 🎉',
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
      final hasLocation = await LocationService().checkAndEnforceLocationPermission(
        context: context,
        roleTitle: 'Service Provider',
        actionReason: 'start your trip, enable live customer tracking, and update arrival status',
      );
      if (!hasLocation) return;

      AppLocationData startLoc;
      if (gig.providerStartLocation == null) {
        try {
          startLoc = await LocationService().getCurrentLocation();
        } catch (_) {
          startLoc = AppLocationData(
            latitude: LocationService.defaultLat,
            longitude: LocationService.defaultLng,
            address: LocationService.defaultAddress,
            city: LocationService.defaultCity,
            timestamp: DateTime.now(),
          );
        }
      } else {
        startLoc = AppLocationData.fromMap(gig.providerStartLocation!);
      }

      await _requestService.updateJobStatus(
        requestId: gig.id,
        status: RequestStatus.inProgress,
        providerStartLocation: gig.providerStartLocation == null ? startLoc : null,
      );

      await LiveTrackingService().updateProviderLocation(
        requestId: gig.id,
        newLocation: startLoc,
        status: TrackingState.enRoute,
      );

      if (mounted) {
        UiHelper.showSnackBar(
          context,
          'Trip started! Status set to "I Am Coming". Customer is now live-tracking you.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(context, 'Error starting trip: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final user = userController.user;
    String effectiveUid = user.uid;
    if (effectiveUid.isEmpty) {
      try {
        effectiveUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      } catch (_) {}
    }
    final effectiveUser = (user.uid.isEmpty && effectiveUid.isNotEmpty)
        ? user.copyWith(uid: effectiveUid)
        : user;

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
        backgroundColor: AppColors.primary,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.providerProfile);
              },
              child: CircleAvatar(
                radius: context.widthPct(0.048),
                backgroundColor: AppColors.card,
                child: Text(
                  initialLetter,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
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
                      color: AppColors.card.withValues(alpha: 0.75),
                      fontSize: context.respFont(11),
                    ),
                  ),
                  Text(
                    displayName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.card,
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
              color: AppColors.card.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: _isOnline ? AppColors.success : AppColors.card.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor:
                      _isOnline ? AppColors.success : AppColors.card.withValues(alpha: 0.6),
                ),
                UiHelper.horizontalSpace(context, 0.015),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color:
                        _isOnline ? AppColors.success : AppColors.card.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: context.respFont(11),
                  ),
                ),
                Switch(
                  value: _isOnline,
                  activeTrackColor: AppColors.success,
                  onChanged: (val) => _handleToggleOnline(val, effectiveUser.uid),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.card),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.providerProfile);
            },
          ),
          UiHelper.horizontalSpace(context, 0.015),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 1
            ? _buildActiveGigsTab(effectiveUser)
            : _currentIndex == 2
                ? _buildRequestsTab(effectiveUser, rawAssigned)
                : _buildDashboardHome(effectiveUser, displayName, assignedCategories, rawAssigned),
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
                      if (activeJobs.isNotEmpty) ...[
                        InkWell(
                          onTap: () => setState(() => _currentIndex = 1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.15),
                                  AppColors.accent.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Job In Progress',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${activeJobs.length} active service ongoing. Tap to manage & track live.',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Browse Incoming Requests'),
                    onPressed: () => setState(() => _currentIndex = 2),
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
          const SizedBox(height: 10),

          // Start & End Location Trail Display
          if (gig.providerStartLocation != null || gig.providerEndLocation != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (gig.providerStartLocation != null)
                    Row(
                      children: [
                        const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Start Location: ${gig.providerStartLocation!['address'] ?? gig.providerStartLocation!['city'] ?? "Recorded"}',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.mainText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (gig.providerEndLocation != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.sports_score_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'End Location: ${gig.providerEndLocation!['address'] ?? gig.providerEndLocation!['city'] ?? "Recorded"}',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Live Route & Map Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 16, color: AppColors.accent),
              label: const Text(
                'Live Route & Tracking Map',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                LiveTrackingMapView.open(
                  context: context,
                  request: gig,
                  isProviderView: true,
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Dynamic Tracking Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gig.trackingStatus == TrackingState.arrived
                  ? AppColors.success.withValues(alpha: 0.15)
                  : gig.trackingStatus == TrackingState.enRoute
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: gig.trackingStatus == TrackingState.arrived
                    ? AppColors.success.withValues(alpha: 0.4)
                    : gig.trackingStatus == TrackingState.enRoute
                        ? AppColors.warning.withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  gig.trackingStatus == TrackingState.arrived
                      ? Icons.pin_drop_rounded
                      : gig.trackingStatus == TrackingState.enRoute
                          ? Icons.navigation_rounded
                          : Icons.check_circle_outline_rounded,
                  size: 13,
                  color: gig.trackingStatus == TrackingState.arrived
                      ? AppColors.success
                      : gig.trackingStatus == TrackingState.enRoute
                          ? AppColors.warning
                          : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  gig.trackingStatus == TrackingState.arrived
                      ? 'Status: Arrived at Client Location'
                      : gig.trackingStatus == TrackingState.enRoute
                          ? 'Status: En Route (I Am Coming)'
                          : 'Status: Accepted (Ready to Start)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: gig.trackingStatus == TrackingState.arrived
                        ? AppColors.success
                        : gig.trackingStatus == TrackingState.enRoute
                            ? AppColors.warning
                            : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Actions Row with Wrap to prevent screen overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
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
              if (!isInProgress)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleStartJob(gig),
                  icon: const Icon(Icons.directions_run_rounded, size: 16),
                  label: const Text('I Am Coming'),
                )
              else if (gig.trackingStatus == TrackingState.enRoute) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleMarkArrived(gig),
                  icon: const Icon(Icons.pin_drop_rounded, size: 16),
                  label: const Text('I Have Arrived'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleCompleteGig(gig),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Done'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleCompleteGig(gig),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Done (Complete Gig)'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Incoming Requests Full Tab ──────────────────────────────────────

  Widget _buildRequestsTab(UserModel user, List<String> rawAssigned) {
    final bool isAll = _selectedRequestsFilter == 'all';
    final bool isSpecialty = _selectedRequestsFilter == 'specialty';

    return Column(
      children: [
        // Tab Header & Category Filter Bar
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.widthPct(0.045),
            vertical: context.heightPct(0.015),
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Requests',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: context.respFont(16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse and accept real-time service requests',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: context.respFont(11),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3.5,
                          backgroundColor: _isOnline ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: context.respFont(10.5),
                            fontWeight: FontWeight.w700,
                            color: _isOnline ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRequestsFilterChip(
                      label: 'All Requests',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: isAll,
                      onTap: () => setState(() => _selectedRequestsFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildRequestsFilterChip(
                      label: 'My Specialties',
                      icon: Icons.star_rounded,
                      isSelected: isSpecialty,
                      onTap: () => setState(() => _selectedRequestsFilter = 'specialty'),
                    ),
                    ...ServiceCategory.all8Categories.map((cat) {
                      final isSelected = _selectedRequestsFilter == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _buildRequestsFilterChip(
                          label: cat.name,
                          icon: cat.icon,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedRequestsFilter = cat.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Live Requests Feed
        Expanded(
          child: _buildLiveIncomingRequestsStream(
            user,
            rawAssigned,
            isFullTab: true,
            showAllOpenRequests: isAll,
            filterCategoryId: (!isAll && !isSpecialty) ? _selectedRequestsFilter : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.secondaryText,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.mainText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIncomingRequestsStream(
    UserModel user,
    List<String> rawAssigned, {
    int? limit,
    bool isFullTab = false,
    bool showAllOpenRequests = false,
    String? filterCategoryId,
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

    final bool effectiveShowAll = showAllOpenRequests || (!isFullTab && user.categories.isEmpty);

    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamProviderIncomingRequests(
        providerId: user.uid,
        providerCategories: rawAssigned,
        isOnline: _isOnline,
        showAllOpenRequests: effectiveShowAll,
        filterCategoryId: filterCategoryId,
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
                const SizedBox(height: 4),
                Text(
                  isFullTab && !effectiveShowAll
                      ? 'No pending requests in this filter. Switch to "All Requests" to see all open gigs.'
                      : 'No pending requests right now. Keep yourself online for new incoming gigs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                ),
                if (isFullTab && !effectiveShowAll) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Show All Requests'),
                    onPressed: () {
                      setState(() => _selectedRequestsFilter = 'all');
                    },
                  ),
                ],
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
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isBroadcast ? 'Random Karigar' : 'Direct Request to You',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.isBroadcast ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.categoryName.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.categoryName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.person_pin_rounded, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.customerName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          UiHelper.verticalSpace(context, 0.008),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.fmd_good_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location: ${item.customerCity != null && item.customerCity!.isNotEmpty ? item.customerCity! : "Gondal"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        item.customerAddress,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    LiveTrackingMapView.open(
                      context: context,
                      request: item,
                      isProviderView: true,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 14, color: AppColors.accentDark),
                        SizedBox(width: 4),
                        Text(
                          'Map',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.scheduledDate.isNotEmpty || item.scheduledTime.isNotEmpty) ...[
            UiHelper.verticalSpace(context, 0.006),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text(
                  'Scheduled: ${item.scheduledDate} • ${item.scheduledTime}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
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
