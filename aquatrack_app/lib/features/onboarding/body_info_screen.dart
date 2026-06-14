import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/utils/logger.dart';
import '../../shared/widgets/living_drop.dart';
import '../auth/presentation/providers/auth_providers.dart';
import '../profile/providers/profile_provider.dart';

/// Body Info Onboarding Screen - 5-step wizard after registration
/// Collects user body information to calculate daily water goal
class BodyInfoScreen extends ConsumerStatefulWidget {
  const BodyInfoScreen({super.key});

  @override
  ConsumerState<BodyInfoScreen> createState() => _BodyInfoScreenState();
}

class _BodyInfoScreenState extends ConsumerState<BodyInfoScreen> {
  int currentStep = 0;
  bool _isSubmitting = false;

  // User data
  final Map<String, dynamic> data = {
    'gender': 'male',
    'age': 28,
    'height': 168.0,
    'weight': 60.0,
    'activity': 'moderate',
    'work': 'office',
    'health': ['none'],
    'veg': 'mid',
    'coffee': 1,
    'alcohol': 0,
  };

  final UserRepository _userRepository = UserRepository();

  final List<OnboardingStep> steps = [
    OnboardingStep(
      id: 'body',
      title: 'Đôi nét về bạn',
      subtitle: 'Để AquaTrack tính nhu cầu nước chính xác',
    ),
    OnboardingStep(
      id: 'lifestyle',
      title: 'Nhịp sống',
      subtitle: 'Bạn vận động và làm việc thế nào?',
    ),
    OnboardingStep(
      id: 'health',
      title: 'Sức khỏe',
      subtitle: 'Có điều gì cần đặc biệt lưu ý không?',
    ),
    OnboardingStep(
      id: 'diet',
      title: 'Thói quen ăn uống',
      subtitle: 'Rau, cà phê, rượu bia hằng ngày',
    ),
    OnboardingStep(
      id: 'review',
      title: 'Mục tiêu của bạn',
      subtitle: 'AI đã tính toán dựa trên dữ liệu',
    ),
  ];

  bool get isLastStep => currentStep == steps.length - 1;

  Future<void> nextStep() async {
    if (isLastStep) {
      await _submitOnboardingData();
    } else {
      setState(() {
        currentStep++;
      });
    }
  }

  /// Submit onboarding data to backend
  Future<void> _submitOnboardingData() async {
    setState(() {
      _isSubmitting = true;
    });

    AppLogger.info('Onboarding', 'Submitting onboarding data...');

    try {
      // Map Flutter data fields to backend API format
      await _userRepository.submitOnboardingData(
        gender: data['gender'] as String,
        age: data['age'] as int,
        height: (data['height'] as double).round(),
        weight: data['weight'] as double,
        activityLevel: data['activity'] as String,
        jobType: data['work'] as String,
        healthConditions: List<String>.from(data['health'] as List),
        veggieIntake: data['veg'] as String,
        coffeeCupsPerDay: data['coffee'] as int,
        alcoholUnitsPerDay: data['alcohol'] as int,
      );

      AppLogger.info('Onboarding', 'Onboarding data submitted successfully');

      // Refresh ProfileProvider with new data
      await ref.read(profileNotifierProvider.notifier).refreshProfile();

      // Refresh the auth user so the cached/stored user now carries
      // profile_complete = true. Without this, reopening the app (no logout)
      // would read a stale cached user and re-trigger onboarding.
      await ref.read(authStateProvider.notifier).refreshUser();

      // Navigate to main app
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      AppLogger.error('Onboarding', 'Failed to submit onboarding data', e);

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.nightSurface,
            title: const Text(
              'Lỗi lưu thông tin',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Không thể lưu thông tin cá nhân. Vui lòng thử lại sau.\n\nChi tiết: $e',
              style: TextStyle(color: AppColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Still navigate to home even if API fails
                  context.go('/');
                },
                child:
                    const Text('Bỏ qua', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void prevStep() {
    if (currentStep == 0) {
      context.go('/register');
    } else {
      setState(() {
        currentStep--;
      });
    }
  }

  void skipToReview() {
    setState(() {
      currentStep = steps.length - 1;
    });
  }

  void updateData(String key, dynamic value) {
    setState(() {
      data[key] = value;
    });
  }

  void toggleHealth(String healthId) {
    setState(() {
      List<String> health = List<String>.from(data['health'] ?? []);

      if (healthId == 'none') {
        health = ['none'];
      } else {
        health = health.where((h) => h != 'none').toList();
        if (health.contains(healthId)) {
          health.remove(healthId);
        } else {
          health.add(healthId);
        }
        if (health.isEmpty) health = ['none'];
      }

      data['health'] = health;
    });
  }

  int calculateGoal() {
    // Base calculation: 35ml × weight
    double goal = (data['weight'] as double) * 35;

    // Activity multiplier
    final activityMuls = {
      'sedentary': 1.0,
      'light': 1.15,
      'moderate': 1.3,
      'active': 1.45,
      'athlete': 1.6,
    };
    goal *= activityMuls[data['activity']] ?? 1.3;

    // Work multiplier
    final workMuls = {
      'office': 1.0,
      'mixed': 1.05,
      'field': 1.2,
      'manual': 1.25,
      'sport': 1.35,
    };
    goal *= workMuls[data['work']] ?? 1.0;

    // Vegetable adjustment
    final vegMuls = {'low': 1.05, 'mid': 1.0, 'high': 0.95};
    goal *= vegMuls[data['veg']] ?? 1.0;

    // Coffee and alcohol additions
    goal += (data['coffee'] as int) * 120; // 120ml per coffee cup
    goal += (data['alcohol'] as int) * 200; // 200ml per alcohol unit

    // Health adjustments
    final health = data['health'] as List<String>;
    if (health.contains('pregnant')) goal += 300;
    if (health.contains('lactating')) goal += 700;
    if (health.contains('kidney')) goal = goal.clamp(0, 1800);

    // Round to nearest 50
    return ((goal / 50).round() * 50).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: Column(
          children: [
            // Header with progress
            _buildHeader(step),

            // Step content
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: _buildStepContent(),
              ),
            ),

            // Footer with buttons
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OnboardingStep step) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A3460), Color(0xFF0B1933)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
          child: Column(
            children: [
              // Glow effect
              Container(
                height: 80,
                child: Stack(
                  children: [
                    Positioned(
                      top: -60,
                      left: 0,
                      right: 0,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            colors: [
                              const Color(0x3838BDF8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation and progress
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: prevStep,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress bars
                  Expanded(
                    child: Row(
                      children: List.generate(steps.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < steps.length - 1 ? 5 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: index <= currentStep
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF38BDF8),
                                        Color(0xFF0EA5E9),
                                      ],
                                    )
                                  : null,
                              color: index <= currentStep
                                  ? null
                                  : Colors.white.withValues(alpha: 0.1),
                              boxShadow: index == currentStep
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF38BDF8,
                                        ).withValues(alpha: 0.6),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Step counter
                  Text(
                    '${currentStep + 1}/${steps.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBAE6FD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Step info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${currentStep + 1} · ${step.id.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7DD3FC),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFBAE6FD),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildBodyStep();
      case 1:
        return _buildLifestyleStep();
      case 2:
        return _buildHealthStep();
      case 3:
        return _buildDietStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xFF0B1120)],
          stops: [0.0, 0.3],
        ),
        border: Border(top: BorderSide(color: Color(0x08FFFFFF), width: 1)),
      ),
      child: Column(
        children: [
          // Next button
          GestureDetector(
            onTap: _isSubmitting ? null : nextStep,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isSubmitting
                        ? 'Đang lưu...'
                        : (isLastStep ? 'Bắt đầu uống nước' : 'Tiếp theo'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.02,
                    ),
                  ),
                  if (!_isSubmitting) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Skip button (except on last step)
          if (currentStep < steps.length - 1)
            GestureDetector(
              onTap: skipToReview,
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Bỏ qua phần này',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Step 1: Body info
  Widget _buildBodyStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Giới tính'),
          Row(
            children: [
              _buildGenderOption('male', 'Nam', '♂', const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              _buildGenderOption('female', 'Nữ', '♀', const Color(0xFFF472B6)),
              const SizedBox(width: 8),
              _buildGenderOption('other', 'Khác', '○', const Color(0xFFA78BFA)),
            ],
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('Tuổi'),
          _buildNumberStepper(
            value: data['age'] as int,
            onChanged: (value) => updateData('age', value),
            min: 10,
            max: 100,
            unit: 'tuổi',
          ),
          _buildFieldLabel('Chiều cao'),
          _buildSliderField(
            value: data['height'] as double,
            onChanged: (value) => updateData('height', value),
            min: 130,
            max: 210,
            unit: 'cm',
          ),
          _buildFieldLabel('Cân nặng'),
          _buildSliderField(
            value: data['weight'] as double,
            onChanged: (value) => updateData('weight', value),
            min: 30,
            max: 150,
            unit: 'kg',
            precision: 1,
          ),
        ],
      ),
    );
  }

  // Step 2: Lifestyle
  Widget _buildLifestyleStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Mức vận động thường ngày'),
          ...ActivityOption.values.map((activity) {
            final isSelected = data['activity'] == activity.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => updateData('activity', activity.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0x2E38BDF8)
                        : AppColors.nightSurface,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF38BDF8,
                              ).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(activity.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              activity.description,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRadio(isSelected),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 18),
          _buildFieldLabel('Tính chất công việc'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkOption.values.map((work) {
              final isSelected = data['work'] == work.id;
              return GestureDetector(
                onTap: () => updateData('work', work.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0x2E38BDF8)
                        : AppColors.nightSurface,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        work.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFBAE6FD)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        work.description,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 3: Health
  Widget _buildHealthStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Tình trạng sức khỏe đặc biệt'),
          Text(
            'Có thể chọn nhiều. AquaTrack sẽ điều chỉnh lượng nước & lời nhắc cho phù hợp.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthOption.values.map((health) {
              final isSelected = (data['health'] as List<String>).contains(
                health.id,
              );
              return GestureDetector(
                onTap: () => toggleHealth(health.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(
                            int.parse(
                                  '${health.tone.substring(1)}1F',
                                  radix: 16,
                                ) +
                                0xFF000000,
                          )
                        : AppColors.nightSurface,
                    border: Border.all(
                      color: isSelected
                          ? Color(
                              int.parse(health.tone.substring(1), radix: 16) +
                                  0xFF000000,
                            )
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 11,
                          color: Color(
                            int.parse(health.tone.substring(1), radix: 16) +
                                0xFF000000,
                          ),
                        ),
                      if (isSelected) const SizedBox(width: 6),
                      Text(
                        health.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Color(
                                  int.parse(
                                        health.tone.substring(1),
                                        radix: 16,
                                      ) +
                                      0xFF000000,
                                )
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Health disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x0FFBBF24),
              border: Border.all(color: const Color(0x2EFBBF24), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thông tin này không thay thế lời khuyên y tế. Với bệnh thận hoặc tim mạch, hãy hỏi bác sĩ về lượng nước phù hợp.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFFDE68A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Diet
  Widget _buildDietStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Lượng rau củ quả mỗi ngày'),
          Text(
            'Rau củ quả chứa nhiều nước — ăn nhiều sẽ giảm bớt nhu cầu uống.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: VegetableOption.values.map((veg) {
              final isSelected = data['veg'] == veg.id;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: veg != VegetableOption.values.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => updateData('veg', veg.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0x4010B981), Color(0x1410B981)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isSelected ? null : AppColors.nightSurface,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(veg.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            veg.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            veg.description,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Cà phê / ngày'),
          _buildCounterRow(
            value: data['coffee'] as int,
            onChanged: (value) => updateData('coffee', value),
            icon: '☕',
            unit: 'cốc',
            max: 6,
            hint: 'Lợi tiểu — AquaTrack sẽ bù thêm 120ml/cốc',
            tint: const Color(0xFFB45309),
          ),
          const SizedBox(height: 12),
          _buildFieldLabel('Rượu bia / ngày'),
          _buildCounterRow(
            value: data['alcohol'] as int,
            onChanged: (value) => updateData('alcohol', value),
            icon: '🍺',
            unit: 'đơn vị',
            max: 6,
            hint: '1 đơn vị = 1 lon bia / 1 ly rượu vang',
            tint: const Color(0xFF92400E),
          ),
        ],
      ),
    );
  }

  // Step 5: Review
  Widget _buildReviewStep() {
    final goal = calculateGoal();
    final liter = (goal / 1000).toStringAsFixed(2);
    final cups = (goal / 250).round();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Goal display with living drop
          Container(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment.topCenter,
                colors: [Color(0x2E0EA5E9), Colors.transparent],
                stops: [0.0, 0.7],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const LivingDrop(fillPercentage: 80, size: 120),
                const SizedBox(height: 10),
                const Text(
                  'MỤC TIÊU HẰNG NGÀY',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7DD3FC),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      goal.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          ),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.03,
                        height: 1,
                      ),
                    ),
                    Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ $liter lít · khoảng $cups cốc 250ml',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'TÓM TẮT',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Summary container
          Container(
            decoration: BoxDecoration(
              color: AppColors.nightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildReviewRow(
                  'Giới tính · Tuổi',
                  '${_getGenderLabel(data['gender'] as String)} · ${data['age']} tuổi',
                ),
                _buildReviewRow(
                  'Chiều cao · Cân nặng',
                  '${data['height'].toInt()} cm · ${data['weight']} kg',
                ),
                _buildReviewRow(
                  'Vận động',
                  ActivityOption.values
                      .firstWhere((a) => a.id == data['activity'])
                      .label,
                ),
                _buildReviewRow(
                  'Công việc',
                  WorkOption.values
                      .firstWhere((w) => w.id == data['work'])
                      .label,
                ),
                _buildReviewRow(
                  'Rau củ quả',
                  VegetableOption.values
                      .firstWhere((v) => v.id == data['veg'])
                      .label,
                ),
                _buildReviewRow(
                  'Cà phê · Rượu bia',
                  '${data['coffee']} cốc · ${data['alcohol']} đơn vị',
                ),
                _buildReviewRow('Sức khỏe', _getHealthSummary(), isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x1438BDF8),
              border: Border.all(color: const Color(0x3338BDF8), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF38BDF8),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AquaTrack sẽ tự điều chỉnh mục tiêu này theo thời tiết, vận động và lịch ngủ. Bạn luôn có thể chỉnh lại trong Hồ sơ.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFBAE6FD),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF7DD3FC),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGenderOption(String id, String label, String icon, Color color) {
    final isSelected = data['gender'] == id;

    return Expanded(
      child: GestureDetector(
        onTap: () => updateData('gender', id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isSelected ? null : AppColors.nightSurface,
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isSelected ? color : AppColors.textMuted,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.circle, color: Colors.white, size: 8)
          : null,
    );
  }

  Widget _buildNumberStepper({
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
    required String unit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepButton(
            onTap: () => onChanged((value - 1).clamp(min, max)),
            icon: Icons.remove,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.02,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _buildStepButton(
            onTap: () => onChanged((value + 1).clamp(min, max)),
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x2638BDF8),
          border: Border.all(color: const Color(0x4D38BDF8)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSliderField({
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
    required String unit,
    int precision = 0,
  }) {
    final displayValue = precision == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(precision);
    final percentage = ((value - min) / (max - min)) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.02,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
              Text(
                '${min.toInt()}–${max.toInt()}$unit',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 32,
            child: Stack(
              children: [
                // Track
                Positioned(
                  top: 13,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Progress
                Positioned(
                  top: 13,
                  left: 0,
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 72) *
                        (percentage / 100),
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),

                // Thumb
                Positioned(
                  left: (MediaQuery.of(context).size.width - 72) *
                          (percentage / 100) -
                      10,
                  top: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF38BDF8,
                          ).withValues(alpha: 0.25),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Slider input
                Positioned.fill(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    onChanged: onChanged,
                    activeColor: Colors.transparent,
                    inactiveColor: Colors.transparent,
                    thumbColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required int value,
    required Function(int) onChanged,
    required String icon,
    required String unit,
    required int max,
    String? hint,
    required Color tint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.22),
                  border: Border.all(color: tint.withValues(alpha: 0.44)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value.toString(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSmallStepButton(
                          onTap: () => onChanged((value - 1).clamp(0, max)),
                          icon: Icons.remove,
                        ),
                        const SizedBox(width: 6),
                        _buildSmallStepButton(
                          onTap: () => onChanged((value + 1).clamp(0, max)),
                          icon: Icons.add,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallStepButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0x2638BDF8),
          border: Border.all(color: const Color(0x4D38BDF8)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return 'Nam';
    }
  }

  String _getHealthSummary() {
    final health = data['health'] as List<String>;
    if (health.contains('none') || health.isEmpty) {
      return 'Không có lưu ý';
    }

    final labels = health
        .where((h) => h != 'none')
        .map((h) => HealthOption.values.firstWhere((opt) => opt.id == h).label)
        .join(', ');

    return labels.isNotEmpty ? labels : 'Không có lưu ý';
  }
}

// Data models
class OnboardingStep {
  final String id;
  final String title;
  final String subtitle;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

enum ActivityOption {
  sedentary('sedentary', 'Ít vận động', 'Ngồi nhiều, hiếm khi tập', '🪑'),
  light('light', 'Nhẹ nhàng', 'Đi bộ vài lần/tuần', '🚶'),
  moderate('moderate', 'Vừa phải', 'Tập 3–4 buổi/tuần', '🏃'),
  active('active', 'Năng động', 'Tập gần như mỗi ngày', '🏋️'),
  athlete('athlete', 'Rất năng động', 'VĐV / lao động nặng', '🚴');

  const ActivityOption(this.id, this.label, this.description, this.icon);

  final String id;
  final String label;
  final String description;
  final String icon;
}

enum WorkOption {
  office('office', 'Văn phòng', 'Máy lạnh, ngồi nhiều'),
  mixed('mixed', 'Hỗn hợp', 'Vừa ngồi vừa di chuyển'),
  field('field', 'Ngoài trời', 'Phơi nắng, đi lại nhiều'),
  manual('manual', 'Tay chân', 'Xây dựng, vận chuyển'),
  sport('sport', 'Thể thao chuyên nghiệp', 'Tập luyện cường độ cao');

  const WorkOption(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;
}

enum HealthOption {
  none('none', 'Không có', '#10B981'),
  diabetes('diabetes', 'Tiểu đường', '#F59E0B'),
  hypertension('hypertension', 'Cao huyết áp', '#F97316'),
  kidney('kidney', 'Bệnh thận', '#EF4444'),
  heart('heart', 'Tim mạch', '#EC4899'),
  pregnant('pregnant', 'Đang mang thai', '#A78BFA'),
  lactating('lactating', 'Đang cho con bú', '#A78BFA'),
  gout('gout', 'Gout', '#FBBF24');

  const HealthOption(this.id, this.label, this.tone);

  final String id;
  final String label;
  final String tone;
}

enum VegetableOption {
  low('low', 'Ít', '< 1 phần / ngày', '🥬'),
  mid('mid', 'Vừa', '1–2 phần / ngày', '🥗'),
  high('high', 'Nhiều', '3+ phần / ngày', '🍎');

  const VegetableOption(this.id, this.label, this.description, this.icon);

  final String id;
  final String label;
  final String description;
  final String icon;
}
