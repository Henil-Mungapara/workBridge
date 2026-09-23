import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';

/// Centralized service managing service requests, dual-mode Karigar dispatch,
/// real-time streams, and atomic concurrency transactions.
class ServiceRequestService {
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _requestsCollection =>
      _firestore?.collection('service_requests');

  CollectionReference<Map<String, dynamic>>? get _usersCollection =>
      _firestore?.collection('users');

  // ── 1. Create Service Request (Broadcast or Specific) ─────────────────────

  /// Creates a new service request and stores it in Firestore.
  /// Dispatched either as [RequestDispatchType.broadcast] (Random Karigar)
  /// or [RequestDispatchType.specific] (Specific Karigar).
  Future<ServiceRequestModel> createRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String categoryId,
    required String categoryName,
    required String serviceTitle,
    required String description,
    required double estimatedAmount,
    required String scheduledDate,
    required String scheduledTime,
    String requestType = RequestDispatchType.broadcast,
    String? targetProviderId,
    String? targetProviderName,
  }) async {
    final String docId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final request = ServiceRequestModel(
      id: docId,
      customerId: customerId,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      customerAddress: customerAddress.trim(),
      categoryId: categoryId,
      categoryName: categoryName,
      serviceTitle: serviceTitle.trim(),
      description: description.trim(),
      estimatedAmount: estimatedAmount,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      requestType: requestType,
      targetProviderId: targetProviderId,
      targetProviderName: targetProviderName,
      status: RequestStatus.pending,
      declinedBy: const [],
      canceledBy: const [],
      createdAt: DateTime.now().toIso8601String(),
    );

    final col = _requestsCollection;
    if (col != null) {
      await col.doc(docId).set(request.toMap());
    }
    return request;
  }

  // ── 2. Customer Streams ───────────────────────────────────────────────────

  /// Streams all service requests submitted by this customer in real-time.
  Stream<List<ServiceRequestModel>> streamCustomerRequests(String customerId) {
    final col = _requestsCollection;
    if (customerId.isEmpty || col == null) return Stream.value([]);

    return col
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── 3. Service Provider Streams ───────────────────────────────────────────

  /// Streams incoming pending requests for this provider.
  /// - Only emits when [isOnline] is true.
  /// - Excludes requests already declined or previously cancelled by this provider.
  /// - For broadcast requests: matches provider's assigned categories.
  /// - For specific requests: matches [targetProviderId] == [providerId].
  Stream<List<ServiceRequestModel>> streamProviderIncomingRequests({
    required String providerId,
    required List<String> providerCategories,
    required bool isOnline,
  }) {
    final col = _requestsCollection;
    if (!isOnline || providerId.isEmpty || col == null) {
      return Stream.value([]);
    }

    return col
        .where('status', isEqualTo: RequestStatus.pending)
        .snapshots()
        .map((snapshot) {
      final List<ServiceRequestModel> results = [];

      for (final doc in snapshot.docs) {
        final req = ServiceRequestModel.fromFirestore(doc);

        // Skip if this provider previously declined this request
        if (req.declinedBy.contains(providerId)) continue;

        // Skip if this provider previously accepted and then cancelled this request
        if (req.canceledBy.contains(providerId)) continue;

        if (req.isSpecific) {
          // Specific Karigar request: only show if targeted to this provider
          if (req.targetProviderId == providerId) {
            results.add(req);
          }
        } else {
          // Random Karigar (Broadcast) request: show if category matches provider's specialties
          final matchesCategory = _matchesProviderCategory(
            reqCategoryName: req.categoryName,
            reqCategoryId: req.categoryId,
            providerCategories: providerCategories,
          );
          if (matchesCategory) {
            results.add(req);
          }
        }
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    });
  }

  /// Streams active jobs accepted by this provider (accepted or in_progress).
  Stream<List<ServiceRequestModel>> streamProviderActiveJobs(String providerId) {
    final col = _requestsCollection;
    if (providerId.isEmpty || col == null) return Stream.value([]);

    return col
        .where('assignedProviderId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequestModel.fromFirestore(doc))
          .where((req) => req.status == RequestStatus.accepted || req.status == RequestStatus.inProgress)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Streams completed jobs for this provider.
  Stream<List<ServiceRequestModel>> streamProviderCompletedJobs(String providerId) {
    final col = _requestsCollection;
    if (providerId.isEmpty || col == null) return Stream.value([]);

    return col
        .where('assignedProviderId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ServiceRequestModel.fromFirestore(doc))
          .where((req) => req.status == RequestStatus.completed)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── 4. Admin Stream ───────────────────────────────────────────────────────

  /// Streams all service requests for administration monitoring.
  Stream<List<ServiceRequestModel>> streamAllRequests() {
    final col = _requestsCollection;
    if (col == null) return Stream.value([]);

    return col.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── 5. Atomic Concurrency: Accept Request ─────────────────────────────────

  /// Atomically claims a service request using a Firestore Transaction.
  /// If multiple providers (e.g. 5 providers) tap "Accept" at the exact same moment,
  /// this transaction ensures only the very first succeeds.
  /// All other providers receive an exception, and real-time listeners hide
  /// the request from their dashboard within milliseconds.
  Future<bool> acceptRequest({
    required String requestId,
    required UserModel provider,
  }) async {
    final firestore = _firestore;
    final col = _requestsCollection;
    if (firestore == null || col == null) return true;

    final docRef = col.doc(requestId);

    return await firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw 'This service request is no longer available.';
      }

      final data = snapshot.data()!;
      final currentStatus = data['status'] as String? ?? RequestStatus.pending;
      final assignedId = data['assignedProviderId'] as String?;

      // Strictly check if already accepted by another provider
      if (currentStatus != RequestStatus.pending ||
          (assignedId != null && assignedId.isNotEmpty)) {
        throw 'Sorry! This job was just accepted by another service provider.';
      }

      // Atomically update document to accepted state
      transaction.update(docRef, {
        'status': RequestStatus.accepted,
        'assignedProviderId': provider.uid,
        'assignedProviderName': provider.name,
        'assignedProviderPhone': provider.phone,
        'acceptedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    });
  }

  // ── 6. Decline Request ────────────────────────────────────────────────────

  /// Appends [providerId] to [declinedBy].
  /// The request is immediately hidden from this provider's dashboard
  /// while remaining visible to all other eligible providers.
  Future<void> declineRequest({
    required String requestId,
    required String providerId,
  }) async {
    final col = _requestsCollection;
    if (col != null) {
      await col.doc(requestId).update({
        'declinedBy': FieldValue.arrayUnion([providerId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ── 7. Atomic Cancellation: Reopening for Other Providers ─────────────────

  /// Cancels an accepted job on the provider's side.
  /// - If the request was a Broadcast (Random Karigar), its status is reset back
  ///   to [RequestStatus.pending], assigned provider info is cleared, and [providerId]
  ///   is recorded in [canceledBy].
  ///   This causes the request to immediately REAPPEAR on other providers' screens!
  /// - If the request was targeted (Specific Karigar), it marks it as cancelled.
  Future<void> cancelAcceptedJob({
    required String requestId,
    required String providerId,
    String reason = 'Provider cancelled gig',
  }) async {
    final firestore = _firestore;
    final col = _requestsCollection;
    if (firestore == null || col == null) return;

    final docRef = col.doc(requestId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final data = snapshot.data()!;
      final requestType = data['requestType'] as String? ?? RequestDispatchType.broadcast;

      if (requestType == RequestDispatchType.broadcast) {
        // Re-open broadcast request for all OTHER providers
        transaction.update(docRef, {
          'status': RequestStatus.pending,
          'assignedProviderId': null,
          'assignedProviderName': null,
          'assignedProviderPhone': null,
          'acceptedAt': null,
          'canceledBy': FieldValue.arrayUnion([providerId]),
          'cancellationReason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Direct request cancelled
        transaction.update(docRef, {
          'status': RequestStatus.cancelled,
          'cancelledAt': DateTime.now().toIso8601String(),
          'cancellationReason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // ── 8. Lifecycle Transitions ──────────────────────────────────────────────

  /// Transitions a job status to [in_progress] or [completed].
  Future<void> updateJobStatus({
    required String requestId,
    required String status,
  }) async {
    final col = _requestsCollection;
    if (col == null) return;

    final Map<String, dynamic> updates = {
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == RequestStatus.completed) {
      updates['completedAt'] = DateTime.now().toIso8601String();
    }

    await col.doc(requestId).update(updates);
  }

  /// Cancels a pending request from the customer's side.
  Future<void> cancelCustomerRequest({
    required String requestId,
    required String customerId,
    String reason = 'Customer cancelled request',
  }) async {
    final col = _requestsCollection;
    if (col == null) return;

    final doc = await col.doc(requestId).get();
    if (doc.exists && doc.data()?['customerId'] == customerId) {
      await col.doc(requestId).update({
        'status': RequestStatus.cancelled,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ── 9. Provider Directory for Specific Karigar Picker ─────────────────────

  /// Fetches verified service providers capable of handling [categoryNameOrId].
  Future<List<UserModel>> getVerifiedProvidersForCategory(String categoryNameOrId) async {
    final col = _usersCollection;
    if (col == null) return [];

    try {
      final snapshot = await col
          .where('role', isEqualTo: AppRoles.serviceProvider)
          .where('isVerified', isEqualTo: true)
          .get();

      final targetCategory = ServiceCategory.findByNameOrTrade(categoryNameOrId);
      final List<UserModel> list = [];

      for (final doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        if (targetCategory == null) {
          list.add(user);
          continue;
        }

        // Check if provider has this category assigned
        final matches = user.categories.any((c) {
          final cat = ServiceCategory.findByNameOrTrade(c);
          return cat?.id == targetCategory.id;
        });

        if (matches || user.categories.isEmpty) {
          list.add(user);
        }
      }

      return list;
    } catch (e) {
      debugPrint('Error getting verified providers for category: $e');
      return [];
    }
  }

  /// Updates provider online/offline status in Firestore.
  Future<void> updateProviderOnlineStatus({
    required String providerId,
    required bool isOnline,
  }) async {
    final col = _usersCollection;
    if (providerId.isEmpty || col == null) return;
    try {
      await col.doc(providerId).update({
        'isOnline': isOnline,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Checks if a service request matches any category assigned to the provider.
  bool _matchesProviderCategory({
    required String reqCategoryName,
    required String reqCategoryId,
    required List<String> providerCategories,
  }) {
    if (providerCategories.isEmpty) return true; // Show all if unassigned

    final reqCat = ServiceCategory.findByNameOrTrade(reqCategoryName) ??
        ServiceCategory.findByNameOrTrade(reqCategoryId);

    for (final pCat in providerCategories) {
      final resolved = ServiceCategory.findByNameOrTrade(pCat);
      if (resolved != null && reqCat != null && resolved.id == reqCat.id) {
        return true;
      }
      if (pCat.trim().toLowerCase() == reqCategoryName.trim().toLowerCase() ||
          pCat.trim().toLowerCase() == reqCategoryId.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
