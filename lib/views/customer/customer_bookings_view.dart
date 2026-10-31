import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_currency.dart';
import '../../core/services/service_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import '../tracking/live_tracking_map_view.dart';

/// Customer Bookings Screen (View).
/// Displays live real-time booking updates, assigned Karigar details,
/// and allows customers to monitor or cancel active requests.
class CustomerBookingsView extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const CustomerBookingsView({super.key, this.onBackToDashboard});

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServiceRequestService _requestService = ServiceRequestService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelBooking(ServiceRequestModel request) async {
    final isWorking = request.isAccepted || request.isInProgress;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(
              child: Text('Cancel Service Booking', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            isWorking
                ? 'Are you sure you want to cancel your ongoing service booking for "${request.serviceTitle}"? The assigned specialist will be notified and live tracking will be closed.'
                : 'Are you sure you want to cancel your service request for "${request.serviceTitle}"?',
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _requestService.cancelCustomerRequest(
          requestId: request.id,
          customerId: request.customerId,
          reason: 'Cancelled by customer',
        );
        if (mounted) {
          UiHelper.showSnackBar(context, 'Request cancelled successfully.');
        }
      } catch (e) {
        if (mounted) {
          UiHelper.showSnackBar(context, 'Failed to cancel: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final customerId = userController.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        leading: widget.onBackToDashboard != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.card, size: 20),
                onPressed: widget.onBackToDashboard,
              )
            : null,
        title: Text(
          'My Service Bookings',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.card,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.card.withValues(alpha: 0.75),
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Active Bookings'),
            Tab(text: 'History & Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: _requestService.streamCustomerRequests(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load bookings: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final allRequests = snapshot.data ?? [];
          final activeRequests = allRequests.where((r) =>
              r.status == RequestStatus.pending ||
              r.status == RequestStatus.accepted ||
              r.status == RequestStatus.inProgress).toList();

          final pastRequests = allRequests.where((r) =>
              r.status == RequestStatus.completed ||
              r.status == RequestStatus.cancelled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(activeRequests, isActive: true),
              _buildRequestsList(pastRequests, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<ServiceRequestModel> requests, {required bool isActive}) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.calendar_today_rounded : Icons.history_rounded,
                size: 56,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                isActive ? 'No active bookings right now' : 'No past bookings yet',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? 'Explore service categories and book a verified Karigar anytime.'
                    : 'Your completed or cancelled bookings will show here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
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
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final req = requests[index];
        return _buildBookingCard(req);
      },
    );
  }

  Widget _buildBookingCard(ServiceRequestModel request) {
    final category = ServiceCategory.findByNameOrTrade(request.categoryName) ??
        ServiceCategory.findByNameOrTrade(request.categoryId);
    final accent = category?.accentColor ?? AppColors.accent;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.accepted:
        statusColor = AppColors.success;
        statusLabel = 'Karigar Confirmed';
        statusIcon = Icons.check_circle_rounded;
        break;
      case RequestStatus.inProgress:
        statusColor = const Color(0xFF0284C7);
        statusLabel = 'In Progress';
        statusIcon = Icons.autorenew_rounded;
        break;
      case RequestStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'Job Completed';
        statusIcon = Icons.task_alt_rounded;
        break;
      case RequestStatus.cancelled:
        statusColor = AppColors.error;
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_outlined;
        break;
      case RequestStatus.pending:
      default:
        statusColor = Colors.amber.shade800;
        statusLabel = request.isSpecific
            ? 'Awaiting Provider...'
            : 'Looking for Karigar...';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
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
          // Header: Category & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category?.icon ?? Icons.build_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.serviceTitle,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: request.isBroadcast
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.isBroadcast ? 'Random Karigar' : 'Specific Karigar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: request.isBroadcast ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${request.categoryName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${AppCurrency.symbol}${request.estimatedAmount.toStringAsFixed(0)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              request.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mainText,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Address & Schedule info
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.customerAddress.isNotEmpty ? request.customerAddress : 'Address not specified',
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(
                '${request.scheduledDate} ${request.scheduledTime}',
                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),

          // Karigar Details if Assigned
          if (request.assignedProviderName != null && request.assignedProviderName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      request.assignedProviderName![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.assignedProviderName!,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (request.assignedProviderPhone != null &&
                            request.assignedProviderPhone!.isNotEmpty)
                          Text(
                            request.assignedProviderPhone!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Provider Start & End Locations Display for Customer
          if (request.providerStartLocation != null || request.providerEndLocation != null) ...[
            const SizedBox(height: 10),
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
                  if (request.providerStartLocation != null)
                    Row(
                      children: [
                        const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Specialist Started From: ${request.providerStartLocation!['address'] ?? request.providerStartLocation!['city'] ?? "Recorded"}',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.mainText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (request.providerEndLocation != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.sports_score_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Specialist Completed At: ${request.providerEndLocation!['address'] ?? request.providerEndLocation!['city'] ?? "Recorded"}',
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
          ],

          // Action: Live Tracking if Accepted or In Progress
          if (request.isAccepted || request.isInProgress) ...[
            const SizedBox(height: 12),
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
                icon: const Icon(Icons.map_rounded, size: 18, color: AppColors.accent),
                label: const Text(
                  'Live Track Specialist on Map',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  LiveTrackingMapView.open(
                    context: context,
                    request: request,
                    isProviderView: false,
                  );
                },
              ),
            ),
          ],

          // Action: Cancel if pending, accepted, or in progress
          if (request.isPending || request.isAccepted || request.isInProgress) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _handleCancelBooking(request),
                icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.error),
                label: Text(
                  request.isPending ? 'Cancel Booking' : 'Cancel Service',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
