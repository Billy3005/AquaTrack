import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/coin_badge.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  String _activeTab = 'all';
  final Map<String, bool> _purchased = {};
  String _equipped = 'theme_ocean';
  String? _toastMessage;
  String? _toastType;

  late AnimationController _toastController;
  late Animation<double> _toastAnimation;
  late AnimationController _shineController;

  final int _balance = 1240;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toastAnimation = CurvedAnimation(
      parent: _toastController,
      curve: Curves.elasticOut,
    );

    _shineController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _toastController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  List<ShopItem> get _items => [
    // Featured / limited
    ShopItem(
      id: 'theme_aurora',
      category: 'theme',
      name: 'Aurora Night',
      subtitle: 'Theme · giới hạn',
      price: 450,
      rarity: 'epic',
      featured: true,
      colorSwatch: const [
        Color(0xFF312E81),
        Color(0xFF7C3AED),
        Color(0xFF06B6D4),
      ],
    ),
    ShopItem(
      id: 'frame_dragon',
      category: 'frame',
      name: 'Rồng nước',
      subtitle: 'Khung avatar · hiếm',
      price: 600,
      rarity: 'epic',
      featured: true,
      ringColors: const [
        Color(0xFFFBBF24),
        Color(0xFFF472B6),
        Color(0xFF0EA5E9),
      ],
    ),

    // Themes
    ShopItem(
      id: 'theme_ocean',
      category: 'theme',
      name: 'Đêm Đại dương',
      subtitle: 'Theme · đã có',
      price: 0,
      rarity: 'common',
      owned: true,
      colorSwatch: const [
        Color(0xFF0C4A80),
        Color(0xFF082F5C),
        Color(0xFF38BDF8),
      ],
    ),
    ShopItem(
      id: 'theme_forest',
      category: 'theme',
      name: 'Mưa rừng',
      subtitle: 'Theme',
      price: 280,
      rarity: 'rare',
      colorSwatch: const [
        Color(0xFF064E3B),
        Color(0xFF059669),
        Color(0xFFA3E635),
      ],
    ),
    ShopItem(
      id: 'theme_desert',
      category: 'theme',
      name: 'Hoàng hôn sa mạc',
      subtitle: 'Theme',
      price: 320,
      rarity: 'rare',
      colorSwatch: const [
        Color(0xFF7C2D12),
        Color(0xFFF59E0B),
        Color(0xFFFDE68A),
      ],
    ),
    ShopItem(
      id: 'theme_sakura',
      category: 'theme',
      name: 'Hoa anh đào',
      subtitle: 'Theme',
      price: 380,
      rarity: 'rare',
      colorSwatch: const [
        Color(0xFF831843),
        Color(0xFFEC4899),
        Color(0xFFFBCFE8),
      ],
    ),

    // Avatar frames
    ShopItem(
      id: 'frame_ocean',
      category: 'frame',
      name: 'Sóng Ocean',
      subtitle: 'Khung avatar · đã có',
      price: 0,
      rarity: 'common',
      owned: true,
      ringColors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    ),
    ShopItem(
      id: 'frame_gold',
      category: 'frame',
      name: 'Vàng ròng',
      subtitle: 'Khung avatar',
      price: 220,
      rarity: 'rare',
      ringColors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    ),
    ShopItem(
      id: 'frame_aurora',
      category: 'frame',
      name: 'Cực quang',
      subtitle: 'Khung avatar',
      price: 480,
      rarity: 'epic',
      ringColors: const [
        Color(0xFFA78BFA),
        Color(0xFF22D3EE),
        Color(0xFF10B981),
      ],
    ),

    // Boosters / consumables
    ShopItem(
      id: 'boost_2x',
      category: 'boost',
      name: 'Nhân đôi 24h',
      subtitle: 'Toàn bộ xu nhận được × 2',
      price: 180,
      rarity: 'rare',
      icon: '⚡',
    ),
    ShopItem(
      id: 'boost_freeze',
      category: 'boost',
      name: 'Đóng băng chuỗi',
      subtitle: 'Bảo vệ streak 1 ngày',
      price: 120,
      rarity: 'common',
      icon: '🧊',
    ),
    ShopItem(
      id: 'boost_xpkit',
      category: 'boost',
      name: 'Gói +500 XP',
      subtitle: 'Nạp ngay 500 XP',
      price: 250,
      rarity: 'rare',
      icon: '💎',
    ),

    // Drink stickers (cosmetic)
    ShopItem(
      id: 'sticker_neon',
      category: 'sticker',
      name: 'Drop Neon',
      subtitle: 'Hiệu ứng giọt nước',
      price: 90,
      rarity: 'common',
      icon: '💧',
    ),
    ShopItem(
      id: 'sticker_bubble',
      category: 'sticker',
      name: 'Bong bóng vàng',
      subtitle: 'Hiệu ứng khi log',
      price: 140,
      rarity: 'common',
      icon: '🫧',
    ),
  ];

  List<String> get _tabs => ['all', 'theme', 'frame', 'boost', 'sticker'];

  String _getTabLabel(String tab) {
    switch (tab) {
      case 'all':
        return 'Tất cả';
      case 'theme':
        return 'Theme';
      case 'frame':
        return 'Khung';
      case 'boost':
        return 'Tăng tốc';
      case 'sticker':
        return 'Sticker';
      default:
        return tab;
    }
  }

  List<ShopItem> get _filteredItems {
    if (_activeTab == 'all') return _items;
    return _items.where((item) => item.category == _activeTab).toList();
  }

  List<ShopItem> get _featuredItems =>
      _items.where((item) => item.featured).toList();

  bool _isOwned(ShopItem item) => item.owned || _purchased[item.id] == true;

  int get _currentBalance {
    final spent = _items
        .where((item) => _purchased[item.id] == true)
        .fold(0, (sum, item) => sum + item.price);
    return _balance - spent;
  }

  void _buyItem(ShopItem item) {
    if (_isOwned(item)) {
      setState(() {
        _equipped = item.id;
      });
      _showToast('Đã chọn "${item.name}"', 'equip');
    } else if (_currentBalance < item.price) {
      _showToast('Thiếu ${item.price - _currentBalance} xu', 'error');
    } else {
      setState(() {
        _purchased[item.id] = true;
      });
      _showToast('Đã mua "${item.name}" · −${item.price} xu', 'success');
    }
  }

  void _showToast(String message, String type) {
    setState(() {
      _toastMessage = message;
      _toastType = type;
    });

    _toastController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          _toastController.reverse().then((_) {
            setState(() {
              _toastMessage = null;
              _toastType = null;
            });
          });
        }
      });
    });
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'epic':
        return const Color(0xFFA78BFA);
      case 'rare':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(child: _buildContent()),
            ],
          ),
          if (_toastMessage != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1040), Color(0xFF0B1120)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _buildBackButton(),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CỬA HÀNG',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFFCD34D),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'AquaShop',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 14),
              LargeCoinBadge(
                amount: _currentBalance,
                subtitle: 'SỐ DƯ',
                onTap: () => context.go('/missions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: IconButton(
        onPressed: () => context.pop(),
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFBBF24).withOpacity(0.16),
            const Color(0xFFF59E0B).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: const RadialGradient(
                  center: Alignment(-0.4, -0.4),
                  colors: [Color(0xFFFEF3C7), Color(0xFFB45309)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Color(0xFF451A03),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SỐ DƯ',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFFCD34D),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _currentBalance.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (match) => '${match[1]}.',
                        ),
                        style: AppTextStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'xu',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFFDE68A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/missions'),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    child: Text(
                      '+ Kiếm xu',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFDE68A),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.nightBase,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabs.map((tab) {
              final isActive = tab == _activeTab;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFBBF24).withOpacity(0.2),
                              const Color(0xFFF59E0B).withOpacity(0.08),
                            ],
                          )
                        : null,
                    color: isActive ? null : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFBBF24).withOpacity(0.45)
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = tab),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          _getTabLabel(tab),
                          style: AppTextStyles.caption.copyWith(
                            color: isActive
                                ? const Color(0xFFFDE68A)
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeTab == 'all') ...[
            _buildSectionLabel('✨ Nổi bật tuần này'),
            const SizedBox(height: 10),
            _buildFeaturedCarousel(),
            const SizedBox(height: 18),
            _buildSectionLabel('Tất cả vật phẩm'),
            const SizedBox(height: 10),
          ],
          _buildItemsGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textBright,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _buildFeaturedCard(_featuredItems[index]);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(ShopItem item) {
    final rarityColor = _getRarityColor(item.rarity);
    final isOwned = _isOwned(item);
    final isEquipped = _equipped == item.id;

    return Container(
      width: 215,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withOpacity(0.13),
            const Color(0xFF0B1120).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarityColor.withOpacity(0.33)),
      ),
      child: Stack(
        children: [
          // Shine animation
          AnimatedBuilder(
            animation: _shineController,
            builder: (context, child) {
              return Positioned(
                top: 0,
                bottom: 0,
                left: -40 + (_shineController.value * 300),
                child: Container(
                  width: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x26FFFFFF),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: rarityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 8.5,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.nightSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: _buildItemPreview(item, large: true)),
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
                const Spacer(),
                _buildBuyButton(item, isOwned, isEquipped, compact: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildShopItemCard(_filteredItems[index]);
      },
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    final rarityColor = _getRarityColor(item.rarity);
    final isOwned = _isOwned(item);
    final isEquipped = _equipped == item.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped ? AppColors.glow : AppColors.border,
          width: isEquipped ? 1.5 : 1,
        ),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: AppColors.glow.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area
            Container(
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.nightBase,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Stack(
                children: [
                  Center(child: _buildItemPreview(item)),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: rarityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  if (isEquipped)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          'ĐANG DÙNG',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFBAE6FD),
                            fontWeight: FontWeight.w700,
                            fontSize: 8.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              item.name,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              item.subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _buildBuyButton(item, isOwned, isEquipped, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreview(ShopItem item, {bool large = false}) {
    switch (item.category) {
      case 'theme':
        return SizedBox(
          width: large ? 70 : 56,
          height: large ? 40 : 32,
          child: Row(
            children: item.colorSwatch!.map((color) {
              return Expanded(child: Container(color: color));
            }).toList(),
          ),
        );

      case 'frame':
        final size = large ? 72.0 : 56.0;
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 2),
            gradient: SweepGradient(
              colors: [...item.ringColors!, item.ringColors!.first],
              transform: const GradientRotation(3.8),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA5B4FC).withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
              ),
              border: Border.all(color: const Color(0xFF0B1120), width: 2),
            ),
            child: Icon(
              Icons.water_drop,
              color: Colors.white,
              size: large ? 26 : 20,
            ),
          ),
        );

      case 'boost':
        final size = large ? 64.0 : 52.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(large ? 16 : 12),
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.4),
              colors: [Color(0x59A78BFA), Color(0x1A7C3AED)],
            ),
            border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              item.icon!,
              style: TextStyle(fontSize: large ? 30 : 24),
            ),
          ),
        );

      case 'sticker':
        final size = large ? 64.0 : 52.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 2),
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.4),
              colors: [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              item.icon!,
              style: TextStyle(fontSize: large ? 28 : 22),
            ),
          ),
        );

      default:
        return Container();
    }
  }

  Widget _buildBuyButton(
    ShopItem item,
    bool isOwned,
    bool isEquipped, {
    required bool compact,
  }) {
    final cantAfford = !isOwned && _currentBalance < item.price;

    if (isOwned && isEquipped) {
      return Container(
        width: double.infinity,
        height: compact ? 32 : 36,
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            '✓ ĐANG DÙNG',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF7DD3FC),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    if (isOwned) {
      return Container(
        width: double.infinity,
        height: compact ? 32 : 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _buyItem(item),
            borderRadius: BorderRadius.circular(9),
            child: Center(
              child: Text(
                'CHỌN DÙNG',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: compact ? 32 : 36,
      decoration: BoxDecoration(
        gradient: cantAfford
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
        color: cantAfford ? Colors.white.withOpacity(0.04) : null,
        borderRadius: BorderRadius.circular(9),
        border: cantAfford
            ? Border.all(color: Colors.white.withOpacity(0.06))
            : null,
        boxShadow: cantAfford
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: cantAfford ? null : () => _buyItem(item),
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: cantAfford
                      ? AppColors.textMuted
                      : const Color(0xFF451A03),
                  size: compact ? 12 : 14,
                ),
                const SizedBox(width: 5),
                Text(
                  item.price.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (match) => '${match[1]}.',
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: cantAfford
                        ? AppColors.textMuted
                        : const Color(0xFF451A03),
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToast() {
    Color toastColor;
    switch (_toastType) {
      case 'error':
        toastColor = const Color(0xFFEF4444);
        break;
      case 'equip':
        toastColor = const Color(0xFF38BDF8);
        break;
      default:
        toastColor = const Color(0xFF22C55E);
    }

    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: ScaleTransition(
          scale: _toastAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: toastColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              _toastMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShopItem {
  final String id;
  final String category;
  final String name;
  final String subtitle;
  final int price;
  final String rarity;
  final bool featured;
  final bool owned;
  final List<Color>? colorSwatch;
  final List<Color>? ringColors;
  final String? icon;

  const ShopItem({
    required this.id,
    required this.category,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rarity,
    this.featured = false,
    this.owned = false,
    this.colorSwatch,
    this.ringColors,
    this.icon,
  });
}
