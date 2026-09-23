import 'package:flutter_test/flutter_test.dart';
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
  });
}
