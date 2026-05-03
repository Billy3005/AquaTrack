import 'package:flutter/material.dart';

/// Drink type with hydration coefficient and UI properties
enum DrinkType {
  water('water', 'Nước lọc', Icons.water_drop, 1.0),
  tea('tea', 'Trà', Icons.emoji_food_beverage, 0.9),
  coffee('coffee', 'Cà phê', Icons.local_cafe, 0.8),
  juice('juice', 'Nước ép', Icons.local_drink, 0.85),
  smoothie('smoothie', 'Sinh tố', Icons.blender, 0.9);

  const DrinkType(this.id, this.displayName, this.icon, this.hydrationCoeff);

  final String id;
  final String displayName;
  final IconData icon;
  final double hydrationCoeff;

  /// Get DrinkType from id
  static DrinkType fromId(String id) {
    return values.firstWhere(
      (type) => type.id == id,
      orElse: () => DrinkType.water,
    );
  }

  /// Calculate effective amount with hydration coefficient
  int getEffectiveAmount(int originalAmount) {
    return (originalAmount * hydrationCoeff).round();
  }
}
