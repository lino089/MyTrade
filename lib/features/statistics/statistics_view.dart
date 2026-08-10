import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats_calculator.dart';
import '../../models/trade.dart';
import '../../providers/trade_filter_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/trading_account.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTrades = ref.watch(filteredTradesProvider);
    final filterState = ref.watch(tradeFilterProvider);
    final filterNotifier = ref.read(tradeFilterProvider.notifier);
    final account = ref.watch(selectedAccountProvider);

    final stats = StatsCalculator.calculate(filteredTrades, initialBalance: account?.initialBalance ?? 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Portofolio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),

          // Filters Card
          _buildFiltersCard(context, filterState, filterNotifier),
          const SizedBox(height: 24),

          if (filteredTrades.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada trade yang cocok dengan filter aktif.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => filterNotifier.clearAll(),
                        child: const Text('Reset Filter'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Stats Grid
            _buildStatsCardsGrid(context, stats, account),
            const SizedBox(height: 24),

            // Charts Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Column(
                  children: [
                    // Row 1: Equity Curve & Monthly Profit
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildEquityCurve(filteredTrades),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildMonthlyProfitChart(filteredTrades),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildEquityCurve(filteredTrades),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildMonthlyProfitChart(filteredTrades),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Row 2: Win vs Loss Pie & Setup Distribution Pie
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildWinLossPie(stats),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildSetupDistributionPie(filteredTrades),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildWinLossPie(stats),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildSetupDistributionPie(filteredTrades),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersCard(
    BuildContext context,
    TradeFilterState filter,
    TradeFilterNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => notifier.clearAll(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Column(
                  children: [
                    // Row 1: Search & Date Picker
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (val) => notifier.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Cari pair, setup, catatan...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              fillColor: AppColors.surfaceLight,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDateRange: filter.dateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: AppColors.primary,
                                        surface: AppColors.surface,
                                        onPrimary: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (range != null) {
                                notifier.setDateRange(range);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              filter.dateRange == null
                                  ? 'Rentang Tanggal'
                                  : '${Formatters.formatDate(filter.dateRange!.start)} - ${Formatters.formatDate(filter.dateRange!.end)}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Dropdowns
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDropdownFilter(
                          hint: 'Semua Pair',
                          value: filter.pair,
                          items: AppConstants.defaultPairs,
                          onChanged: (val) => notifier.setPair(val),
                        ),
                        _buildDropdownFilter(
                          hint: 'Semua Setup',
                          value: filter.setup,
                          items: AppConstants.defaultSetups,
                          onChanged: (val) => notifier.setSetup(val),
                        ),
                        _buildDropdownFilter(
                          hint: 'Buy / Sell',
                          value: filter.direction,
                          items: const ['Buy', 'Sell'],
                          onChanged: (val) => notifier.setDirection(val),
                        ),
                        _buildDropdownFilter(
                          hint: 'Win / Loss',
                          value: filter.status,
                          items: const ['Win', 'Loss', 'Break Even'],
                          onChanged: (val) => notifier.setStatus(val),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          dropdownColor: AppColors.surfaceLight,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatsCardsGrid(BuildContext context, TradeStats stats, TradingAccount? account) {
    final profitColor = stats.totalProfitPercent >= 0 ? AppColors.profit : AppColors.loss;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _buildStatMetricCard(context, 'Total Trade', '${stats.totalTrades}', 'W:${stats.totalWins} L:${stats.totalLosses} BE:${stats.totalBreakEvens}'),
            _buildStatMetricCard(context, 'Win Rate', '${stats.winRate.toStringAsFixed(1)}%', 'Rasio Kemenangan', color: stats.winRate >= 50 ? AppColors.profit : AppColors.loss),
            _buildStatMetricCard(context, 'Max Drawdown', Formatters.formatPercent(-stats.maxDrawdownPercent), Formatters.formatCurrency(-stats.maxDrawdownAmount, account?.currency ?? 'USD'), color: AppColors.loss),
            _buildStatMetricCard(context, 'Profit Factor', stats.profitFactor.isInfinite ? '∞' : stats.profitFactor.toStringAsFixed(2), 'Faktor Keuntungan', color: stats.profitFactor >= 1.5 ? AppColors.profit : AppColors.loss),
            _buildStatMetricCard(context, 'Total Profit (\$)', Formatters.formatCurrency(stats.totalProfitAmount), 'Total Bersih', color: profitColor),
            _buildStatMetricCard(context, 'Total Profit (%)', Formatters.formatPercent(stats.totalProfitPercent), 'Persentase Total', color: profitColor),
            _buildStatMetricCard(context, 'Average RR', stats.averageRR.toStringAsFixed(2), 'Risk Reward Rerata'),
            _buildStatMetricCard(context, 'Avg Profit', Formatters.formatPercent(stats.averageProfitPercent), Formatters.formatCurrency(stats.averageProfitAmount), color: AppColors.profit),
            _buildStatMetricCard(context, 'Avg Loss', Formatters.formatPercent(stats.averageLossPercent), Formatters.formatCurrency(stats.averageLossAmount), color: AppColors.loss),
            _buildStatMetricCard(context, 'Win Streak', '${stats.maxWinStreak} Trade', 'Streak Win Terpanjang', color: AppColors.profit),
            _buildStatMetricCard(context, 'Loss Streak', '${stats.maxLossStreak} Trade', 'Streak Loss Terpanjang', color: AppColors.loss),
          ],
        );
      },
    );
  }

  Widget _buildStatMetricCard(
    BuildContext context,
    String label,
    String value,
    String subtitle, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEquityCurve(List<Trade> trades) {
    final sorted = List<Trade>.from(trades)
      ..sort((a, b) => a.entryTime.compareTo(b.entryTime));

    final spots = <FlSpot>[const FlSpot(0, 0)];
    double cumulative = 0.0;
    
    for (int i = 0; i < sorted.length; i++) {
      cumulative += sorted[i].profitLossPercent;
      spots.add(FlSpot((i + 1).toDouble(), cumulative));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kurva Ekuitas (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: const FlTitlesData(
                show: true,
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: AppColors.border),
                  left: BorderSide(color: AppColors.border),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyProfitChart(List<Trade> trades) {
    // Group profits by Month/Year
    final Map<String, double> monthlyPnl = {};
    
    for (final trade in trades) {
      final key = '${trade.entryTime.year}-${trade.entryTime.month.toString().padLeft(2, "0")}';
      monthlyPnl[key] = (monthlyPnl[key] ?? 0.0) + trade.profitLossPercent;
    }

    final sortedKeys = monthlyPnl.keys.toList()..sort();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final val = monthlyPnl[key]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: val >= 0 ? AppColors.profit : AppColors.loss,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profit Bulanan (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: barGroups.isEmpty
              ? const Center(child: Text('Data bulanan tidak tersedia.'))
              : BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= sortedKeys.length) return const SizedBox();
                            // Convert '2026-07' to 'Jul 26'
                            final parts = sortedKeys[idx].split('-');
                            final month = int.parse(parts[1]);
                            final yr = parts[0].substring(2);
                            final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
                            return Text(
                              '${monthNames[month - 1]} $yr',
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: barGroups,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWinLossPie(TradeStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rasio Win vs Loss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.profit,
                        value: stats.totalWins.toDouble(),
                        title: '${stats.totalWins}',
                        radius: 50,
                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppColors.loss,
                        value: stats.totalLosses.toDouble(),
                        title: '${stats.totalLosses}',
                        radius: 50,
                        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (stats.totalBreakEvens > 0)
                        PieChartSectionData(
                          color: AppColors.neutral,
                          value: stats.totalBreakEvens.toDouble(),
                          title: '${stats.totalBreakEvens}',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendIndicator('Wins', AppColors.profit),
                  const SizedBox(height: 8),
                  _buildLegendIndicator('Losses', AppColors.loss),
                  const SizedBox(height: 8),
                  _buildLegendIndicator('Break Evens', AppColors.neutral),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupDistributionPie(List<Trade> trades) {
    final Map<String, int> setupCounts = {};
    for (final t in trades) {
      for (final s in t.setups) {
        setupCounts[s] = (setupCounts[s] ?? 0) + 1;
      }
    }

    final sortedSetups = setupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pick top 4 setups, group others
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];
    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      AppColors.neutral,
    ];

    int otherSum = 0;
    for (int i = 0; i < sortedSetups.length; i++) {
      if (i < 4) {
        final color = colors[i];
        sections.add(
          PieChartSectionData(
            color: color,
            value: sortedSetups[i].value.toDouble(),
            title: '${sortedSetups[i].value}',
            radius: 50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
          ),
        );
        legends.add(_buildLegendIndicator(sortedSetups[i].key, color));
        legends.add(const SizedBox(height: 6));
      } else {
        otherSum += sortedSetups[i].value;
      }
    }

    if (otherSum > 0) {
      final otherColor = colors[4];
      sections.add(
        PieChartSectionData(
          color: otherColor,
          value: otherSum.toDouble(),
          title: '$otherSum',
          radius: 50,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
        ),
      );
      legends.add(_buildLegendIndicator('Lainnya', otherColor));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distribusi Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: sections.isEmpty
                    ? const Center(child: Text('Tidak ada data setup.'))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                      ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legends,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
