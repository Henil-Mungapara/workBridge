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
