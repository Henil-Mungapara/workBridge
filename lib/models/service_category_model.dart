import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Domain model representing a service category in WorkBridge.
class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final int providerCount;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.accent,
    this.isActive = true,
    this.providerCount = 0,
  });

  /// The 8 canonical service categories for WorkBridge.
  static const List<ServiceCategory> all8Categories = [
    ServiceCategory(
      id: 'plumbing',
      name: 'Plumbing',
      description: 'Pipe leak repairs, bathroom fittings, tap fixing & drain cleaning',
      icon: Icons.plumbing_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    ServiceCategory(
      id: 'electrical',
      name: 'Electrical',
      description: 'Wiring, switchboard replacement, fixtures & circuit troubleshooting',
      icon: Icons.electrical_services_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    ServiceCategory(
      id: 'carpentry',
      name: 'Carpentry',
      description: 'Furniture repair, modular woodwork, door locks & custom cabinetry',
      icon: Icons.carpenter_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    ServiceCategory(
      id: 'painting',
      name: 'Painting',
      description: 'Interior wall painting, exterior coating, waterproofing & wall putty',
      icon: Icons.format_paint_rounded,
      accentColor: Color(0xFFEC4899),
    ),
    ServiceCategory(
      id: 'home_cleaning',
      name: 'Home Cleaning',
      description: 'Deep house cleaning, kitchen scrubbing, bathroom & sofa sanitization',
      icon: Icons.cleaning_services_rounded,
      accentColor: Color(0xFF10B981),
    ),
    ServiceCategory(
      id: 'appliance_repair',
      name: 'Appliance Repair',
      description: 'AC servicing, refrigerator, microwave & washing machine repair',
      icon: Icons.home_repair_service_rounded,
      accentColor: Color(0xFF00A896),
    ),
    ServiceCategory(
      id: 'salon_beauty',
      name: 'Salon & Beauty',
      description: 'Hair styling, facial treatments, manicure, pedicure & grooming at home',
      icon: Icons.face_retouching_natural_rounded,
      accentColor: Color(0xFFF43F5E),
    ),
    ServiceCategory(
      id: 'vehicle_services',
      name: 'Vehicle Services',
      description: 'Car & bike maintenance, oil check, battery inspection & roadside assist',
      icon: Icons.directions_car_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
  ];

  /// Resolves any trade/category string to one of the 8 canonical categories,
  /// or null if no confident match.
  static ServiceCategory? findByNameOrTrade(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final query = raw.trim().toLowerCase();

    for (final category in all8Categories) {
      if (category.name.toLowerCase() == query || category.id.toLowerCase() == query) {
        return category;
      }
    }

    // Heuristic keyword matching for legacy trades or custom descriptions
    if (query.contains('plumb') || query.contains('pipe') || query.contains('leak')) {
      return all8Categories[0]; // Plumbing
    }
    if (query.contains('elect') || query.contains('wire') || query.contains('circuit')) {
      return all8Categories[1]; // Electrical
    }
    if (query.contains('carpent') || query.contains('wood') || query.contains('furnit')) {
      return all8Categories[2]; // Carpentry
    }
    if (query.contains('paint') || query.contains('wall') || query.contains('waterproof')) {
      return all8Categories[3]; // Painting
    }
    if (query.contains('clean') || query.contains('saniti') || query.contains('maid')) {
      return all8Categories[4]; // Home Cleaning
    }
    if (query.contains('appliance') || query.contains('ac') || query.contains('fridge') || query.contains('refrigerat')) {
      return all8Categories[5]; // Appliance Repair
    }
    if (query.contains('salon') || query.contains('beauty') || query.contains('hair') || query.contains('groom')) {
      return all8Categories[6]; // Salon & Beauty
    }
    if (query.contains('vehicle') || query.contains('car') || query.contains('bike') || query.contains('auto')) {
      return all8Categories[7]; // Vehicle Services
    }

    return null;
  }

  /// Filters the 8 canonical categories to only those assigned to a provider.
  /// If [assigned] has raw strings or trades, it maps them.
  static List<ServiceCategory> filterAssigned(List<String> assigned) {
    if (assigned.isEmpty) return const [];

    final Set<String> matchedIds = {};
    final List<ServiceCategory> result = [];

    for (final raw in assigned) {
      final match = findByNameOrTrade(raw);
      if (match != null && !matchedIds.contains(match.id)) {
        matchedIds.add(match.id);
        result.add(match);
      }
    }

    return result;
  }

  static const Map<String, IconData> iconMap = {
    'plumbing': Icons.plumbing_rounded,
    'electrical': Icons.electrical_services_rounded,
    'carpentry': Icons.carpenter_rounded,
    'painting': Icons.format_paint_rounded,
    'home_cleaning': Icons.cleaning_services_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'appliance_repair': Icons.home_repair_service_rounded,
    'appliance': Icons.home_repair_service_rounded,
    'salon_beauty': Icons.face_retouching_natural_rounded,
    'salon': Icons.face_retouching_natural_rounded,
    'beauty': Icons.face_retouching_natural_rounded,
    'vehicle_services': Icons.directions_car_rounded,
    'vehicle': Icons.directions_car_rounded,
    'pest_control': Icons.bug_report_rounded,
    'gardening': Icons.yard_rounded,
    'construction': Icons.foundation_rounded,
    'handyman': Icons.handyman_rounded,
    'security': Icons.security_rounded,
    'moving': Icons.local_shipping_rounded,
    'roofing': Icons.roofing_rounded,
    'locksmith': Icons.lock_clock_rounded,
    'category': Icons.category_rounded,
  };

  static const List<Map<String, dynamic>> availableIcons = [
    {'key': 'plumbing', 'name': 'Plumbing', 'icon': Icons.plumbing_rounded},
    {'key': 'electrical', 'name': 'Electrical', 'icon': Icons.electrical_services_rounded},
    {'key': 'carpentry', 'name': 'Carpentry', 'icon': Icons.carpenter_rounded},
    {'key': 'painting', 'name': 'Painting', 'icon': Icons.format_paint_rounded},
    {'key': 'home_cleaning', 'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded},
    {'key': 'appliance_repair', 'name': 'Appliance', 'icon': Icons.home_repair_service_rounded},
    {'key': 'salon_beauty', 'name': 'Salon & Beauty', 'icon': Icons.face_retouching_natural_rounded},
    {'key': 'vehicle_services', 'name': 'Vehicle Services', 'icon': Icons.directions_car_rounded},
    {'key': 'pest_control', 'name': 'Pest Control', 'icon': Icons.bug_report_rounded},
    {'key': 'gardening', 'name': 'Gardening & Lawn', 'icon': Icons.yard_rounded},
    {'key': 'construction', 'name': 'Construction & Masonry', 'icon': Icons.foundation_rounded},
    {'key': 'handyman', 'name': 'General Handyman', 'icon': Icons.handyman_rounded},
    {'key': 'security', 'name': 'Security & CCTV', 'icon': Icons.security_rounded},
    {'key': 'moving', 'name': 'Packing & Moving', 'icon': Icons.local_shipping_rounded},
    {'key': 'roofing', 'name': 'Roofing & Waterproofing', 'icon': Icons.roofing_rounded},
    {'key': 'locksmith', 'name': 'Locksmith & Keys', 'icon': Icons.lock_clock_rounded},
    {'key': 'category', 'name': 'General Service', 'icon': Icons.category_rounded},
  ];

  static const List<Map<String, dynamic>> availableColors = [
    {'name': 'WorkBridge Cyan', 'color': Color(0xFF00B4D8), 'hex': '#00B4D8'},
    {'name': 'Ocean Blue', 'color': Color(0xFF0284C7), 'hex': '#0284C7'},
    {'name': 'Amber Gold', 'color': Color(0xFFF59E0B), 'hex': '#F59E0B'},
    {'name': 'Midnight Navy', 'color': Color(0xFF0A192F), 'hex': '#0A192F'},
    {'name': 'Vibrant Pink', 'color': Color(0xFFEC4899), 'hex': '#EC4899'},
    {'name': 'Emerald Green', 'color': Color(0xFF10B981), 'hex': '#10B981'},
    {'name': 'Teal', 'color': Color(0xFF00A896), 'hex': '#00A896'},
    {'name': 'Rose Red', 'color': Color(0xFFF43F5E), 'hex': '#F43F5E'},
    {'name': 'Royal Blue', 'color': Color(0xFF3B82F6), 'hex': '#3B82F6'},
    {'name': 'Sapphire Blue', 'color': Color(0xFF0047AB), 'hex': '#0047AB'},
  ];

  static IconData iconFromKey(String? key) {
    if (key == null || key.trim().isEmpty) return Icons.category_rounded;
    final k = key.trim().toLowerCase();
    return iconMap[k] ?? Icons.category_rounded;
  }

  static String keyFromIcon(IconData icon) {
    for (final entry in iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return 'category';
  }

  static Color colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.accent;
    String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '');
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final int? value = int.tryParse(cleanHex, radix: 16);
    return value != null ? Color(value) : AppColors.accent;
  }

  static String hexFromColor(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Deserializes a [ServiceCategory] from a Cloud Firestore document map.
  factory ServiceCategory.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? map['id']?.toString() ?? '';
    final name = (map['name'] as String?)?.trim() ?? '';
    final desc = (map['description'] as String?)?.trim() ?? '';
    final isActive = map['isActive'] as bool? ?? true;
    final pCount = (map['providerCount'] as num?)?.toInt() ?? 0;

    final canonical = findByNameOrTrade(name.isNotEmpty ? name : id);

    final rawIcon = map['iconName']?.toString() ?? map['icon']?.toString() ?? id;
    final rawColor = map['accentColorHex']?.toString() ?? map['color']?.toString();

    final resolvedIcon = iconFromKey(rawIcon);
    final icon = (resolvedIcon != Icons.category_rounded)
        ? resolvedIcon
        : (canonical?.icon ?? Icons.category_rounded);

    final color = (rawColor != null && rawColor.isNotEmpty)
        ? colorFromHex(rawColor)
        : (canonical?.accentColor ?? AppColors.accent);

    return ServiceCategory(
      id: id.isNotEmpty ? id : (canonical?.id ?? name.toLowerCase().replaceAll(' ', '_')),
      name: name.isNotEmpty ? name : (canonical?.name ?? 'Category'),
      description: desc.isNotEmpty ? desc : (canonical?.description ?? 'Professional service category'),
      icon: icon,
      accentColor: color,
      isActive: isActive,
      providerCount: pCount,
    );
  }

  /// Converts this [ServiceCategory] into a Map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': keyFromIcon(icon),
      'accentColorHex': hexFromColor(accentColor),
      'isActive': isActive,
      'providerCount': providerCount,
    };
  }

  ServiceCategory copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? accentColor,
    bool? isActive,
    int? providerCount,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      isActive: isActive ?? this.isActive,
      providerCount: providerCount ?? this.providerCount,
    );
  }
}
