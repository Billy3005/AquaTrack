import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/water_profile.dart';
import '../../../core/services/water_profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Water Profile Form widget để user setup profile
class WaterProfileForm extends ConsumerStatefulWidget {
  const WaterProfileForm({super.key});

  @override
  ConsumerState<WaterProfileForm> createState() => _WaterProfileFormState();
}

class _WaterProfileFormState extends ConsumerState<WaterProfileForm> {
  final WaterProfileService _service = WaterProfileService();

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _coffeeController = TextEditingController();
  final _alcoholController = TextEditingController();

  // Form state
  Gender? _selectedGender;
  ActivityLevel? _selectedActivityLevel;
  JobType? _selectedJobType;
  VeggieIntake? _selectedVeggieIntake;
  List<HealthCondition> _selectedHealthConditions = [HealthCondition.none];

  // UI state
  bool _isLoading = false;
  bool _isCalculating = false;
  WaterProfileEnums? _enums;
  WaterProfileResponse? _currentProfile;
  WaterCalculationResponse? _calculation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _coffeeController.dispose();
    _alcoholController.dispose();
    super.dispose();
  }

  /// Load initial data (enums + current profile)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load enums and current profile in parallel
      final futures = await Future.wait([
        _service.getEnums(),
        _service.getProfile(),
      ]);

      _enums = futures[0] as WaterProfileEnums;
      _currentProfile = futures[1] as WaterProfileResponse;

      // Populate form with current data
      _populateForm(_currentProfile!);
    } catch (e) {
      _showError('Lỗi khi tải dữ liệu: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Populate form fields với current profile data
  void _populateForm(WaterProfileResponse profile) {
    setState(() {
      _selectedGender = profile.gender;
      _ageController.text = profile.age?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _selectedActivityLevel = profile.activityLevel;
      _selectedJobType = profile.jobType;
      _selectedHealthConditions =
          profile.healthConditions ?? [HealthCondition.none];
      _selectedVeggieIntake = profile.veggieIntake;
      _coffeeController.text = profile.coffeeCupsPerDay?.toString() ?? '0';
      _alcoholController.text = profile.alcoholUnitsPerDay?.toString() ?? '0';
    });
  }

  /// Save profile và calculate water goal
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      final update = WaterProfileUpdate(
        gender: _selectedGender,
        age: int.tryParse(_ageController.text),
        height: int.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        activityLevel: _selectedActivityLevel,
        jobType: _selectedJobType,
        healthConditions: _selectedHealthConditions,
        veggieIntake: _selectedVeggieIntake,
        coffeeCupsPerDay: int.tryParse(_coffeeController.text) ?? 0,
        alcoholUnitsPerDay: int.tryParse(_alcoholController.text) ?? 0,
      );

      final updatedProfile = await _service.updateProfile(update);

      // If profile is complete, calculate water intake
      if (updatedProfile.isComplete) {
        final calculation = await _service.calculateWaterIntake();
        setState(() {
          _calculation = calculation;
        });
      }

      setState(() {
        _currentProfile = updatedProfile;
      });

      _showSuccess('Đã cập nhật profile thành công!');
    } catch (e) {
      _showError('Lỗi khi lưu profile: ${e.toString()}');
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_enums == null || _currentProfile == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildBodySection(),
            const SizedBox(height: 24),
            _buildLifestyleSection(),
            const SizedBox(height: 24),
            _buildHealthSection(),
            const SizedBox(height: 24),
            _buildDietSection(),
            const SizedBox(height: 24),
            _buildCalculationCard(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Header card với progress
  Widget _buildHeaderCard() {
    final completionPercentage = _currentProfile?.completionPercentage ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.cyanAccent),
              const SizedBox(width: 8),
              Text(
                'Thông tin cá nhân',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: AppColors.borderColor,
                  valueColor: AlwaysStoppedAnimation(AppColors.cyanAccent),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${completionPercentage.toInt()}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (completionPercentage < 100) ...[
            const SizedBox(height: 8),
            Text(
              'Hoàn thiện thông tin để tính toán mục tiêu nước chính xác',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// B1: Body section
  Widget _buildBodySection() {
    return _buildSection(
      title: 'B1. Thông tin cơ thể',
      icon: Icons.accessibility_new,
      children: [
        // Gender dropdown
        _buildDropdownField<Gender>(
          label: 'Giới tính',
          value: _selectedGender,
          items: _enums!.genderOptions,
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) =>
              value == null ? 'Vui lòng chọn giới tính' : null,
        ),

        const SizedBox(height: 16),

        // Age and Height row
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _ageController,
                label: 'Tuổi',
                suffix: 'tuổi',
                validator: (value) => _validateAge(value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                controller: _heightController,
                label: 'Chiều cao',
                suffix: 'cm',
                validator: (value) => _validateHeight(value),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Weight
        _buildNumberField(
          controller: _weightController,
          label: 'Cân nặng',
          suffix: 'kg',
          isDecimal: true,
          validator: (value) => _validateWeight(value),
        ),
      ],
    );
  }

  /// B2: Lifestyle section
  Widget _buildLifestyleSection() {
    return _buildSection(
      title: 'B2. Lối sống',
      icon: Icons.directions_run,
      children: [
        _buildDropdownField<ActivityLevel>(
          label: 'Mức độ hoạt động',
          value: _selectedActivityLevel,
          items: _enums!.activityLevelOptions,
          onChanged: (value) => setState(() => _selectedActivityLevel = value),
          validator: (value) =>
              value == null ? 'Vui lòng chọn mức độ hoạt động' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField<JobType>(
          label: 'Loại công việc',
          value: _selectedJobType,
          items: _enums!.jobTypeOptions,
          onChanged: (value) => setState(() => _selectedJobType = value),
          validator: (value) =>
              value == null ? 'Vui lòng chọn loại công việc' : null,
        ),
      ],
    );
  }

  /// B3: Health section
  Widget _buildHealthSection() {
    return _buildSection(
      title: 'B3. Tình trạng sức khỏe',
      icon: Icons.health_and_safety,
      children: [
        _buildMultiSelectField<HealthCondition>(
          label: 'Tình trạng sức khỏe',
          selectedValues: _selectedHealthConditions,
          options: _enums!.healthConditionOptions,
          onChanged: (values) =>
              setState(() => _selectedHealthConditions = values),
        ),
      ],
    );
  }

  /// B4: Diet section
  Widget _buildDietSection() {
    return _buildSection(
      title: 'B4. Chế độ ăn uống',
      icon: Icons.restaurant,
      children: [
        _buildDropdownField<VeggieIntake>(
          label: 'Lượng rau củ',
          value: _selectedVeggieIntake,
          items: _enums!.veggieIntakeOptions,
          onChanged: (value) => setState(() => _selectedVeggieIntake = value),
          validator: (value) =>
              value == null ? 'Vui lòng chọn lượng rau củ' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                controller: _coffeeController,
                label: 'Cà phê/ngày',
                suffix: 'cốc',
                validator: (value) => _validateCoffee(value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                controller: _alcoholController,
                label: 'Rượu bia/ngày',
                suffix: 'đơn vị',
                validator: (value) => _validateAlcohol(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Calculation result card
  Widget _buildCalculationCard() {
    if (_calculation == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calculate,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Hoàn thiện thông tin để tính toán',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu nước hàng ngày',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main goal
          Text(
            _calculation!.formattedTotal,
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${_calculation!.formattedCups} • ${_calculation!.formattedMl}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          // Warnings
          if (_calculation!.hasAnyWarnings) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calculation!.warningMessage ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCalculating ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyanAccent,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCalculating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Đang tính toán...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  const SizedBox(width: 8),
                  Text('Lưu và tính toán'),
                ],
              ),
      ),
    );
  }

  /// Helper: Build section wrapper
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Helper: Build dropdown field
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownOption<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((option) {
        return DropdownMenuItem<T>(
          value: option.value,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Helper: Build multi-select field
  Widget _buildMultiSelectField<T>({
    required String label,
    required List<T> selectedValues,
    required List<DropdownOption<T>> options,
    required ValueChanged<List<T>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option.value);

            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<T>.from(selectedValues);
                if (selected) {
                  // Handle "none" exclusive logic
                  if (option.value is HealthCondition) {
                    final healthOption = option.value as HealthCondition;
                    if (healthOption == HealthCondition.none) {
                      newValues.clear();
                      newValues.add(option.value);
                    } else {
                      newValues.removeWhere((v) =>
                          v is HealthCondition && v == HealthCondition.none);
                      newValues.add(option.value);
                    }
                  } else {
                    newValues.add(option.value);
                  }
                } else {
                  newValues.remove(option.value);
                  if (newValues.isEmpty && option.value is HealthCondition) {
                    newValues.add(HealthCondition.none as T);
                  }
                }
                onChanged(newValues);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Helper: Build number input field
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    bool isDecimal = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  /// Validation helpers
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập tuổi';
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Tuổi phải từ 1 đến 120';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập chiều cao';
    final height = int.tryParse(value);
    if (height == null || height < 100 || height > 250) {
      return 'Chiều cao phải từ 100 đến 250 cm';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập cân nặng';
    final weight = double.tryParse(value);
    if (weight == null || weight < 30 || weight > 300) {
      return 'Cân nặng phải từ 30 đến 300 kg';
    }
    return null;
  }

  String? _validateCoffee(String? value) {
    if (value == null || value.isEmpty) value = '0';
    final coffee = int.tryParse(value);
    if (coffee == null || coffee < 0 || coffee > 10) {
      return 'Số cốc cà phê phải từ 0 đến 10';
    }
    return null;
  }

  String? _validateAlcohol(String? value) {
    if (value == null || value.isEmpty) value = '0';
    final alcohol = int.tryParse(value);
    if (alcohol == null || alcohol < 0 || alcohol > 10) {
      return 'Số đơn vị rượu bia phải từ 0 đến 10';
    }
    return null;
  }

  /// Error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success dialog
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
