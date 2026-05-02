import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/stats_provider.dart';

/// AI insights cards cho personalized feedback
class InsightsCards extends StatelessWidget {
  final StatsData statsData;

  const InsightsCards({
    super.key,
    required this.statsData,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NHẬN XÉT TỪNG NHÂN',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInsightCard(insight),
            )),
      ],
    );
  }

  /// Generate AI insights based on stats data
  List<InsightData> _generateInsights() {
    final insights = <InsightData>[];
    final period = statsData.period;
    final periodName = period == StatsPeriod.week ? 'tuần' : 'tháng';

    // Goal completion insight
    if (statsData.goalCompletionRate >= 0.8) {
      insights.add(InsightData(
        icon: Icons.emoji_events,
        iconColor: AppColors.success,
        title: 'Xuất sắc!',
        message:
            'Bạn đạt mục tiêu ${(statsData.goalCompletionRate * 100).round()}% số ngày trong $periodName này. '
            'Tiếp tục duy trì thói quen tuyệt vời này nhé! 🏆',
        type: InsightType.positive,
      ));
    } else if (statsData.goalCompletionRate >= 0.5) {
      insights.add(InsightData(
        icon: Icons.trending_up,
        iconColor: AppColors.warning,
        title: 'Đang cải thiện',
        message:
            'Bạn đạt mục tiêu ${(statsData.goalCompletionRate * 100).round()}% số ngày trong $periodName này. '
            'Hãy thử thiết lập nhắc nhở để đạt 80%+ nhé!',
        type: InsightType.neutral,
      ));
    } else {
      insights.add(InsightData(
        icon: Icons.local_fire_department,
        iconColor: AppColors.streakOrange,
        title: 'Đã đến lúc bước gas!',
        message:
            'Chỉ ${(statsData.goalCompletionRate * 100).round()}% số ngày đạt mục tiêu trong $periodName này. '
            'Bắt đầu với những ly nước nhỏ đều đặn trong ngày! 💪',
        type: InsightType.motivational,
      ));
    }

    // Average intake insight
    if (statsData.averageIntake >= 2000) {
      insights.add(InsightData(
        icon: Icons.water_drop,
        iconColor: AppColors.cyan,
        title: 'Cơ thể được nuôi dưỡng tốt',
        message:
            'Trung bình ${(statsData.averageIntake / 1000).toStringAsFixed(1)}L/ngày - '
            'lượng nước này giúp da đẹp, tăng cường miễn dịch và tinh thần sảng khoái.',
        type: InsightType.informational,
      ));
    } else if (statsData.averageIntake >= 1200) {
      insights.add(InsightData(
        icon: Icons.psychology,
        iconColor: AppColors.xpPurple,
        title: 'Tăng thêm một chút nữa',
        message:
            'Hiện tại ${(statsData.averageIntake / 1000).toStringAsFixed(1)}L/ngày. '
            'Thêm 2-3 ly nữa để đạt tối ưu cho sức khỏe não bộ và làn da! 🧠',
        type: InsightType.suggestion,
      ));
    } else {
      insights.add(InsightData(
        icon: Icons.priority_high,
        iconColor: AppColors.error,
        title: 'Cơ thể cần nhiều nước hơn',
        message:
            'Chỉ ${(statsData.averageIntake / 1000).toStringAsFixed(1)}L/ngày có thể gây mệt mỏi và '
            'giảm tập trung. Hãy bắt đầu với 1 ly ngay bây giờ! 🚨',
        type: InsightType.urgent,
      ));
    }

    // Streak insight
    if (statsData.streakDays >= 7) {
      insights.add(InsightData(
        icon: Icons.local_fire_department,
        iconColor: AppColors.streakOrange,
        title: 'Streak Master! 🔥',
        message: '${statsData.streakDays} ngày liên tiếp! '
            'Bạn đang xây dựng thói quen lành mạnh bền vững. Cứ tiếp tục như vậy nhé!',
        type: InsightType.achievement,
      ));
    } else if (statsData.streakDays >= 3) {
      insights.add(InsightData(
        icon: Icons.trending_up,
        iconColor: AppColors.success,
        title: 'Momentum tốt!',
        message: '${statsData.streakDays} ngày liên tiếp đạt mục tiêu. '
            'Chỉ cần thêm vài ngày nữa là bạn sẽ tạo thói quen bền vững!',
        type: InsightType.encouraging,
      ));
    }

    // Favorite liquid insight
    if (statsData.topLiquidType != 'Nước') {
      insights.add(InsightData(
        icon: Icons.favorite,
        iconColor: AppColors.xpPurpleLight,
        title: 'Gu uống đặc biệt',
        message:
            'Bạn thích ${statsData.topLiquidType.toLowerCase()} nhất trong $periodName này! '
            'Nhớ cân bằng với nước lọc để tối ưu hóa sức khỏe nhé.',
        type: InsightType.personal,
      ));
    }

    // Take only top 3 most relevant insights
    return insights.take(3).toList();
  }

  /// Build individual insight card
  Widget _buildInsightCard(InsightData insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _getCardGradient(insight.type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon với background circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get gradient based on insight type
  LinearGradient _getCardGradient(InsightType type) {
    switch (type) {
      case InsightType.positive:
      case InsightType.achievement:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            AppColors.success.withValues(alpha: 0.03),
          ],
        );
      case InsightType.motivational:
      case InsightType.urgent:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.streakOrange.withValues(alpha: 0.08),
            AppColors.streakOrange.withValues(alpha: 0.03),
          ],
        );
      case InsightType.informational:
      case InsightType.personal:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withValues(alpha: 0.08),
            AppColors.cyan.withValues(alpha: 0.03),
          ],
        );
      case InsightType.suggestion:
      case InsightType.encouraging:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.xpPurple.withValues(alpha: 0.08),
            AppColors.xpPurple.withValues(alpha: 0.03),
          ],
        );
      case InsightType.neutral:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withValues(alpha: 0.5),
          ],
        );
    }
  }
}

/// Insight data model
class InsightData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final InsightType type;

  const InsightData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.type,
  });
}

/// Insight type for styling
enum InsightType {
  positive,
  motivational,
  informational,
  suggestion,
  achievement,
  encouraging,
  personal,
  urgent,
  neutral,
}
