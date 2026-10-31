import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/live_tracking_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/service_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_query_helper.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/service_request_model.dart';

/// Full-featured interactive map view rendering live technician dispatch,
/// route polylines, start/end markers, and real-time movement streaming.
class LiveTrackingMapView extends StatefulWidget {
  final ServiceRequestModel request;
  final bool isProviderView;

  const LiveTrackingMapView({
    super.key,
    required this.request,
    this.isProviderView = false,
  });

  static Future<void> open({
    required BuildContext context,
    required ServiceRequestModel request,
    bool isProviderView = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTrackingMapView(
          request: request,
          isProviderView: isProviderView,
        ),
      ),
    );
  }

  @override
  State<LiveTrackingMapView> createState() => _LiveTrackingMapViewState();
}

class _LiveTrackingMapViewState extends State<LiveTrackingMapView> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LiveTrackingService _trackingService = LiveTrackingService();
  late AnimationController _pulseController;

  LiveTrackingData? _currentTracking;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initTracking() {
    // Initial fallback data from the request model
    final cLat = widget.request.customerLatitude ?? LocationService.defaultLat;
    final cLng = widget.request.customerLongitude ?? LocationService.defaultLng;
    final cCity = widget.request.customerCity ?? LocationService.defaultCity;
    final cAddr = widget.request.customerAddress;

    final pStartMap = widget.request.providerStartLocation;
    final pCurMap = widget.request.providerCurrentLocation ?? pStartMap;

    final pLat = pCurMap != null ? (pCurMap['latitude'] as num?)?.toDouble() ?? (cLat - 0.012) : (cLat - 0.012);
    final pLng = pCurMap != null ? (pCurMap['longitude'] as num?)?.toDouble() ?? (cLng - 0.012) : (cLng - 0.012);

    final customerLocation = AppLocationData(
      latitude: cLat,
      longitude: cLng,
      address: cAddr,
      city: cCity,
      timestamp: DateTime.now(),
    );

    final providerLocation = AppLocationData(
      latitude: pLat,
      longitude: pLng,
      address: pCurMap?['address'] as String? ?? 'Gondal En-Route',
      city: cCity,
      timestamp: DateTime.now(),
    );

    final locService = LocationService();
    _currentTracking = LiveTrackingData(
      requestId: widget.request.id,
      providerId: widget.request.assignedProviderId ?? '',
      providerName: widget.request.assignedProviderName ?? 'Service Provider',
      providerPhone: widget.request.assignedProviderPhone ?? '',
      customerId: widget.request.customerId,
      customerName: widget.request.customerName,
      customerLocation: customerLocation,
      providerLocation: providerLocation,
      status: widget.request.trackingStatus ?? TrackingState.enRoute,
      distanceMeters: locService.calculateDistanceMeters(pLat, pLng, cLat, cLng),
      distanceDisplay: locService.formatDistance(pLat, pLng, cLat, cLng),
      etaDisplay: locService.estimateTravelTime(pLat, pLng, cLat, cLng),
      updatedAt: DateTime.now(),
    );
  }

  void _recenter() {
    if (_currentTracking == null || !_isMapReady) return;
    final pLat = _currentTracking!.providerLocation.latitude;
    final pLng = _currentTracking!.providerLocation.longitude;
    final cLat = _currentTracking!.customerLocation.latitude;
    final cLng = _currentTracking!.customerLocation.longitude;

    final centerLat = (pLat + cLat) / 2.0;
    final centerLng = (pLng + cLng) / 2.0;

    _mapController.move(LatLng(centerLat, centerLng), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<LiveTrackingData>(
        stream: _trackingService.streamTracking(widget.request.id),
        initialData: _currentTracking,
        builder: (context, snapshot) {
          final tracking = snapshot.data ?? _currentTracking!;
          final cPoint = LatLng(tracking.customerLocation.latitude, tracking.customerLocation.longitude);
          final pPoint = LatLng(tracking.providerLocation.latitude, tracking.providerLocation.longitude);

          final initialCenter = LatLng(
            (cPoint.latitude + pPoint.latitude) / 2.0,
            (cPoint.longitude + pPoint.longitude) / 2.0,
          );

          return Stack(
            children: [
              // 1. OpenStreetMap Vector Engine
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 14.5,
                  minZoom: 4,
                  maxZoom: 18,
                  onMapReady: () {
                    _isMapReady = true;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.workbridge',
                  ),
                  // Polyline connecting provider to customer
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pPoint, cPoint],
                        strokeWidth: 4.5,
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderStrokeWidth: 2.0,
                        borderColor: AppColors.accent,
                      ),
                    ],
                  ),
                  // Markers for Customer and Provider
                  MarkerLayer(
                    markers: [
                      // Customer Destination Marker (Blue Sapphire Pin - Fixed/Static Home)
                      Marker(
                        point: cPoint,
                        width: 110,
                        height: 75,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                widget.isProviderView
                                    ? '${tracking.customerName.split(' ').first}\'s House (Static)'
                                    : 'Your Home (${tracking.customerLocation.city})',
                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                                ],
                              ),
                              child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      // Provider Active Marker (Moving Pulse Technician Pin)
                      Marker(
                        point: pPoint,
                        width: 100,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulseScale = 1.0 + (_pulseController.value * 0.25);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Text(
                                    widget.isProviderView
                                        ? 'You (Moving GPS)'
                                        : '${tracking.providerName.split(' ').first} (Live GPS)',
                                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Transform.scale(
                                  scale: pulseScale,
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Floating Top Header
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.request.serviceTitle,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.isProviderView
                                  ? 'Provider Navigation • Destination: ${tracking.customerLocation.city}'
                                  : 'Live Karigar Tracking • Coming to your location',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (tracking.status == TrackingState.completed)
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (tracking.status == TrackingState.completed)
                              ? 'Completed'
                              : (tracking.distanceMeters < 80 ? 'Arrived' : 'En Route'),
                          style: TextStyle(
                            color: (tracking.status == TrackingState.completed)
                                ? AppColors.success
                                : AppColors.accentDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Right Floating Controls (Recenter & Zoom)
              Positioned(
                right: 16,
                bottom: MediaQueryHelper.height(context, 0.30),
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'recenter_btn',
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                      onPressed: _recenter,
                      child: const Icon(Icons.my_location_rounded, size: 20),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'simulate_step_btn',
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      tooltip: 'Simulate Moving Step',
                      onPressed: () async {
                        await _trackingService.simulateProviderStepCloser(widget.request.id);
                        if (context.mounted) {
                          UiHelper.showSnackBar(
                            context,
                            'Simulated technician moving closer! Coordinates updated in Realtime Database.',
                            isError: false,
                          );
                        }
                      },
                      child: const Icon(Icons.fast_forward_rounded, size: 20),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Detail Sheet Card
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ETA & Distance Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isProviderView
                                        ? '${tracking.distanceDisplay} to Client Destination'
                                        : '${tracking.distanceDisplay} Away',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    widget.isProviderView
                                        ? 'Travel time to home: ${tracking.etaDisplay}'
                                        : 'Estimated Arrival: ${tracking.etaDisplay}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 14, color: AppColors.success),
                                  SizedBox(width: 2),
                                  Text(
                                    'LIVE GPS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Addresses & Location Breadcrumbs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.radio_button_checked, size: 14, color: AppColors.accent),
                              Container(width: 2, height: 26, color: AppColors.border),
                              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Provider: ${tracking.providerLocation.address}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mainText,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Destination: ${tracking.customerLocation.address}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Technician Card & Call Action
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (widget.isProviderView ? tracking.customerName : tracking.providerName)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isProviderView ? tracking.customerName : tracking.providerName,
                                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.isProviderView
                                      ? 'Client • ${tracking.customerLocation.city}'
                                      : 'Verified Specialist • Live Tracking',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.success.withValues(alpha: 0.12),
                              foregroundColor: AppColors.success,
                            ),
                            icon: const Icon(Icons.call_rounded),
                            tooltip: 'Contact',
                            onPressed: () {
                              UiHelper.showSnackBar(
                                context,
                                'Calling ${widget.isProviderView ? tracking.customerName : tracking.providerName}...',
                                isError: false,
                              );
                            },
                          ),
                        ],
                      ),
                      if (widget.isProviderView) ...[
                        const SizedBox(height: 12),
                        if (tracking.status == TrackingState.enRoute)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.pin_drop_rounded, size: 18),
                              label: const Text(
                                'I Have Arrived at Location',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () async {
                                await _trackingService.updateTrackingStatus(
                                  requestId: widget.request.id,
                                  status: TrackingState.arrived,
                                );
                                await ServiceRequestService().markProviderArrived(
                                  requestId: widget.request.id,
                                );
                                if (context.mounted) {
                                  UiHelper.showSnackBar(
                                    context,
                                    'Status updated: Arrived at Client Location! Client is notified 🎉',
                                  );
                                }
                              },
                            ),
                          )
                        else if (tracking.status == TrackingState.arrived)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Arrived at Destination • Ready for Service',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
