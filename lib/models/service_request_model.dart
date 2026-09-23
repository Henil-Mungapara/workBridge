import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the execution state of a service request.
abstract final class RequestStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static String displayName(String? status) {
    switch (status?.toLowerCase()) {
      case pending:
        return 'Pending';
      case accepted:
        return 'Accepted';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }
}

/// Represents the dispatch type chosen by the customer.
abstract final class RequestDispatchType {
  /// Broadcast to all eligible service providers in the category (Random Karigar).
  static const String broadcast = 'broadcast';

  /// Targeted request sent directly to a selected provider (Specific Karigar).
  static const String specific = 'specific';
}

/// Domain model representing a customer's on-demand service booking request.
class ServiceRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String categoryId;
  final String categoryName;
  final String serviceTitle;
  final String description;
  final double estimatedAmount;
  final String scheduledDate;
  final String scheduledTime;

  /// 'broadcast' (Random Karigar) or 'specific' (Specific Karigar)
  final String requestType;

  /// If requestType == 'specific', this is the targeted provider's UID
  final String? targetProviderId;
  final String? targetProviderName;

  /// Once accepted, these store the claimed provider's info
  final String? assignedProviderId;
  final String? assignedProviderName;
  final String? assignedProviderPhone;

  /// Current status: pending, accepted, in_progress, completed, cancelled
  final String status;

  /// Provider UIDs who declined this request
  final List<String> declinedBy;

  /// Provider UIDs who accepted and subsequently cancelled this request
  final List<String> canceledBy;

  final String createdAt;
  final String? acceptedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancellationReason;

  const ServiceRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.categoryId,
    required this.categoryName,
    required this.serviceTitle,
    required this.description,
    required this.estimatedAmount,
    required this.scheduledDate,
    required this.scheduledTime,
    this.requestType = RequestDispatchType.broadcast,
    this.targetProviderId,
    this.targetProviderName,
    this.assignedProviderId,
    this.assignedProviderName,
    this.assignedProviderPhone,
    this.status = RequestStatus.pending,
    this.declinedBy = const [],
    this.canceledBy = const [],
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  bool get isBroadcast => requestType == RequestDispatchType.broadcast;
  bool get isSpecific => requestType == RequestDispatchType.specific;
  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isInProgress => status == RequestStatus.inProgress;
  bool get isCompleted => status == RequestStatus.completed;
  bool get isCancelled => status == RequestStatus.cancelled;

  /// Deserializes a Firestore document snapshot into [ServiceRequestModel].
  factory ServiceRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ServiceRequestModel.fromMap(data, doc.id);
  }

  /// Deserializes a map representation into [ServiceRequestModel].
  factory ServiceRequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawDeclined = map['declinedBy'];
    List<String> parsedDeclined = [];
    if (rawDeclined is List) {
      parsedDeclined = rawDeclined.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    final rawCanceled = map['canceledBy'];
    List<String> parsedCanceled = [];
    if (rawCanceled is List) {
      parsedCanceled = rawCanceled.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    final double amount = (map['estimatedAmount'] is num)
        ? (map['estimatedAmount'] as num).toDouble()
        : double.tryParse(map['estimatedAmount']?.toString() ?? '0') ?? 0.0;

    return ServiceRequestModel(
      id: docId ?? (map['id'] as String? ?? ''),
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      serviceTitle: map['serviceTitle'] as String? ?? '',
      description: map['description'] as String? ?? '',
      estimatedAmount: amount,
      scheduledDate: map['scheduledDate'] as String? ?? '',
      scheduledTime: map['scheduledTime'] as String? ?? '',
      requestType: map['requestType'] as String? ?? RequestDispatchType.broadcast,
      targetProviderId: map['targetProviderId'] as String?,
      targetProviderName: map['targetProviderName'] as String?,
      assignedProviderId: map['assignedProviderId'] as String?,
      assignedProviderName: map['assignedProviderName'] as String?,
      assignedProviderPhone: map['assignedProviderPhone'] as String?,
      status: map['status'] as String? ?? RequestStatus.pending,
      declinedBy: parsedDeclined,
      canceledBy: parsedCanceled,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      acceptedAt: map['acceptedAt'] as String?,
      completedAt: map['completedAt'] as String?,
      cancelledAt: map['cancelledAt'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  /// Converts this instance into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'serviceTitle': serviceTitle,
      'description': description,
      'estimatedAmount': estimatedAmount,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'requestType': requestType,
      'targetProviderId': targetProviderId,
      'targetProviderName': targetProviderName,
      'assignedProviderId': assignedProviderId,
      'assignedProviderName': assignedProviderName,
      'assignedProviderPhone': assignedProviderPhone,
      'status': status,
      'declinedBy': declinedBy,
      'canceledBy': canceledBy,
      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'completedAt': completedAt,
      'cancelledAt': cancelledAt,
      'cancellationReason': cancellationReason,
    };
  }

  ServiceRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? categoryId,
    String? categoryName,
    String? serviceTitle,
    String? description,
    double? estimatedAmount,
    String? scheduledDate,
    String? scheduledTime,
    String? requestType,
    String? targetProviderId,
    String? targetProviderName,
    String? assignedProviderId,
    String? assignedProviderName,
    String? assignedProviderPhone,
    String? status,
    List<String>? declinedBy,
    List<String>? canceledBy,
    String? createdAt,
    String? acceptedAt,
    String? completedAt,
    String? cancelledAt,
    String? cancellationReason,
    bool clearAssigned = false,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      description: description ?? this.description,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      requestType: requestType ?? this.requestType,
      targetProviderId: targetProviderId ?? this.targetProviderId,
      targetProviderName: targetProviderName ?? this.targetProviderName,
      assignedProviderId: clearAssigned ? null : (assignedProviderId ?? this.assignedProviderId),
      assignedProviderName: clearAssigned ? null : (assignedProviderName ?? this.assignedProviderName),
      assignedProviderPhone: clearAssigned ? null : (assignedProviderPhone ?? this.assignedProviderPhone),
      status: status ?? this.status,
      declinedBy: declinedBy ?? this.declinedBy,
      canceledBy: canceledBy ?? this.canceledBy,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: clearAssigned ? null : (acceptedAt ?? this.acceptedAt),
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  /// Reopens a broadcast request after provider cancellation, clearing assigned fields
  /// and recording the cancelling provider so they won't see it again.
  ServiceRequestModel reopenBroadcast({
    required String cancelledByProviderId,
    String? reason,
  }) {
    final updated = List<String>.from(canceledBy);
    if (!updated.contains(cancelledByProviderId)) {
      updated.add(cancelledByProviderId);
    }
    return copyWith(
      status: RequestStatus.pending,
      clearAssigned: true,
      canceledBy: updated,
      cancellationReason: reason,
    );
  }
}
