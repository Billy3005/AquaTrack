import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'providers/profile_provider.dart';

class EditBodyInfoScreen extends ConsumerStatefulWidget {
  const EditBodyInfoScreen({super.key});

  @override
  ConsumerState<EditBodyInfoScreen> createState() => _EditBodyInfoScreenState();
}

class _EditBodyInfoScreenState extends ConsumerState<EditBodyInfoScreen> {
  // Form controllers
  String? _selectedGender;
  int _age = 25;
  double _height = 168;
  double _weight = 60.0;
  String? _selectedActivityLevel;
  String? _selectedJobType;
  List<String> _healthConditions = ['none'];
  String _veggieIntake = 'mid';
  int _coffeeCupsPerDay = 1;
  int _alcoholUnitsPerDay = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default values, will update in build method
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileNotifierProvider);

    // Initialize with current profile data on first build
    if (_selectedGender == null) {
      _selectedGender = profile.gender;
      _age = profile.age ?? 25;
      _height = (profile.height ?? 168).toDouble();
      _weight = profile.weight ?? 60.0;
      _selectedActivityLevel = profile.activityLevel;
      _selectedJobType = profile.jobType;
      _healthConditions = profile.healthConditions ?? ['none'];
      _veggieIntake =
          'mid'; // Default value as profile doesn't have this field yet
      _coffeeCupsPerDay = profile.coffeeCupsPerDay ?? 1;
      _alcoholUnitsPerDay = profile.alcoholUnitsPerDay ?? 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildGenderSection(),
                    const SizedBox(height: 24),
                    _buildAgeSection(),
                    const SizedBox(height: 24),
                    _buildHeightSection(),
                    const SizedBox(height: 24),
                    _buildWeightSection(),
                    const SizedBox(height: 24),
                    _buildActivityLevelSection(),
                    const SizedBox(height: 24),
                    _buildJobTypeSection(),
                    const SizedBox(height: 24),
                    _buildHealthConditionsSection(),
                    const SizedBox(height: 24),
                    _buildVeggieIntakeSection(),
                    const SizedBox(height: 24),
                    _buildCoffeeAlcoholSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Sửa thông tin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GIỚI TÍNH',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderButton('male', 'Nam', Icons.male)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderButton('female', 'Nữ', Icons.female)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderButton('other', 'Khác', Icons.circle)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.background : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.background : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TUỔI',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _age > 1 ? () => setState(() => _age--) : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _age > 1 ? AppColors.cyan : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _age > 1
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              Text(
                '$_age tuổi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
              IconButton(
                onPressed: _age < 120 ? () => setState(() => _age++) : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _age < 120 ? AppColors.cyan : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _age < 120
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CHIỀU CAO',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '130-210cm',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                '${_height.round()} cm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: Slider(
                  value: _height,
                  min: 130,
                  max: 210,
                  activeColor: AppColors.cyan,
                  inactiveColor: Colors.white.withValues(alpha: 0.2),
                  thumbColor: Colors.white,
                  onChanged: (value) => setState(() => _height = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CÂN NẶNG',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '30-150kg',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                '${_weight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: Slider(
                  value: _weight,
                  min: 30,
                  max: 150,
                  activeColor: AppColors.cyan,
                  inactiveColor: Colors.white.withValues(alpha: 0.2),
                  thumbColor: Colors.white,
                  onChanged: (value) => setState(() => _weight = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSection() {
    const activityLevels = {
      'sedentary': {'label': 'Ít vận động', 'desc': 'Ngồi nhiều, ít tập'},
      'light': {'label': 'Nhẹ nhàng', 'desc': 'Tập nhẹ 1-3 ngày/tuần'},
      'moderate': {'label': 'Vừa phải', 'desc': 'Tập vừa 3-5 ngày/tuần'},
      'active': {'label': 'Tích cực', 'desc': 'Tập mạnh 6-7 ngày/tuần'},
      'very_active': {
        'label': 'Rất tích cực',
        'desc': 'Tập rất mạnh hàng ngày'
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MỨC VẬN ĐỘNG',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'THƯỜNG NGÀY',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        ...activityLevels.entries
            .map((entry) => _buildActivityOption(
                entry.key, entry.value['label']!, entry.value['desc']!))
            .toList(),
      ],
    );
  }

  Widget _buildActivityOption(String value, String label, String desc) {
    final isSelected = _selectedActivityLevel == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.directions_run,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTypeSection() {
    const jobTypes = {
      'office': {
        'label': 'Văn phòng',
        'desc': 'Ngồi bàn chủ yếu',
        'icon': Icons.computer
      },
      'mixed': {
        'label': 'Hỗn hợp',
        'desc': 'Vừa ngồi vừa đi',
        'icon': Icons.work
      },
      'outdoor': {
        'label': 'Ngoài trời',
        'desc': 'Hoạt động ngoài trời',
        'icon': Icons.outdoor_grill
      },
      'manual': {
        'label': 'Thể lực',
        'desc': 'Lao động nặng',
        'icon': Icons.fitness_center
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOẠI CÔNG VIỆC',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...jobTypes.entries
            .map((entry) => _buildJobTypeOption(
                entry.key,
                entry.value['label'] as String,
                entry.value['desc'] as String,
                entry.value['icon'] as IconData))
            .toList(),
      ],
    );
  }

  Widget _buildJobTypeOption(
      String value, String label, String desc, IconData icon) {
    final isSelected = _selectedJobType == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedJobType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthConditionsSection() {
    const healthOptions = {
      'none': {'label': 'Không có', 'desc': 'Khỏe mạnh bình thường'},
      'diabetes': {'label': 'Tiểu đường', 'desc': 'Cần kiểm soát đường huyết'},
      'hypertension': {'label': 'Cao huyết áp', 'desc': 'Huyết áp cao'},
      'kidney': {'label': 'Thận', 'desc': 'Vấn đề về thận'},
      'heart': {'label': 'Tim mạch', 'desc': 'Bệnh tim mạch'},
      'pregnant': {'label': 'Mang thai', 'desc': 'Đang mang thai'},
      'lactating': {'label': 'Cho con bú', 'desc': 'Đang cho con bú'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÌNH TRẠNG SỨC KHỎE',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'CÓ THỂ CHỌN NHIỀU',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        ...healthOptions.entries
            .map((entry) => _buildHealthOption(
                entry.key, entry.value['label']!, entry.value['desc']!))
            .toList(),
      ],
    );
  }

  Widget _buildHealthOption(String value, String label, String desc) {
    final isSelected = _healthConditions.contains(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == 'none') {
            // If selecting "none", clear all others
            _healthConditions = ['none'];
          } else {
            // If selecting other condition, remove "none" and toggle this condition
            if (isSelected) {
              _healthConditions.remove(value);
              if (_healthConditions.isEmpty) {
                _healthConditions = ['none'];
              }
            } else {
              _healthConditions.remove('none');
              _healthConditions.add(value);
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeggieIntakeSection() {
    const veggieOptions = {
      'low': {'label': 'Ít', 'desc': 'Ít ăn rau củ quả'},
      'mid': {'label': 'Vừa', 'desc': 'Ăn rau củ quả bình thường'},
      'high': {'label': 'Nhiều', 'desc': 'Ăn rau củ quả nhiều'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LƯỢNG RAU CỦ QUẢ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'HÀNG NGÀY',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        ...veggieOptions.entries
            .map((entry) => _buildVeggieOption(
                entry.key, entry.value['label']!, entry.value['desc']!))
            .toList(),
      ],
    );
  }

  Widget _buildVeggieOption(String value, String label, String desc) {
    final isSelected = _veggieIntake == value;

    return GestureDetector(
      onTap: () => setState(() => _veggieIntake = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : const Color(0xFF059669),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeAlcoholSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THÓI QUEN HÀNG NGÀY',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildCoffeeCounter(),
        const SizedBox(height: 16),
        _buildAlcoholCounter(),
      ],
    );
  }

  Widget _buildCoffeeCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.coffee,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cà phê',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Số cốc/ngày',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _coffeeCupsPerDay > 0
                    ? () => setState(() => _coffeeCupsPerDay--)
                    : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _coffeeCupsPerDay > 0
                        ? AppColors.cyan
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _coffeeCupsPerDay > 0
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              Container(
                width: 40,
                child: Text(
                  '$_coffeeCupsPerDay',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _coffeeCupsPerDay < 10
                    ? () => setState(() => _coffeeCupsPerDay++)
                    : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _coffeeCupsPerDay < 10
                        ? AppColors.cyan
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _coffeeCupsPerDay < 10
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.wine_bar,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rượu bia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Đơn vị/ngày',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _alcoholUnitsPerDay > 0
                    ? () => setState(() => _alcoholUnitsPerDay--)
                    : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _alcoholUnitsPerDay > 0
                        ? AppColors.cyan
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _alcoholUnitsPerDay > 0
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              Container(
                width: 40,
                child: Text(
                  '$_alcoholUnitsPerDay',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _alcoholUnitsPerDay < 10
                    ? () => setState(() => _alcoholUnitsPerDay++)
                    : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _alcoholUnitsPerDay < 10
                        ? AppColors.cyan
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _alcoholUnitsPerDay < 10
                        ? AppColors.background
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'Hủy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _saveChanges,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? AppColors.cyan.withValues(alpha: 0.6)
                      : AppColors.cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Update via ProfileProvider
      final profileNotifier = ref.read(profileNotifierProvider.notifier);

      // Call backend API to update body info
      await profileNotifier.updateBodyInfo(
        gender: _selectedGender,
        age: _age,
        height: _height.round(),
        weight: _weight,
        activityLevel: _selectedActivityLevel,
        jobType: _selectedJobType,
        healthConditions: _healthConditions,
        veggieIntake: _veggieIntake,
        coffeeCupsPerDay: _coffeeCupsPerDay,
        alcoholUnitsPerDay: _alcoholUnitsPerDay,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
