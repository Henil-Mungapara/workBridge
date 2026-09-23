/// System-wide authorized user roles in WorkBridge.
///
/// Strictly restricted to three roles:
/// - Customer
/// - Service_Provider
/// - Admin
///
/// Case-insensitive conversion is supported, but spelling strictly matters.
/// Any unrecognized string (such as 'Henil') is strictly invalid.
abstract final class AppRoles {
  static const String customer = 'customer';
  static const String serviceProvider = 'service_provider';
  static const String admin = 'admin';

  static const List<String> all = [customer, serviceProvider, admin];

  /// Checks if [rawRole] matches one of the three strictly allowed roles.
  /// Case-insensitive, but spelling matters strictly.
  static bool isValid(String? rawRole) {
    if (rawRole == null) return false;
    final r = rawRole.trim().toLowerCase();
    return r == 'customer' ||
        r == 'service_provider' ||
        r == 'service provider' ||
        r == 'provider' ||
        r == 'admin';
  }

  /// Canonicalizes a raw role string into 'customer', 'service_provider', or 'admin'.
  /// Returns null if unrecognized (e.g. 'Henil').
  static String? canonicalize(String? rawRole) {
    if (rawRole == null) return null;
    final r = rawRole.trim().toLowerCase();
    if (r == 'customer') return customer;
    if (r == 'service_provider' || r == 'service provider' || r == 'provider') {
      return serviceProvider;
    }
    if (r == 'admin') return admin;
    return null;
  }

  /// Returns user-friendly display title for the given role.
  static String displayName(String? rawRole) {
    final canonical = canonicalize(rawRole);
    switch (canonical) {
      case admin:
        return 'Admin';
      case serviceProvider:
        return 'Service Provider';
      case customer:
        return 'Customer';
      default:
        return (rawRole != null && rawRole.trim().isNotEmpty)
            ? rawRole.trim()
            : 'Unassigned';
    }
  }
}

/// Domain model representing an authenticated WorkBridge user.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? password;
  final String role;
  final bool isVerified;
  final List<String> categories;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    this.role = AppRoles.customer,
    this.isVerified = false,
    this.categories = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the user's assigned role is one of Customer, Service_Provider, or Admin.
  bool get hasValidRole => AppRoles.isValid(role);

  /// Returns the canonical role string, or null if unrecognized.
  String? get canonicalRole => AppRoles.canonicalize(role);

  /// Normalizes role strings to 'customer', 'admin', or 'service_provider' if valid.
  /// If invalid, returns the trimmed raw string so callers can detect and reject it.
  static String normalizeRole(String? rawRole) {
    final canonical = AppRoles.canonicalize(rawRole);
    if (canonical != null) return canonical;
    return (rawRole?.trim() ?? AppRoles.customer);
  }

  /// Factory constructor to initialize an empty/guest user.
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      phone: '',
      password: null,
      role: AppRoles.customer,
      isVerified: false,
      categories: const [],
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Factory to deserialize from a Map (e.g. Cloud Firestore document).
  /// Preserves the raw role string if unrecognized so that role-validation
  /// can detect and report the exact string to the user.
  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawRole = (map['role'] as String?)?.trim() ?? '';
    final canonical = AppRoles.canonicalize(rawRole);

    final rawCategories = map['categories'];
    List<String> parsedCategories = [];
    if (rawCategories is List) {
      parsedCategories = rawCategories
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (map['category'] is String &&
        (map['category'] as String).trim().isNotEmpty) {
      parsedCategories = [(map['category'] as String).trim()];
    } else if (map['trade'] is String &&
        (map['trade'] as String).trim().isNotEmpty) {
      parsedCategories = [(map['trade'] as String).trim()];
    }

    return UserModel(
      uid: docId ?? map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      password: map['password'] as String?,
      role: canonical ?? (rawRole.isNotEmpty ? rawRole : AppRoles.customer),
      isVerified: map['isVerified'] as bool? ?? false,
      categories: parsedCategories,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Converts this instance into a Map for Firestore persistence.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': AppRoles.canonicalize(role) ?? role,
      'isVerified': isVerified,
      'categories': categories,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }

  /// Creates a copy with modified fields.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    bool? isVerified,
    List<String>? categories,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role != null ? (AppRoles.canonicalize(role) ?? role.trim()) : this.role,
      isVerified: isVerified ?? this.isVerified,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
