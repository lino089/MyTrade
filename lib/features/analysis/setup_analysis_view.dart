import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats_calculator.dart';
import '../../providers/trade_filter_provider.dart';

class SetupAnalysisView extends ConsumerWidget {
  const SetupAnalysisView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTrades = ref.watch(filteredTradesProvider);

    final setupStats = StatsCalculator.calculateSetupStats(filteredTrades);
    final checklistStats = StatsCalculator.calculateChecklistStats(filteredTrades);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Setup & Konfirmasi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Temukan strategi dan kriteria entry dengan performa terbaik',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Setup Performance List
          Text(
            'Performa Berdasarkan Setup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (setupStats.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Belum ada data setup trading.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: setupStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = setupStats[index];
                return _buildSetupItemCard(context, item);
              },
            ),
          const SizedBox(height: 32),

          // Checklist Analytics List
          Text(
            'Efektivitas Checklist Konfirmasi Entry',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Melihat tingkat kemenangan (win rate) berdasarkan kombinasi checklist yang dicentang saat entry',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (checklistStats.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Belum ada data konfirmasi checklist entry.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checklistStats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = checklistStats[index];
                return _buildChecklistItemCard(context, item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSetupItemCard(BuildContext context, SetupStats item) {
    final profitColor = item.totalProfitPercent >= 0 ? AppColors.profit : AppColors.loss;
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Name & Trade Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.totalTrades} Trade',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Middle: Win Rate
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${item.winRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: item.winRate >= 50 ? AppColors.profit : AppColors.loss,
                  ),
                ),
                const Text(
                  'Win Rate',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 32),

            // Right: Profit %
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatPercent(item.totalProfitPercent),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: profitColor,
                  ),
                ),
                const Text(
                  'Total Profit',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItemCard(BuildContext context, ChecklistStats item) {
    final isIndividual = item.combination.endsWith('(Individual)');
    final displayName = isIndividual 
        ? item.combination.replaceAll(' (Individual)', '') 
        : item.combination;

    return Card(
      color: isIndividual ? AppColors.surface.withOpacity(0.5) : AppColors.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon indicators
            Icon(
              isIndividual ? Icons.check_circle_outline_rounded : Icons.dynamic_feed_rounded,
              color: isIndividual ? AppColors.accent : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),

            // Combination Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: isIndividual ? FontWeight.normal : FontWeight.bold, 
                      fontSize: 13, 
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.totalTrades} Trade dicatat',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Win Rate
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (item.winRate >= 60 
                    ? AppColors.profit 
                    : item.winRate >= 45 
                        ? AppColors.neutral 
                        : AppColors.loss).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.winRate.toStringAsFixed(0)}% WR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: item.winRate >= 60 
                      ? AppColors.profit 
                      : item.winRate >= 45 
                          ? AppColors.textPrimary 
                          : AppColors.loss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
