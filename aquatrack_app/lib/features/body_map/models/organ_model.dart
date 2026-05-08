import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Organ information and state model
class OrganInfo {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String hydrationEffect;
  final Color primaryColor;
  final Color dehydratedColor;
  final double priority; // 0.0-1.0, higher = more affected by dehydration

  const OrganInfo({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.hydrationEffect,
    required this.primaryColor,
    required this.dehydratedColor,
    required this.priority,
  });
}

/// Organ hydration state
enum OrganState {
  critical, // < 30% hydration
  poor, // 30-50% hydration
  fair, // 50-70% hydration
  good, // 70-85% hydration
  excellent, // 85%+ hydration
}

/// Organ health data
class OrganHealth {
  final OrganInfo organ;
  final OrganState state;
  final double hydrationLevel; // 0.0-1.0
  final Color currentColor;
  final String statusMessage;

  const OrganHealth({
    required this.organ,
    required this.state,
    required this.hydrationLevel,
    required this.currentColor,
    required this.statusMessage,
  });

  /// Create organ health from hydration level
  factory OrganHealth.fromHydration({
    required OrganInfo organ,
    required double hydrationLevel,
  }) {
    final adjustedLevel = _calculateAdjustedLevel(
      hydrationLevel,
      organ.priority,
    );
    final state = _calculateState(adjustedLevel);
    final color = _calculateColor(organ, adjustedLevel);
    final message = _getStatusMessage(organ, state);

    return OrganHealth(
      organ: organ,
      state: state,
      hydrationLevel: adjustedLevel,
      currentColor: color,
      statusMessage: message,
    );
  }

  /// Calculate adjusted hydration level based on organ priority
  static double _calculateAdjustedLevel(double baseLevel, double priority) {
    // Organs with higher priority are more sensitive to dehydration
    final sensitivity = 0.3 + (priority * 0.7);
    return (baseLevel * sensitivity).clamp(0.0, 1.0);
  }

  /// Calculate organ state from hydration level
  static OrganState _calculateState(double level) {
    if (level >= 0.85) return OrganState.excellent;
    if (level >= 0.70) return OrganState.good;
    if (level >= 0.50) return OrganState.fair;
    if (level >= 0.30) return OrganState.poor;
    return OrganState.critical;
  }

  /// Calculate organ color based on hydration level
  static Color _calculateColor(OrganInfo organ, double level) {
    if (level >= 0.85) {
      return organ.primaryColor;
    } else if (level >= 0.70) {
      return Color.lerp(organ.primaryColor, organ.dehydratedColor, 0.2)!;
    } else if (level >= 0.50) {
      return Color.lerp(organ.primaryColor, organ.dehydratedColor, 0.5)!;
    } else if (level >= 0.30) {
      return Color.lerp(organ.primaryColor, organ.dehydratedColor, 0.7)!;
    } else {
      return organ.dehydratedColor;
    }
  }

  /// Get status message for organ
  static String _getStatusMessage(OrganInfo organ, OrganState state) {
    switch (state) {
      case OrganState.excellent:
        return '${organ.name} hoạt động tối ưu!';
      case OrganState.good:
        return '${organ.name} khỏe mạnh';
      case OrganState.fair:
        return '${organ.name} cần thêm nước';
      case OrganState.poor:
        return '${organ.name} đang thiếu nước';
      case OrganState.critical:
        return '${organ.name} cần bù nước gấp!';
    }
  }
}

/// Default organ definitions
class DefaultOrgans {
  static const List<OrganInfo> all = [
    OrganInfo(
      id: 'brain',
      name: 'Não bộ',
      nameEn: 'Brain',
      description: 'Trung tâm điều khiển cơ thể, cần 20% lượng nước trong máu.',
      hydrationEffect: 'Thiếu nước gây mệt mỏi, giảm tập trung và đau đầu.',
      primaryColor: AppColors.organBrain,
      dehydratedColor: Color(0xFF8D6E63),
      priority: 1.0, // Highest priority
    ),
    OrganInfo(
      id: 'heart',
      name: 'Tim',
      nameEn: 'Heart',
      description: 'Bơm máu và oxy khắp cơ thể, cần nước để duy trì huyết áp.',
      hydrationEffect: 'Thiếu nước làm tăng nhịp tim và giảm hiệu suất.',
      primaryColor: AppColors.organHeart,
      dehydratedColor: Color(0xFF8D4A47),
      priority: 0.95,
    ),
    OrganInfo(
      id: 'kidneys',
      name: 'Thận',
      nameEn: 'Kidneys',
      description: 'Lọc độc tố và điều hòa nước trong cơ thể.',
      hydrationEffect: 'Thiếu nước làm giảm chức năng lọc và tích tụ độc tố.',
      primaryColor: AppColors.organKidney,
      dehydratedColor: Color(0xFF5D7999),
      priority: 0.9,
    ),
    OrganInfo(
      id: 'liver',
      name: 'Gan',
      nameEn: 'Liver',
      description: 'Chuyển hóa chất dinh dưỡng và giải độc cơ thể.',
      hydrationEffect: 'Thiếu nước làm chậm quá trình trao đổi chất.',
      primaryColor: Color(0xFF8BC34A),
      dehydratedColor: Color(0xFF6D8C3A),
      priority: 0.8,
    ),
    OrganInfo(
      id: 'skin',
      name: 'Da',
      nameEn: 'Skin',
      description: 'Lớp bảo vệ đầu tiên, chứa 64% nước cơ thể.',
      hydrationEffect: 'Thiếu nước gây khô da, mất độ đàn hồi và lão hóa.',
      primaryColor: AppColors.organSkin,
      dehydratedColor: Color(0xFF7A4A7A),
      priority: 0.7,
    ),
    OrganInfo(
      id: 'lungs',
      name: 'Phổi',
      nameEn: 'Lungs',
      description: 'Trao đổi khí và duy trì độ ẩm đường hô hấp.',
      hydrationEffect:
          'Thiếu nước làm khô đường hô hấp và giảm khả năng trao đổi khí.',
      primaryColor: Color(0xFF64B5F6),
      dehydratedColor: Color(0xFF4A7A8C),
      priority: 0.75,
    ),
    OrganInfo(
      id: 'muscles',
      name: 'Cơ bắp',
      nameEn: 'Muscles',
      description: 'Chứa 76% nước, cần thiết cho co bóp cơ.',
      hydrationEffect: 'Thiếu nước gây chuột rút và giảm sức mạnh cơ bắp.',
      primaryColor: Color(0xFFFF8A65),
      dehydratedColor: Color(0xFF8C5A47),
      priority: 0.65,
    ),
    OrganInfo(
      id: 'stomach',
      name: 'Dạ dày',
      nameEn: 'Stomach',
      description: 'Tiêu hóa thức ăn và hấp thụ chất dinh dưỡng.',
      hydrationEffect: 'Thiếu nước làm chậm quá trình tiêu hóa.',
      primaryColor: Color(0xFFFFB74D),
      dehydratedColor: Color(0xFF8C6A3D),
      priority: 0.6,
    ),
  ];

  /// Get organ by ID
  static OrganInfo? getById(String id) {
    try {
      return all.firstWhere((organ) => organ.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get organs sorted by priority (most critical first)
  static List<OrganInfo> getByPriority() {
    final sorted = List<OrganInfo>.from(all);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }
}
