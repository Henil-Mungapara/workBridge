import 'package:flutter_test/flutter_test.dart';
import 'package:workbridge/core/services/live_tracking_service.dart';
import 'package:workbridge/core/services/location_service.dart';
import 'package:workbridge/core/services/service_request_service.dart';
import 'package:workbridge/models/service_request_model.dart';

void main() {
  group('ServiceRequestModel & Concurrency Lifecycle Unit Tests', () {
    test('Broadcast Request (Random Karigar) initializes with pending status', () {
      final req = ServiceRequestModel(
        id: 'req_001',
        customerId: 'cust_123',
        customerName: 'Rahul Verma',
        customerPhone: '+91 98765 43210',
        customerAddress: 'Block B, Sector 62, Noida',
        categoryId: 'appliance_repair',
        categoryName: 'Appliance Repair',
        serviceTitle: 'AC Repair & Servicing',
        description: 'AC not cooling properly',
        estimatedAmount: 1499.0,
        scheduledDate: '2026-09-24',
        scheduledTime: '10:00 AM',
        requestType: RequestDispatchType.broadcast,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(req.isBroadcast, isTrue);
      expect(req.isSpecific, isFalse);
      expect(req.isPending, isTrue);
      expect(req.isAccepted, isFalse);
      expect(req.targetProviderId, isNull);
      expect(req.assignedProviderId, isNull);
      expect(req.declinedBy, isEmpty);
      expect(req.canceledBy, isEmpty);
    });

    test('Specific Karigar request sets targetProviderId and name correctly', () {
      final req = ServiceRequestModel(
        id: 'req_002',
        customerId: 'cust_123',
        customerName: 'Rahul Verma',
        customerPhone: '+91 98765 43210',
        customerAddress: 'Block B, Sector 62, Noida',
        categoryId: 'appliance_repair',
        categoryName: 'Appliance Repair',
        serviceTitle: 'AC Compressor Check',
        description: 'AC compressor making loud vibrating noise',
        estimatedAmount: 2200.0,
        scheduledDate: '2026-09-24',
        scheduledTime: '2:30 PM',
        requestType: RequestDispatchType.specific,
        targetProviderId: 'prov_999',
        targetProviderName: 'Vikram Sharma (Senior Karigar)',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(req.isSpecific, isTrue);
      expect(req.isBroadcast, isFalse);
      expect(req.targetProviderId, 'prov_999');
      expect(req.targetProviderName, 'Vikram Sharma (Senior Karigar)');
    });

    test('Accepted request locks to single provider and transitions to accepted status', () {
      final pendingReq = ServiceRequestModel(
        id: 'req_003',
        customerId: 'cust_123',
        customerName: 'Aman Patel',
        customerPhone: '+91 91234 56789',
        customerAddress: 'Flat 402, Green Valley Apartments',
        categoryId: 'plumbing',
        categoryName: 'Plumbing',
        serviceTitle: 'Bathroom Tap Leakage',
        description: 'Water leaking continuously from main mixer',
        estimatedAmount: 650.0,
        scheduledDate: '2026-09-24',
        scheduledTime: '11:00 AM',
        createdAt: DateTime.now().toIso8601String(),
      );

      final acceptedReq = pendingReq.copyWith(
        status: RequestStatus.accepted,
        assignedProviderId: 'prov_555',
        assignedProviderName: 'Suresh Kumar',
        assignedProviderPhone: '+91 99887 76655',
        acceptedAt: DateTime.now().toIso8601String(),
      );

      expect(acceptedReq.isPending, isFalse);
      expect(acceptedReq.isAccepted, isTrue);
      expect(acceptedReq.assignedProviderId, 'prov_555');
      expect(acceptedReq.assignedProviderName, 'Suresh Kumar');
      expect(acceptedReq.assignedProviderPhone, '+91 99887 76655');
      expect(acceptedReq.acceptedAt, isNotNull);
    });

    test('Provider cancellation reopens broadcast request and appends provider to canceledBy', () {
      final acceptedReq = ServiceRequestModel(
        id: 'req_004',
        customerId: 'cust_123',
        customerName: 'Aman Patel',
        customerPhone: '+91 91234 56789',
        customerAddress: 'Flat 402, Green Valley Apartments',
        categoryId: 'plumbing',
        categoryName: 'Plumbing',
        serviceTitle: 'Bathroom Tap Leakage',
        description: 'Water leaking continuously from main mixer',
        estimatedAmount: 650.0,
        scheduledDate: '2026-09-24',
        scheduledTime: '11:00 AM',
        status: RequestStatus.accepted,
        assignedProviderId: 'prov_555',
        assignedProviderName: 'Suresh Kumar',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Provider cancels: status resets to pending, assigned cleared, canceledBy updated
      final reopenedReq = acceptedReq.reopenBroadcast(
        cancelledByProviderId: 'prov_555',
        reason: 'Vehicle breakdown',
      );

      expect(reopenedReq.isPending, isTrue);
      expect(reopenedReq.assignedProviderId, isNull);
      expect(reopenedReq.canceledBy, contains('prov_555'));
      expect(reopenedReq.cancellationReason, 'Vehicle breakdown');
    });

    test('toMap and fromMap serialization preserves all lifecycle fields', () {
      final original = ServiceRequestModel(
        id: 'req_005',
        customerId: 'cust_888',
        customerName: 'Priya Sharma',
        customerPhone: '+91 98888 77777',
        customerAddress: 'Villa 12, Palm Meadows',
        categoryId: 'electrical',
        categoryName: 'Electrical',
        serviceTitle: 'Circuit Breaker Tripping',
        description: 'MCB keeps tripping when AC is turned on',
        estimatedAmount: 1850.0,
        scheduledDate: '2026-09-25',
        scheduledTime: '04:00 PM',
        requestType: RequestDispatchType.broadcast,
        status: RequestStatus.inProgress,
        assignedProviderId: 'prov_101',
        assignedProviderName: 'Deepak Verma',
        assignedProviderPhone: '+91 97777 66666',
        declinedBy: ['prov_102', 'prov_103'],
        canceledBy: ['prov_104'],
        createdAt: '2026-09-23T10:00:00.000',
        acceptedAt: '2026-09-23T10:05:00.000',
      );

      final map = original.toMap();
      final deserialized = ServiceRequestModel.fromMap(map, original.id);

      expect(deserialized.id, original.id);
      expect(deserialized.customerId, original.customerId);
      expect(deserialized.customerName, original.customerName);
      expect(deserialized.estimatedAmount, 1850.0);
      expect(deserialized.declinedBy, ['prov_102', 'prov_103']);
      expect(deserialized.canceledBy, ['prov_104']);
      expect(deserialized.assignedProviderId, 'prov_101');
      expect(deserialized.status, RequestStatus.inProgress);
    });

    test('Customer coordinates and city (e.g. Gondal) are faithfully serialized and deserialized', () {
      final reqWithLocation = ServiceRequestModel(
        id: 'req_loc_001',
        customerId: 'cust_gondal_01',
        customerName: 'Jayesh Patel',
        customerPhone: '+91 94280 12345',
        customerAddress: 'Station Road, Near Bus Stand, Gondal',
        customerLatitude: 21.9619,
        customerLongitude: 70.7923,
        customerCity: 'Gondal',
        categoryId: 'plumbing',
        categoryName: 'Plumbing',
        serviceTitle: 'Main Pipe Repair',
        description: 'Urgent leak near water meter',
        estimatedAmount: 800.0,
        scheduledDate: '2026-09-28',
        scheduledTime: '10:00 AM',
        createdAt: DateTime.now().toIso8601String(),
      );

      final map = reqWithLocation.toMap();
      expect(map['customerLatitude'], 21.9619);
      expect(map['customerLongitude'], 70.7923);
      expect(map['customerCity'], 'Gondal');

      final deserialized = ServiceRequestModel.fromMap(map, reqWithLocation.id);
      expect(deserialized.customerLatitude, 21.9619);
      expect(deserialized.customerLongitude, 70.7923);
      expect(deserialized.customerCity, 'Gondal');
    });

    test('Provider starting and ending locations are recorded and stored accurately', () {
      final startLoc = {
        'latitude': 21.9650,
        'longitude': 70.7950,
        'address': 'Gondal Bypass, Gondal, Gujarat',
        'city': 'Gondal',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final endLoc = {
        'latitude': 21.9619,
        'longitude': 70.7923,
        'address': 'Station Road, Gondal, Gujarat',
        'city': 'Gondal',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final acceptedReq = ServiceRequestModel(
        id: 'req_loc_002',
        customerId: 'cust_gondal_01',
        customerName: 'Jayesh Patel',
        customerPhone: '+91 94280 12345',
        customerAddress: 'Station Road, Gondal',
        customerLatitude: 21.9619,
        customerLongitude: 70.7923,
        customerCity: 'Gondal',
        categoryId: 'electrical',
        categoryName: 'Electrical',
        serviceTitle: 'Switchboard Repair',
        description: 'Sparking issue',
        estimatedAmount: 500.0,
        scheduledDate: '2026-09-28',
        scheduledTime: '02:00 PM',
        status: RequestStatus.completed,
        assignedProviderId: 'prov_gondal_01',
        assignedProviderName: 'Ramesh Karigar',
        providerStartLocation: startLoc,
        providerEndLocation: endLoc,
        trackingStatus: 'completed',
        createdAt: DateTime.now().toIso8601String(),
      );

      final map = acceptedReq.toMap();
      expect(map['providerStartLocation'], isNotNull);
      expect(map['providerStartLocation']['city'], 'Gondal');
      expect(map['providerEndLocation'], isNotNull);
      expect(map['providerEndLocation']['latitude'], 21.9619);
      expect(map['trackingStatus'], 'completed');

      final deserialized = ServiceRequestModel.fromMap(map, acceptedReq.id);
      expect(deserialized.providerStartLocation?['city'], 'Gondal');
      expect(deserialized.providerEndLocation?['latitude'], 21.9619);
      expect(deserialized.trackingStatus, 'completed');
    });

    test('LiveTrackingData serializes correctly with Realtime Database tree schema', () {
      final now = DateTime.now();
      final customerLoc = AppLocationData(
        latitude: 21.9619,
        longitude: 70.7923,
        address: 'Station Road, Gondal, Gujarat',
        city: 'Gondal',
        timestamp: now,
      );

      final providerLoc = AppLocationData(
        latitude: 21.9680,
        longitude: 70.7980,
        address: 'Gondal Main Chowk, Gondal',
        city: 'Gondal',
        timestamp: now,
      );

      final trackingData = LiveTrackingData(
        requestId: 'req_loc_003',
        providerId: 'prov_001',
        providerName: 'Kishore Mistri',
        providerPhone: '+91 98765 00000',
        customerId: 'cust_001',
        customerName: 'Jayesh Patel',
        customerLocation: customerLoc,
        providerLocation: providerLoc,
        status: TrackingState.enRoute,
        distanceMeters: 850.0,
        distanceDisplay: '850 m',
        etaDisplay: '3 mins',
        updatedAt: DateTime.now(),
      );

      final rtdbMap = trackingData.toMap();
      expect(rtdbMap['requestId'], 'req_loc_003');
      expect(rtdbMap['status'], TrackingState.enRoute);
      expect(rtdbMap['customerLocation']['city'], 'Gondal');
      expect(rtdbMap['providerLocation']['latitude'], 21.9680);
      expect(rtdbMap['distanceDisplay'], '850 m');
      expect(rtdbMap['etaDisplay'], '3 mins');

      final restored = LiveTrackingData.fromMap(rtdbMap);
      expect(restored.requestId, 'req_loc_003');
      expect(restored.status, TrackingState.enRoute);
      expect(restored.customerLocation.city, 'Gondal');
      expect(restored.providerLocation.latitude, 21.9680);
    });

    test('ServiceRequestService streamProviderIncomingRequests yields empty list when offline', () async {
      final service = ServiceRequestService();
      final stream = service.streamProviderIncomingRequests(
        providerId: 'prov_test_01',
        providerCategories: ['Electrical'],
        isOnline: false,
        showAllOpenRequests: true,
      );
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('TrackingState.arrived and LiveTrackingData transitions status correctly', () {
      final tracking = LiveTrackingData(
        requestId: 'req_loc_004',
        providerId: 'prov_test',
        providerName: 'Test Specialist',
        providerPhone: '+91 99999 88888',
        customerId: 'cust_test',
        customerName: 'Customer Name',
        customerLocation: AppLocationData(
          latitude: 21.9619,
          longitude: 70.7923,
          address: 'Gondal Address',
          city: 'Gondal',
          timestamp: DateTime(2026, 9, 28),
        ),
        providerLocation: AppLocationData(
          latitude: 21.9619,
          longitude: 70.7923,
          address: 'Arrived at Gate',
          city: 'Gondal',
          timestamp: DateTime(2026, 9, 28),
        ),
        status: TrackingState.arrived,
        distanceMeters: 0,
        distanceDisplay: '0 m',
        etaDisplay: 'Arrived',
        updatedAt: DateTime.now(),
      );

      expect(tracking.status, TrackingState.arrived);
      expect(tracking.etaDisplay, 'Arrived');
      expect(tracking.toMap()['status'], 'arrived');
    });
  });
}

