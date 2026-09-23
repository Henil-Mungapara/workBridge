import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

/// Representation of a Service Provider in Admin panel (fetched live from Firebase)
class AdminProviderItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? password;
  final String trade;
  final List<String> categories;
  final double rating;
  final int completedJobs;
  final bool isVerified;
  final String joinedDate;

  const AdminProviderItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    required this.trade,
    this.categories = const [],
    required this.rating,
    required this.completedJobs,
    required this.isVerified,
    this.joinedDate = 'Recent',
  });
}

/// Representation of a Customer / User in Admin panel (fetched live from Firebase)
class AdminCustomerItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? password;
  final int totalBookings;
  final String joinedDate;
  final bool isActive;

  const AdminCustomerItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.password,
    required this.totalBookings,
    required this.joinedDate,
    required this.isActive,
  });
}

/// Admin Dashboard Screen (View).
///
/// Designed with reference to SmartAttend Admin architecture:
/// - Branded Admin AppBar with dynamic User state and direct profile shortcut
/// - Live Cloud Firestore-driven KPI metrics (Users, Providers, Verification Queue)
/// - Administration setup modules (Manage Providers, Customers, Categories, Audit)
/// - Real-time Provider Verification review queue with instant Approve / Inspect actions
/// - Bottom navigation bar matching modular multi-page administration
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _currentIndex = 0;

  late final TextEditingController _providerSearchController;
  late final TextEditingController _userSearchController;
  String _providerSearchQuery = '';
  String _userSearchQuery = '';
  String _providerSort = 'Name (A-Z)';
  String _userSort = 'Name (A-Z)';

  final List<String> _providerSortOptions = const [
    'Name (A-Z)',
    'Name (Z-A)',
    'Rating (High-Low)',
    'Verified First',
  ];

  final List<String> _userSortOptions = const [
    'Name (A-Z)',
    'Name (Z-A)',
    'Bookings (High-Low)',
    'Email (A-Z)',
  ];

  List<AdminProviderItem> _providersList = [];
  List<AdminCustomerItem> _usersList = [];
  List<Map<String, dynamic>> _unassignedRoleUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersStreamSubscription;

  // Track active/inactive category status locally
  final Map<String, bool> _categoryStatusMap = {
    for (final cat in ServiceCategory.all8Categories) cat.id: true,
  };

  int _getProviderCountForCategory(String categoryId) {
    return _providersList.where((p) {
      if (p.categories.isNotEmpty) {
        return p.categories.any((c) => ServiceCategory.findByNameOrTrade(c)?.id == categoryId);
      }
      return ServiceCategory.findByNameOrTrade(p.trade)?.id == categoryId;
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _providerSearchController = TextEditingController();
    _userSearchController = TextEditingController();
    _subscribeToLiveDirectory();
  }

  @override
  void dispose() {
    _usersStreamSubscription?.cancel();
    _providerSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  /// Subscribes to real-time Cloud Firestore updates on the 'users' collection.
  /// Eliminates dummy data and organizes live records by canonical role.
  void _subscribeToLiveDirectory() {
    _usersStreamSubscription?.cancel();
    try {
      if (Firebase.apps.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      _usersStreamSubscription = FirebaseFirestore.instance
          .collection('users')
          .snapshots()
          .listen(
        (snapshot) {
          if (!mounted) return;
          final List<AdminProviderItem> liveProviders = [];
          final List<AdminCustomerItem> liveCustomers = [];
          final List<Map<String, dynamic>> unassigned = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawRole = data['role'] as String?;
            final canonicalRole = AppRoles.canonicalize(rawRole);
            final name = (data['name'] as String?)?.trim() ?? 'User';
            final email = (data['email'] as String?)?.trim() ?? '';
            final phone = (data['phone'] as String?)?.trim() ?? 'Not provided';
            final isVerified = data['isVerified'] as bool? ?? false;
            final createdAt = data['createdAt']?.toString() ?? '';
            final joinedFormatted =
                createdAt.isNotEmpty ? createdAt.split('T').first : 'Recent';

            final password = data['password'] as String?;

            if (canonicalRole == AppRoles.serviceProvider) {
              final rawCats = data['categories'];
              List<String> providerCats = [];
              if (rawCats is List) {
                providerCats = rawCats
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              } else if (data['category'] is String &&
                  (data['category'] as String).trim().isNotEmpty) {
                providerCats = [(data['category'] as String).trim()];
              } else if (data['trade'] is String &&
                  (data['trade'] as String).trim().isNotEmpty) {
                providerCats = [(data['trade'] as String).trim()];
              }

              final trade = (data['trade'] as String?)?.trim() ??
                  (providerCats.isNotEmpty
                      ? providerCats.first
                      : 'Service Specialist');

              liveProviders.add(
                AdminProviderItem(
                  id: doc.id,
                  name: name,
                  email: email,
                  phone: phone,
                  password: password,
                  trade: trade,
                  categories: providerCats,
                  rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
                  completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
                  isVerified: isVerified,
                  joinedDate: joinedFormatted,
                ),
              );
            } else if (canonicalRole == AppRoles.customer) {
              liveCustomers.add(
                AdminCustomerItem(
                  id: doc.id,
                  name: name,
                  email: email,
                  phone: phone,
                  password: password,
                  totalBookings: (data['totalBookings'] as num?)?.toInt() ?? 0,
                  joinedDate: joinedFormatted,
                  isActive: data['isActive'] as bool? ?? true,
                ),
              );
            } else if (canonicalRole != AppRoles.admin) {
              // Unrecognized or invalid role! (e.g. 'Henil')
              unassigned.add({
                'id': doc.id,
                'name': name,
                'email': email,
                'phone': phone,
                'rawRole': rawRole ?? 'Unassigned',
              });
            }
          }

          setState(() {
            _providersList = liveProviders;
            _usersList = liveCustomers;
            _unassignedRoleUsers = unassigned;
            _isLoading = false;
            _errorMessage = null;
          });
        },
        onError: (err) {
          debugPrint('Firestore directory stream error: $err');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Could not sync Firestore data: $err';
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting directory stream: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to connect to Firebase: $e';
        });
      }
    }
  }

  Future<void> _fetchLiveDirectoryData() async {
    setState(() => _isLoading = true);
    _subscribeToLiveDirectory();
  }

  /// Live pending verification applications directly derived from unverified providers.
  List<AdminProviderItem> get _verificationQueue {
    return _providersList.where((p) => !p.isVerified).toList();
  }

  List<AdminProviderItem> get _filteredProviders {
    final query = _providerSearchQuery.trim().toLowerCase();
    List<AdminProviderItem> list = _providersList.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.trade.toLowerCase().contains(query) ||
          p.email.toLowerCase().contains(query);
    }).toList();

    switch (_providerSort) {
      case 'Name (Z-A)':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Rating (High-Low)':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Verified First':
        list.sort((a, b) {
          if (a.isVerified == b.isVerified) {
            return a.name.compareTo(b.name);
          }
          return a.isVerified ? -1 : 1;
        });
        break;
      case 'Name (A-Z)':
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  List<AdminCustomerItem> get _filteredUsers {
    final query = _userSearchQuery.trim().toLowerCase();
    List<AdminCustomerItem> list = _usersList.where((u) {
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.phone.contains(query);
    }).toList();

    switch (_userSort) {
      case 'Name (Z-A)':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Bookings (High-Low)':
        list.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
        break;
      case 'Email (A-Z)':
        list.sort((a, b) => a.email.compareTo(b.email));
        break;
      case 'Name (A-Z)':
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  /// Toggles provider verification in Cloud Firestore in real time.
  Future<void> _toggleProviderVerification(AdminProviderItem provider) async {
    try {
      final newStatus = !provider.isVerified;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(provider.id)
          .update({
        'isVerified': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        newStatus
            ? '${provider.name} is now Verified ✅'
            : 'Revoked verification for ${provider.name}',
      );
    } catch (e) {
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Failed to update verification: $e', isError: true);
    }
  }

  /// Detailed inspection dialog for a provider in the queue or directory.
  void _handleReviewDetails(AdminProviderItem provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID: ${provider.id}',
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            Text('Email: ${provider.email.isNotEmpty ? provider.email : "Not provided"}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Phone: ${provider.phone}', style: const TextStyle(fontSize: 13)),
            if (provider.password != null && provider.password!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.key_rounded, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 4),
                  Text('Password: ${provider.password}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text('Specialty: ${provider.trade}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
            const SizedBox(height: 4),
            Text('Completed Jobs: ${provider.completedJobs}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Rating: ${provider.rating.toStringAsFixed(1)} ★',
                style: const TextStyle(fontSize: 13, color: Colors.amber)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Category: ${provider.categories.isNotEmpty ? provider.categories.join(", ") : provider.trade}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAssignCategoryDialog(provider);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Change',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: provider.isVerified
                    ? AppColors.success.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.isVerified
                    ? 'Verified Service Contractor'
                    : 'Pending Verification Review',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: provider.isVerified
                      ? AppColors.success
                      : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  provider.isVerified ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _toggleProviderVerification(provider);
            },
            child: Text(
                provider.isVerified ? 'Revoke Verification' : 'Approve & Verify'),
          ),
        ],
      ),
    );
  }

  /// Dialog allowing Admin to assign one of the 8 canonical categories to a provider.
  void _showAssignCategoryDialog(AdminProviderItem provider) {
    String selectedCategory = provider.categories.isNotEmpty
        ? provider.categories.first
        : (ServiceCategory.findByNameOrTrade(provider.trade)?.name ??
            ServiceCategory.all8Categories.first.name);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.assignment_ind_rounded, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assign Category',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select one of the 8 main service categories for this provider:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                    dropdownColor: AppColors.card,
                    items: ServiceCategory.all8Categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.name,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 18, color: cat.accentColor),
                            const SizedBox(width: 10),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await _updateProviderCategoryInFirestore(
                        provider.id, selectedCategory);
                  },
                  child: const Text('Save Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProviderCategoryInFirestore(
      String uid, String newCategory) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'categories': [newCategory],
        'trade': newCategory,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Assigned $newCategory to provider ✅');
    } catch (e) {
      if (!mounted) return;
      UiHelper.showSnackBar(
          context, 'Failed to update category: $e', isError: true);
    }
  }

  /// Section allowing Admin to view and manage all 8 main service categories.
  void _showCategoryManagementDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Management',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        Text(
                          '8 main service categories & live technician distribution',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ServiceCategory.all8Categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = ServiceCategory.all8Categories[index];
                    final count = _getProviderCountForCategory(cat.id);
                    final isCatActive = _categoryStatusMap[cat.id] ?? true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat.icon,
                            color: cat.accentColor, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.secondaryText
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count Providers',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: count > 0
                                    ? AppColors.primary
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        cat.description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Switch(
                        value: isCatActive,
                        activeTrackColor: AppColors.success,
                        onChanged: (val) {
                          setModalState(() {
                            _categoryStatusMap[cat.id] = val;
                          });
                          setState(() {});
                          UiHelper.showSnackBar(
                            context,
                            val
                                ? '${cat.name} activated on platform'
                                : '${cat.name} deactivated on platform',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog allowing Admin to review and rectify accounts with unrecognized roles.
  void _showFixRoleDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Unrecognized Roles',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _unassignedRoleUsers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'All user accounts currently have strictly authorized roles (Customer, Service_Provider, or Admin)!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _unassignedRoleUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final user = _unassignedRoleUsers[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(user['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Role: "${user['rawRole']}" • ${user['email']}'),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary),
                              tooltip: 'Assign Valid Role',
                              onSelected: (newRole) async {
                                Navigator.of(dialogCtx).pop();
                                await _updateUserRoleInFirestore(
                                    user['id'], newRole);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: AppRoles.customer,
                                  child: Text('Assign as Customer'),
                                ),
                                const PopupMenuItem(
                                  value: AppRoles.serviceProvider,
                                  child: Text('Assign as Service Provider'),
                                ),
                                const PopupMenuItem(
                                  value: AppRoles.admin,
                                  child: Text('Assign as Admin'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserRoleInFirestore(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        'Updated account role to ${AppRoles.displayName(newRole)} ✅ (Active session terminated on user device)',
      );
    } catch (e) {
      if (!mounted) return;
      UiHelper.showSnackBar(context, 'Failed to update role: $e', isError: true);
    }
  }

  /// Opens a dropdown modal allowing the Admin to edit/switch a user's role
  /// (Customer, Service_Provider, Admin). Informs Admin that saving will
  /// immediately log out the user on their device and return them to Login.
  void _showChangeRoleDialog({
    required String uid,
    required String currentRole,
    required String name,
    String? email,
  }) {
    String selectedRole = AppRoles.canonicalize(currentRole) ?? AppRoles.customer;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Change User Role',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Select Assigned Role',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                    dropdownColor: AppColors.card,
                    items: const [
                      DropdownMenuItem(
                        value: AppRoles.customer,
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Customer'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppRoles.serviceProvider,
                        child: Row(
                          children: [
                            Icon(Icons.handyman_rounded, size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Service Provider'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: AppRoles.admin,
                        child: Row(
                          children: [
                            Icon(Icons.shield_rounded, size: 18, color: Color(0xFF0047AB)),
                            SizedBox(width: 8),
                            Text('Admin'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Updating role will immediately close the user's active session and redirect them to the login page on their device.",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.amber.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await _updateUserRoleInFirestore(uid, selectedRole);
                  },
                  child: const Text('Update Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final String displayName = userController.userName.isNotEmpty
        ? userController.userName
        : 'System Administrator';
    final String initialLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

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
                Navigator.of(context).pushNamed(AppRoutes.adminProfile);
              },
              child: CircleAvatar(
                radius: context.widthPct(0.048),
                backgroundColor: AppColors.card,
                child: Text(
                  initialLetter,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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
                    'WorkBridge Administration',
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
          IconButton(
            icon: const Icon(Icons.dataset_rounded, color: AppColors.card),
            tooltip: 'Data Management Hub',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.adminDataManagement);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.card),
            onPressed: () {
              UiHelper.showSnackBar(context, 'System running smoothly. No alerts.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.card),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.adminProfile);
            },
          ),
          UiHelper.horizontalSpace(context, 0.015),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 1
            ? _buildProvidersTab(context)
            : _currentIndex == 2
                ? _buildUsersTab(context)
                : _currentIndex == 3
                    ? _buildReportsTab(context)
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.widthPct(0.045),
                          vertical: context.heightPct(0.018),
                        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Hero Banner
              Container(
                width: context.widthPct(0.91),
                padding: EdgeInsets.all(context.widthPct(0.045)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002B49), Color(0xFF0047AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047AB).withValues(alpha: 0.3),
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
                            color: AppColors.card.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            'SUPER ADMIN PORTAL',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.card,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: context.respFont(10),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text(
                                'Systems Operational',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    UiHelper.verticalSpace(context, 0.015),
                    Text(
                      'Welcome, $displayName',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.card,
                        fontWeight: FontWeight.w800,
                        fontSize: context.respFont(18),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.006),
                    Text(
                      'Overview of platform transactions, provider verifications & user stats.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.card.withValues(alpha: 0.85),
                        fontSize: context.respFont(12),
                      ),
                    ),
                  ],
                ),
              ),

              if (_unassignedRoleUsers.isNotEmpty) ...[
                UiHelper.verticalSpace(context, 0.02),
                Container(
                  width: context.widthPct(0.91),
                  padding: EdgeInsets.all(context.widthPct(0.035)),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_unassignedRoleUsers.length} Account(s) with Invalid Roles',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Found accounts with unrecognized roles. Review and assign valid roles to grant platform access.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mainText,
                                fontSize: context.respFont(10.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showFixRoleDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Review'),
                      ),
                    ],
                  ),
                ),
              ],

              UiHelper.verticalSpace(context, 0.025),

              // KPI Metrics Row 1 (Live Firebase counts)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Total Customers',
                      value: _isLoading ? '...' : '${_usersList.length} Users',
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  UiHelper.horizontalSpace(context, 0.03),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Active Providers',
                      value: _isLoading
                          ? '...'
                          : '${_providersList.where((p) => p.isVerified).length} / ${_providersList.length}',
                      icon: Icons.handyman_rounded,
                      iconColor: AppColors.accent,
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.015),

              // KPI Metrics Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Verification Queue',
                      value: _isLoading ? '...' : '${_verificationQueue.length} Pending',
                      icon: Icons.pending_actions_rounded,
                      iconColor: Colors.amber.shade800,
                    ),
                  ),
                  UiHelper.horizontalSpace(context, 0.03),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Completed Jobs',
                      value: _isLoading
                          ? '...'
                          : '${_providersList.fold<int>(0, (totalJobs, p) => totalJobs + p.completedJobs)} Gigs',
                      icon: Icons.task_alt_rounded,
                      iconColor: AppColors.success,
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.028),

              // Administration Setup & Controls (Inspired by SmartAttend SetUp Details)
              Text(
                'Management & Setup Modules',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: context.respFont(16),
                ),
              ),

              UiHelper.verticalSpace(context, 0.015),

              // Modular Management Grid (4 Modules in 2 Rows)
              Row(
                children: [
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Manage\nProviders',
                      icon: Icons.engineering_rounded,
                      color: const Color(0xFF0047AB),
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                  UiHelper.horizontalSpace(context, 0.03),
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Manage\nCustomers',
                      icon: Icons.group_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        setState(() => _currentIndex = 2);
                      },
                    ),
                  ),
                ],
              ),
              UiHelper.verticalSpace(context, 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Category\nManagement',
                      icon: Icons.category_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: _showCategoryManagementDialog,
                    ),
                  ),
                  UiHelper.horizontalSpace(context, 0.03),
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Role Audit\n& Security',
                      icon: Icons.security_rounded,
                      color: Colors.teal.shade700,
                      onTap: _showFixRoleDialog,
                    ),
                  ),
                ],
              ),
              UiHelper.verticalSpace(context, 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Data\nManagement',
                      icon: Icons.dataset_rounded,
                      color: const Color(0xFF002B49),
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.adminDataManagement);
                      },
                    ),
                  ),
                  UiHelper.horizontalSpace(context, 0.03),
                  Expanded(
                    child: _buildModuleTile(
                      context,
                      title: 'Quick Add\nCustomer',
                      icon: Icons.person_add_rounded,
                      color: AppColors.accent,
                      onTap: () {
                        UiHelper.showAddCustomerDialog(
                          context,
                          onCustomerAdded: _fetchLiveDirectoryData,
                        );
                      },
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.028),

              // Platform Service Categories Overview (All 8 Categories)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Service Categories',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: context.respFont(15.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '8 main service categories & technician coverage',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: context.respFont(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showCategoryManagementDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage All (8)',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: context.respFont(11.5),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: context.respFont(10),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.015),

              // 8 Categories Overview Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ServiceCategory.all8Categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.74,
                ),
                itemBuilder: (context, index) {
                  final cat = ServiceCategory.all8Categories[index];
                  final count = _getProviderCountForCategory(cat.id);
                  final isCatActive = _categoryStatusMap[cat.id] ?? true;

                  return InkWell(
                    onTap: _showCategoryManagementDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: context.widthPct(0.16),
                              height: context.widthPct(0.16),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCatActive
                                      ? AppColors.border
                                      : AppColors.error.withValues(alpha: 0.5),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x060F172A),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  cat.icon,
                                  color: isCatActive
                                      ? cat.accentColor
                                      : AppColors.secondaryText,
                                  size: context.respFont(23),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? AppColors.primary
                                      : AppColors.secondaryText,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.card, width: 1.5),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        UiHelper.verticalSpace(context, 0.006),
                        SizedBox(
                          width: context.widthPct(0.2),
                          child: Text(
                            cat.name,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCatActive
                                  ? AppColors.mainText
                                  : AppColors.secondaryText,
                              fontSize: context.respFont(10.5),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              UiHelper.verticalSpace(context, 0.028),

              // Pending Provider Verifications Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Provider Verification Queue',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_verificationQueue.length} Pending Review',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w700,
                        fontSize: context.respFont(11),
                      ),
                    ),
                  ),
                ],
              ),

              UiHelper.verticalSpace(context, 0.015),

              // Verification List
              if (_verificationQueue.isEmpty)
                Container(
                  width: context.widthPct(0.91),
                  padding: EdgeInsets.all(context.widthPct(0.06)),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppColors.success, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'All verifications processed!',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'No provider applications awaiting administrative action.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _verificationQueue.length,
                  separatorBuilder: (_, __) =>
                      UiHelper.verticalSpace(context, 0.012),
                  itemBuilder: (context, index) {
                    final item = _verificationQueue[index];
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
                                  item.name,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontSize: context.respFont(14),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.joinedDate,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondaryText,
                                  fontSize: context.respFont(10.5),
                                ),
                              ),
                            ],
                          ),
                          UiHelper.verticalSpace(context, 0.004),
                          Text(
                            item.trade,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: context.respFont(12),
                            ),
                          ),
                          UiHelper.verticalSpace(context, 0.004),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  size: 14, color: AppColors.secondaryText),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.email.isNotEmpty ? item.email : 'No email provided',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          UiHelper.verticalSpace(context, 0.012),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.border, width: 1.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _handleReviewDetails(item),
                                  child: const Text('Inspect'),
                                ),
                              ),
                              UiHelper.horizontalSpace(context, 0.03),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.card,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _toggleProviderVerification(item),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              UiHelper.verticalSpace(context, 0.025),

              // Admin Profile Shortcut Card
              UiHelper.customCard(
                context: context,
                widthFraction: 0.91,
                padding: EdgeInsets.all(context.widthPct(0.04)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.widthPct(0.025)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047AB).withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF0047AB),
                      ),
                    ),
                    UiHelper.horizontalSpace(context, 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Profile',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: context.respFont(14),
                            ),
                          ),
                          Text(
                            'System credentials, security & master configurations',
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
                        Navigator.of(context).pushNamed(AppRoutes.adminProfile);
                      },
                    ),
                  ],
                ),
              ),

              UiHelper.verticalSpace(context, 0.02),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamed(AppRoutes.adminProfile);
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
            icon: Icon(Icons.engineering_rounded),
            label: 'Providers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
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
              fontSize: context.respFont(17.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.heightPct(0.018),
          horizontal: context.widthPct(0.02),
        ),
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: context.respFont(22)),
            ),
            UiHelper.verticalSpace(context, 0.01),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: context.respFont(11),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Providers Directory ──────────────────────────────────────────

  Widget _buildProvidersTab(BuildContext context) {
    final filtered = _filteredProviders;

    return RefreshIndicator(
      onRefresh: _fetchLiveDirectoryData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.widthPct(0.045),
          vertical: context.heightPct(0.018),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Providers',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: context.respFont(17.5),
                        ),
                      ),
                      Text(
                        'Live Firestore technician directory & status',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: context.respFont(11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Text(
                    _isLoading ? 'Syncing...' : '${filtered.length} Providers',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: context.respFont(11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => UiHelper.showAddCustomerDialog(
                    context,
                    onCustomerAdded: _fetchLiveDirectoryData,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.card,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              UiHelper.verticalSpace(context, 0.012),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLiveDirectoryData,
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            UiHelper.verticalSpace(context, 0.015),
            UiHelper.searchAndSortBar(
              context: context,
              controller: _providerSearchController,
              hintText: 'Search provider or trade...',
              selectedSort: _providerSort,
              sortOptions: _providerSortOptions,
              onChanged: (val) {
                setState(() => _providerSearchQuery = val);
              },
              onClear: () {
                setState(() {
                  _providerSearchController.clear();
                  _providerSearchQuery = '';
                });
              },
              onSortChanged: (newSort) {
                setState(() => _providerSort = newSort);
              },
            ),
            UiHelper.verticalSpace(context, 0.015),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.heightPct(0.08)),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: AppColors.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _providersList.isEmpty
                            ? 'No registered service providers found in Firestore'
                            : 'No matching service providers found',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => UiHelper.verticalSpace(context, 0.012),
                itemBuilder: (context, index) {
                  return _buildProviderCard(context, filtered[index]);
                },
              ),
            UiHelper.verticalSpace(context, 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, AdminProviderItem provider) {
    return UiHelper.customCard(
      context: context,
      widthFraction: 0.91,
      padding: EdgeInsets.all(context.widthPct(0.04)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: context.widthPct(0.052),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
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
                            provider.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: context.respFont(14.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider.isVerified
                                ? AppColors.success.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.isVerified
                                    ? Icons.verified_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 13,
                                color: provider.isVerified
                                    ? AppColors.success
                                    : Colors.amber.shade900,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                provider.isVerified ? 'Verified' : 'Pending',
                                style: TextStyle(
                                  fontSize: context.respFont(10),
                                  fontWeight: FontWeight.w700,
                                  color: provider.isVerified
                                      ? AppColors.success
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    UiHelper.verticalSpace(context, 0.004),
                    Text(
                      provider.trade,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: context.respFont(12),
                      ),
                    ),
                    UiHelper.verticalSpace(context, 0.002),
                    Text(
                      provider.email.isNotEmpty ? provider.email : 'No email provided',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: context.respFont(11),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          UiHelper.verticalSpace(context, 0.012),
          const Divider(height: 1, color: AppColors.border),
          UiHelper.verticalSpace(context, 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    provider.rating.toStringAsFixed(1),
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${provider.completedJobs} Jobs',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.manage_accounts_outlined, size: 20, color: AppColors.accent),
                    tooltip: 'Change Role',
                    onPressed: () => _showChangeRoleDialog(
                      uid: provider.id,
                      currentRole: AppRoles.serviceProvider,
                      name: provider.name,
                      email: provider.email,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                    tooltip: 'Inspect Provider Details',
                    onPressed: () => _handleReviewDetails(provider),
                  ),
                  IconButton(
                    icon: Icon(
                      provider.isVerified ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: provider.isVerified ? AppColors.success : AppColors.secondaryText,
                    ),
                    tooltip: provider.isVerified ? 'Revoke Verification' : 'Verify Provider',
                    onPressed: () => _toggleProviderVerification(provider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Users Directory ──────────────────────────────────────────────

  Widget _buildUsersTab(BuildContext context) {
    final filtered = _filteredUsers;

    return RefreshIndicator(
      onRefresh: _fetchLiveDirectoryData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.widthPct(0.045),
          vertical: context.heightPct(0.018),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Directory',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: context.respFont(17.5),
                        ),
                      ),
                      Text(
                        'Live Firestore customer directory & activity',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: context.respFont(11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  child: Text(
                    _isLoading ? 'Syncing...' : '${filtered.length} Customers',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: context.respFont(11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => UiHelper.showAddCustomerDialog(
                    context,
                    onCustomerAdded: _fetchLiveDirectoryData,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.card,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              UiHelper.verticalSpace(context, 0.012),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLiveDirectoryData,
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            UiHelper.verticalSpace(context, 0.015),
            UiHelper.searchAndSortBar(
              context: context,
              controller: _userSearchController,
              hintText: 'Search customer name or email...',
              selectedSort: _userSort,
              sortOptions: _userSortOptions,
              onChanged: (val) {
                setState(() => _userSearchQuery = val);
              },
              onClear: () {
                setState(() {
                  _userSearchController.clear();
                  _userSearchQuery = '';
                });
              },
              onSortChanged: (newSort) {
                setState(() => _userSort = newSort);
              },
            ),
            UiHelper.verticalSpace(context, 0.015),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.heightPct(0.08)),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: AppColors.secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _usersList.isEmpty
                            ? 'No customer accounts found in Firestore'
                            : 'No matching customer accounts found',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => UiHelper.verticalSpace(context, 0.012),
                itemBuilder: (context, index) {
                  return _buildCustomerCard(context, filtered[index]);
                },
              ),
            UiHelper.verticalSpace(context, 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, AdminCustomerItem customer) {
    return UiHelper.customCard(
      context: context,
      widthFraction: 0.91,
      padding: EdgeInsets.all(context.widthPct(0.04)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: context.widthPct(0.052),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              UiHelper.horizontalSpace(context, 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: context.respFont(14.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${customer.totalBookings} Bookings',
                            style: TextStyle(
                              fontSize: context.respFont(10),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    UiHelper.verticalSpace(context, 0.004),
                    Text(
                      customer.email.isNotEmpty ? customer.email : 'No email provided',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: context.respFont(12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          UiHelper.verticalSpace(context, 0.012),
          const Divider(height: 1, color: AppColors.border),
          UiHelper.verticalSpace(context, 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.phone,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.manage_accounts_outlined, size: 20, color: AppColors.accent),
                    tooltip: 'Change Role',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showChangeRoleDialog(
                      uid: customer.id,
                      currentRole: AppRoles.customer,
                      name: customer.name,
                      email: customer.email,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    'Joined ${customer.joinedDate}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Reports ──────────────────────────────────────────────────────

  Widget _buildReportsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPct(0.045),
        vertical: context.heightPct(0.018),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational Reports',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: context.respFont(18),
            ),
          ),
          Text(
            'Platform usage statistics, transaction audit & uptime logs',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          UiHelper.verticalSpace(context, 0.02),
          UiHelper.customCard(
            context: context,
            widthFraction: 0.91,
            padding: EdgeInsets.all(context.widthPct(0.045)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gig Completion Rate',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '96.4%',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                UiHelper.verticalSpace(context, 0.015),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.964,
                    backgroundColor: AppColors.border,
                    color: AppColors.success,
                    minHeight: 8,
                  ),
                ),
                UiHelper.verticalSpace(context, 0.015),
                Text(
                  '8,600 successful gigs executed out of 8,920 total requests.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          UiHelper.verticalSpace(context, 0.018),
          UiHelper.customCard(
            context: context,
            widthFraction: 0.91,
            padding: EdgeInsets.all(context.widthPct(0.045)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Satisfaction Index',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '4.88 / 5.0',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                UiHelper.verticalSpace(context, 0.015),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 4.88 / 5.0,
                    backgroundColor: AppColors.border,
                    color: Colors.amber.shade700,
                    minHeight: 8,
                  ),
                ),
                UiHelper.verticalSpace(context, 0.015),
                Text(
                  'Based on 3,420 customer gig ratings and reviews.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          UiHelper.verticalSpace(context, 0.02),

          // Live Platform Service Requests Audit
          Text(
            'Live Platform Service Requests',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: context.respFont(16),
            ),
          ),
          Text(
            'Real-time feed of all service requests across customers & providers',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          UiHelper.verticalSpace(context, 0.015),

          StreamBuilder<List<ServiceRequestModel>>(
            stream: ServiceRequestService().streamAllRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ));
              }

              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Container(
                  width: context.widthPct(0.91),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No service requests recorded in the platform yet.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.take(10).length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final req = requests[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: req.isBroadcast
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : Colors.purple.withValues(alpha: 0.15),
                          child: Icon(
                            req.isBroadcast ? Icons.cell_tower_rounded : Icons.person_pin_rounded,
                            size: 18,
                            color: req.isBroadcast ? AppColors.accent : Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.serviceTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.customerName} • ${req.categoryName} • ${AppCurrency.symbol}${req.estimatedAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                              ),
                              if (req.assignedProviderName != null && req.assignedProviderName!.isNotEmpty)
                                Text(
                                  'Assigned: ${req.assignedProviderName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: req.isCompleted
                                ? AppColors.success.withValues(alpha: 0.12)
                                : req.isAccepted
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                    : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            RequestStatus.displayName(req.status),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: req.isCompleted
                                  ? AppColors.success
                                  : req.isAccepted
                                      ? const Color(0xFF0284C7)
                                      : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          UiHelper.verticalSpace(context, 0.02),
        ],
      ),
    );
  }
}
