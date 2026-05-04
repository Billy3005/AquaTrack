import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/log_drink/widgets/drink_type_chips.dart';
import 'features/log_drink/widgets/amount_stepper.dart';
import 'features/log_drink/widgets/log_preview_card.dart';

/// Test UI components without backend
void main() {
  runApp(const ProviderScope(child: TestUIApp()));
}

class TestUIApp extends StatelessWidget {
  const TestUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaTrack UI Test',
      theme: AppTheme.darkTheme,
      home: const ComponentTestScreen(),
    );
  }
}

class ComponentTestScreen extends StatefulWidget {
  const ComponentTestScreen({super.key});

  @override
  State<ComponentTestScreen> createState() => _ComponentTestScreenState();
}

class _ComponentTestScreenState extends State<ComponentTestScreen> {
  String selectedDrinkType = 'water';
  int currentAmount = 250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A), // navy
              Color(0xFF1B263B), // lighter navy
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Phase 3 UI Components Test',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Drink Type Chips Test
                  const Text(
                    '🧩 Drink Type Chips',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  DrinkTypeChips(
                    selectedType: selectedDrinkType,
                    onTypeSelected: (type) {
                      setState(() {
                        selectedDrinkType = type;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Amount Stepper Test
                  const Text(
                    '🔢 Amount Stepper',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  AmountStepper(
                    currentAmount: currentAmount,
                    onAmountChanged: (amount) {
                      setState(() {
                        currentAmount = amount;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Preview Card Test
                  const Text(
                    '📋 Preview Card',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  LogPreviewCard(
                    amountMl: currentAmount,
                    drinkType: selectedDrinkType,
                    effectiveAmount:
                        _getEffectiveAmount(currentAmount, selectedDrinkType),
                    xpGained: 10,
                  ),
                  const SizedBox(height: 32),

                  // Test Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Phase 3 UI Components Working!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try interacting with the components above',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getEffectiveAmount(int amount, String drinkType) {
    const coefficients = {
      'water': 1.0,
      'tea': 0.9,
      'coffee': 0.8,
      'juice': 0.85,
      'smoothie': 0.9,
    };
    final coeff = coefficients[drinkType] ?? 1.0;
    return (amount * coeff).round();
  }
}
