import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'location_service.dart';

/// Current live tracking progress state of the provider.
abstract final class TrackingState {
  static const String accepted = 'accepted';
  static const String enRoute = 'en_route';
  static const String arrived = 'arrived';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

/// Domain model for active real-time tracking session.
class LiveTrackingData {
  final String requestId;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final String customerId;
  final String customerName;

  final AppLocationData customerLocation;
  final AppLocationData providerLocation;
  final AppLocationData? startLocation;
  final AppLocationData? endLocation;

  final String status;
  final double distanceMeters;
  final String distanceDisplay;
  final String etaDisplay;
  final DateTime updatedAt;

  const LiveTrackingData({
    required this.requestId,
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    required this.customerId,
    required this.customerName,
    required this.customerLocation,
    required this.providerLocation,
    this.startLocation,
    this.endLocation,
    required this.status,
    required this.distanceMeters,
    required this.distanceDisplay,
    required this.etaDisplay,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'customerId': customerId,
      'customerName': customerName,
      'customerLocation': customerLocation.toMap(),
      'providerLocation': providerLocation.toMap(),
      if (startLocation != null) 'startLocation': startLocation!.toMap(),
      if (endLocation != null) 'endLocation': endLocation!.toMap(),
      'status': status,
      'distanceMeters': distanceMeters,
      'distanceDisplay': distanceDisplay,
      'etaDisplay': etaDisplay,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LiveTrackingData.fromMap(Map<String, dynamic> map) {
    final cLocMap = Map<String, dynamic>.from(map['customerLocation'] as Map? ?? {});
    final pLocMap = Map<String, dynamic>.from(map['providerLocation'] as Map? ?? {});
    final sLocMap = map['startLocation'] != null
        ? Map<String, dynamic>.from(map['startLocation'] as Map)
        : null;
    final eLocMap = map['endLocation'] != null
        ? Map<String, dynamic>.from(map['endLocation'] as Map)
        : null;

    final cLoc = AppLocationData.fromMap(cLocMap);
    final pLoc = AppLocationData.fromMap(pLocMap);
    final sLoc = sLocMap != null ? AppLocationData.fromMap(sLocMap) : null;
    final eLoc = eLocMap != null ? AppLocationData.fromMap(eLocMap) : null;

    final locService = LocationService();
    final dist = locService.calculateDistanceMeters(
      pLoc.latitude,
      pLoc.longitude,
      cLoc.latitude,
      cLoc.longitude,
    );
    final distDisplay = locService.formatDistance(
      pLoc.latitude,
      pLoc.longitude,
      cLoc.latitude,
      cLoc.longitude,
    );
    final etaDisplay = locService.estimateTravelTime(
      pLoc.latitude,
      pLoc.longitude,
      cLoc.latitude,
      cLoc.longitude,
    );

    final tsStr = map['updatedAt'] as String?;
    final updatedAt = tsStr != null ? DateTime.tryParse(tsStr) ?? DateTime.now() : DateTime.now();

    return LiveTrackingData(
      requestId: map['requestId'] as String? ?? '',
      providerId: map['providerId'] as String? ?? '',
      providerName: map['providerName'] as String? ?? 'Provider',
      providerPhone: map['providerPhone'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      customerLocation: cLoc,
      providerLocation: pLoc,
      startLocation: sLoc,
      endLocation: eLoc,
      status: map['status'] as String? ?? TrackingState.enRoute,
      distanceMeters: dist,
      distanceDisplay: distDisplay,
      etaDisplay: etaDisplay,
      updatedAt: updatedAt,
    );
  }
}

/// Service managing real-time technician tracking across both Firebase Realtime Database
/// (hierarchical JSON tree) and Cloud Firestore with dual-synchronization and graceful fallback.
class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal();

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseDatabase? get _realtimeDb {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseDatabase.instance;
      }
    } catch (_) {}
    return null;
  }

  // ── In-Memory Cache & Test Override ───────────────────────────────────────
  final Map<String, LiveTrackingData> _inMemoryCache = {};
  final Map<String, StreamController<LiveTrackingData>> _activeStreams = {};

  // ── 1. Start Live Tracking Session ────────────────────────────────────────

  /// Initializes a live tracking session when a Service Provider accepts a request.
  /// Records provider's starting location and initializes the hierarchical tree in
  /// Firebase Realtime Database (`live_tracking/<requestId>`) and Cloud Firestore.
  Future<LiveTrackingData> startTrackingSession({
    required String requestId,
    required String providerId,
    required String providerName,
    required String providerPhone,
    required String customerId,
    required String customerName,
    required AppLocationData customerLocation,
    required AppLocationData providerStartLocation,
  }) async {
    final locService = LocationService();
    final dist = locService.calculateDistanceMeters(
      providerStartLocation.latitude,
      providerStartLocation.longitude,
      customerLocation.latitude,
      customerLocation.longitude,
    );

    final session = LiveTrackingData(
      requestId: requestId,
      providerId: providerId,
      providerName: providerName,
      providerPhone: providerPhone,
      customerId: customerId,
      customerName: customerName,
      customerLocation: customerLocation,
      providerLocation: providerStartLocation,
      startLocation: providerStartLocation,
      status: TrackingState.enRoute,
      distanceMeters: dist,
      distanceDisplay: locService.formatDistance(
        providerStartLocation.latitude,
        providerStartLocation.longitude,
        customerLocation.latitude,
        customerLocation.longitude,
      ),
      etaDisplay: locService.estimateTravelTime(
        providerStartLocation.latitude,
        providerStartLocation.longitude,
        customerLocation.latitude,
        customerLocation.longitude,
      ),
      updatedAt: DateTime.now(),
    );

    _inMemoryCache[requestId] = session;
    _notifyStream(requestId, session);

    // 1. Dual Write to Cloud Firestore
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('live_tracking').doc(requestId).set(session.toMap());

        // Also synchronize to the service_requests document
        await fs.collection('service_requests').doc(requestId).update({
          'providerStartLocation': providerStartLocation.toMap(),
          'providerCurrentLocation': providerStartLocation.toMap(),
          'trackingStatus': TrackingState.enRoute,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firestore tracking init notice: $e');
    }

    // 2. Tree Structure Write to Firebase Realtime Database
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        await rtdb.ref('live_tracking/$requestId').set(session.toMap());
      }
    } catch (e) {
      debugPrint('Realtime Database tree structure write notice: $e');
    }

    return session;
  }

  // ── 2. Update Provider's Live Position ─────────────────────────────────────

  /// Updates provider's moving coordinates in real-time.
  Future<void> updateProviderLocation({
    required String requestId,
    AppLocationData? newLocation,
    String? status,
  }) async {
    final existing = _inMemoryCache[requestId] ?? await fetchTracking(requestId);
    if (existing == null) return;

    final locService = LocationService();
    final pLoc = newLocation ?? existing.providerLocation;
    final dist = locService.calculateDistanceMeters(
      pLoc.latitude,
      pLoc.longitude,
      existing.customerLocation.latitude,
      existing.customerLocation.longitude,
    );

    final resolvedStatus = (dist < 80)
        ? TrackingState.arrived
        : (status ?? existing.status);

    final updated = LiveTrackingData(
      requestId: requestId,
      providerId: existing.providerId,
      providerName: existing.providerName,
      providerPhone: existing.providerPhone,
      customerId: existing.customerId,
      customerName: existing.customerName,
      customerLocation: existing.customerLocation,
      providerLocation: pLoc,
      startLocation: existing.startLocation,
      endLocation: existing.endLocation,
      status: resolvedStatus,
      distanceMeters: dist,
      distanceDisplay: locService.formatDistance(
        pLoc.latitude,
        pLoc.longitude,
        existing.customerLocation.latitude,
        existing.customerLocation.longitude,
      ),
      etaDisplay: locService.estimateTravelTime(
        pLoc.latitude,
        pLoc.longitude,
        existing.customerLocation.latitude,
        existing.customerLocation.longitude,
      ),
      updatedAt: DateTime.now(),
    );

    _inMemoryCache[requestId] = updated;
    _notifyStream(requestId, updated);

    // Write to Realtime Database tree
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        await rtdb.ref('live_tracking/$requestId/providerLocation').set(pLoc.toMap());
        await rtdb.ref('live_tracking/$requestId/status').set(resolvedStatus);
        await rtdb.ref('live_tracking/$requestId/updatedAt').set(DateTime.now().toIso8601String());
      }
    } catch (_) {}

    // Synchronize to Firestore
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('live_tracking').doc(requestId).update({
          'providerLocation': pLoc.toMap(),
          'status': resolvedStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await fs.collection('service_requests').doc(requestId).update({
          'providerCurrentLocation': pLoc.toMap(),
          'trackingStatus': resolvedStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ── 2b. Manual Status Transition (e.g. Arrived) ──────────────────────────

  /// Explicitly updates live tracking status across memory, Realtime DB, and Firestore.
  Future<void> updateTrackingStatus({
    required String requestId,
    required String status,
  }) async {
    final existing = _inMemoryCache[requestId] ?? await fetchTracking(requestId);
    if (existing != null) {
      final updated = LiveTrackingData(
        requestId: requestId,
        providerId: existing.providerId,
        providerName: existing.providerName,
        providerPhone: existing.providerPhone,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerLocation: existing.customerLocation,
        providerLocation: existing.providerLocation,
        startLocation: existing.startLocation,
        endLocation: existing.endLocation,
        status: status,
        distanceMeters: existing.distanceMeters,
        distanceDisplay: existing.distanceDisplay,
        etaDisplay: status == TrackingState.arrived ? 'Arrived' : existing.etaDisplay,
        updatedAt: DateTime.now(),
      );
      _inMemoryCache[requestId] = updated;
      _notifyStream(requestId, updated);
    }

    // Write to Realtime Database
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        await rtdb.ref('live_tracking/$requestId/status').set(status);
        await rtdb.ref('live_tracking/$requestId/updatedAt').set(DateTime.now().toIso8601String());
      }
    } catch (_) {}

    // Synchronize to Firestore
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('live_tracking').doc(requestId).update({
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await fs.collection('service_requests').doc(requestId).update({
          'trackingStatus': status,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ── 3. Complete Tracking Session (Store Ending Location) ───────────────────

  /// Marks live tracking as completed and records provider's final ending location in Firestore and Realtime DB.
  Future<void> completeTrackingSession({
    required String requestId,
    required AppLocationData endLocation,
  }) async {
    final existing = _inMemoryCache[requestId] ?? await fetchTracking(requestId);

    final updated = (existing != null)
        ? LiveTrackingData(
            requestId: requestId,
            providerId: existing.providerId,
            providerName: existing.providerName,
            providerPhone: existing.providerPhone,
            customerId: existing.customerId,
            customerName: existing.customerName,
            customerLocation: existing.customerLocation,
            providerLocation: endLocation,
            startLocation: existing.startLocation,
            endLocation: endLocation,
            status: TrackingState.completed,
            distanceMeters: 0,
            distanceDisplay: '0 m',
            etaDisplay: 'Completed',
            updatedAt: DateTime.now(),
          )
        : null;

    if (updated != null) {
      _inMemoryCache[requestId] = updated;
      _notifyStream(requestId, updated);
    }

    // Write end location to Realtime Database
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        await rtdb.ref('live_tracking/$requestId/endLocation').set(endLocation.toMap());
        await rtdb.ref('live_tracking/$requestId/status').set(TrackingState.completed);
        await rtdb.ref('live_tracking/$requestId/updatedAt').set(DateTime.now().toIso8601String());
      }
    } catch (_) {}

    // Store ending location in Firestore
    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('live_tracking').doc(requestId).update({
          'endLocation': endLocation.toMap(),
          'status': TrackingState.completed,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await fs.collection('service_requests').doc(requestId).update({
          'providerEndLocation': endLocation.toMap(),
          'trackingStatus': TrackingState.completed,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ── 3b. Cancel Tracking Session ───────────────────────────────────────────

  /// Marks live tracking as cancelled across Realtime Database, Firestore, and stream listeners.
  Future<void> cancelTrackingSession({
    required String requestId,
    String reason = 'Session cancelled',
  }) async {
    final existing = _inMemoryCache[requestId] ?? await fetchTracking(requestId);
    if (existing != null) {
      final updated = LiveTrackingData(
        requestId: requestId,
        providerId: existing.providerId,
        providerName: existing.providerName,
        providerPhone: existing.providerPhone,
        customerId: existing.customerId,
        customerName: existing.customerName,
        customerLocation: existing.customerLocation,
        providerLocation: existing.providerLocation,
        startLocation: existing.startLocation,
        endLocation: existing.endLocation,
        status: TrackingState.cancelled,
        distanceMeters: 0,
        distanceDisplay: '0 m',
        etaDisplay: 'Cancelled',
        updatedAt: DateTime.now(),
      );
      _inMemoryCache[requestId] = updated;
      _notifyStream(requestId, updated);
    }

    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        await rtdb.ref('live_tracking/$requestId/status').set(TrackingState.cancelled);
        await rtdb.ref('live_tracking/$requestId/cancellationReason').set(reason);
        await rtdb.ref('live_tracking/$requestId/updatedAt').set(DateTime.now().toIso8601String());
      }
    } catch (_) {}

    try {
      final fs = _firestore;
      if (fs != null) {
        await fs.collection('live_tracking').doc(requestId).update({
          'status': TrackingState.cancelled,
          'cancellationReason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await fs.collection('service_requests').doc(requestId).update({
          'trackingStatus': TrackingState.cancelled,
          'cancellationReason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ── 4. Real-Time Tracking Stream ──────────────────────────────────────────

  /// Emits real-time live tracking data for a booking request.
  /// Combines Realtime Database stream, Firestore snapshots, and local updates.
  Stream<LiveTrackingData> streamTracking(String requestId) {
    final controller = _activeStreams.putIfAbsent(
      requestId,
      () => StreamController<LiveTrackingData>.broadcast(),
    );

    // Initial cache emission
    final cached = _inMemoryCache[requestId];
    if (cached != null) {
      controller.add(cached);
    }

    // 1. Try Realtime Database listener
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        rtdb.ref('live_tracking/$requestId').onValue.listen((event) {
          final val = event.snapshot.value;
          if (val is Map) {
            final data = LiveTrackingData.fromMap(Map<String, dynamic>.from(val));
            _inMemoryCache[requestId] = data;
            controller.add(data);
          }
        }, onError: (err) {
          debugPrint('Realtime DB stream notice: $err');
        });
      }
    } catch (_) {}

    // 2. Fallback / Sync Firestore document stream
    try {
      final fs = _firestore;
      if (fs != null) {
        fs.collection('live_tracking').doc(requestId).snapshots().listen((snap) {
          if (snap.exists && snap.data() != null) {
            final data = LiveTrackingData.fromMap(snap.data()!);
            _inMemoryCache[requestId] = data;
            controller.add(data);
          }
        }, onError: (_) {});
      }
    } catch (_) {}

    return controller.stream;
  }

  Future<LiveTrackingData?> fetchTracking(String requestId) async {
    final cached = _inMemoryCache[requestId];
    if (cached != null) return cached;

    // Check Realtime Database
    try {
      final rtdb = _realtimeDb;
      if (rtdb != null) {
        final snap = await rtdb.ref('live_tracking/$requestId').get();
        if (snap.exists && snap.value is Map) {
          final data = LiveTrackingData.fromMap(Map<String, dynamic>.from(snap.value as Map));
          _inMemoryCache[requestId] = data;
          return data;
        }
      }
    } catch (_) {}

    // Check Firestore
    try {
      final fs = _firestore;
      if (fs != null) {
        final doc = await fs.collection('live_tracking').doc(requestId).get();
        if (doc.exists && doc.data() != null) {
          final data = LiveTrackingData.fromMap(doc.data()!);
          _inMemoryCache[requestId] = data;
          return data;
        }
      }
    } catch (_) {}

    return null;
  }

  void _notifyStream(String requestId, LiveTrackingData data) {
    final controller = _activeStreams[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  /// Simulation helper: moves provider one step closer to customer (useful for testing & demo)
  Future<void> simulateProviderStepCloser(String requestId) async {
    final current = _inMemoryCache[requestId] ?? await fetchTracking(requestId);
    if (current == null) return;

    final pLat = current.providerLocation.latitude;
    final pLng = current.providerLocation.longitude;
    final cLat = current.customerLocation.latitude;
    final cLng = current.customerLocation.longitude;

    // Move 20% closer towards the customer
    final stepLat = pLat + (cLat - pLat) * 0.25;
    final stepLng = pLng + (cLng - pLng) * 0.25;

    final updatedLoc = AppLocationData(
      latitude: stepLat,
      longitude: stepLng,
      address: 'En-route towards ${current.customerLocation.city}',
      city: current.customerLocation.city,
      speed: 28.0,
      timestamp: DateTime.now(),
    );

    await updateProviderLocation(
      requestId: requestId,
      newLocation: updatedLoc,
      status: TrackingState.enRoute,
    );
  }
}
