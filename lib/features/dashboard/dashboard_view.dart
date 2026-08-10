import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats_calculator.dart';
import '../../models/trade.dart';
import '../../models/trading_account.dart';
import '../../providers/account_provider.dart';
import '../../providers/trade_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final tradesState = ref.watch(tradeNotifierProvider);

    if (selectedAccount == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Silakan pilih akun trading terlebih dahulu di halaman Pengaturan.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return tradesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.loss))),
      data: (trades) {
        final stats = StatsCalculator.calculate(trades, initialBalance: selectedAccount.initialBalance);
        
        final double initialBalance = selectedAccount.initialBalance;
        final double currentBalance = initialBalance + stats.totalProfitAmount;
        final double totalProfitPercent = (initialBalance > 0) 
            ? (stats.totalProfitAmount / initialBalance) * 100 
            : 0.0;

        // Calculate recent periods
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfMonth = DateTime(now.year, now.month, 1);

        final tradesToday = trades.where((t) => t.entryTime.isAfter(startOfToday)).toList();
        final tradesThisWeek = trades.where((t) => t.entryTime.isAfter(startOfWeek)).toList();
        final tradesThisMonth = trades.where((t) => t.entryTime.isAfter(startOfMonth)).toList();

        final statsToday = StatsCalculator.calculate(tradesToday);
        final statsWeek = StatsCalculator.calculate(tradesThisWeek);
        final statsMonth = StatsCalculator.calculate(tradesThisMonth);

        return RefreshIndicator(
          onRefresh: () => ref.read(tradeNotifierProvider.notifier).loadTrades(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Overview Header Card
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAccount.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.currency_exchange_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mata Uang: ${selectedAccount.currency}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/trade/add'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Trade'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Modal Awal',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(initialBalance, selectedAccount.currency),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppColors.border,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saldo Saat Ini',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(currentBalance, selectedAccount.currency),
                                    style: TextStyle(
                                      color: currentBalance >= initialBalance ? AppColors.profit : AppColors.loss,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 120, // Fixed height increased to avoid overflow
                      ),
                      children: [
                        _buildStatCard(
                          context,
                          'Total Profit/Loss',
                          Formatters.formatCurrency(stats.totalProfitAmount, selectedAccount.currency),
                          subtitle: stats.totalProfitAmount >= 0 ? 'Surplus' : 'Defisit',
                          color: stats.totalProfitAmount >= 0 ? AppColors.profit : AppColors.loss,
                          icon: Icons.payments_outlined,
                        ),
                        _buildStatCard(
                          context,
                          'Total Profit %',
                          Formatters.formatPercent(totalProfitPercent),
                          subtitle: 'Persentase Kumulatif',
                          color: totalProfitPercent >= 0 ? AppColors.profit : AppColors.loss,
                          icon: Icons.percent_rounded,
                        ),
                        _buildStatCard(
                          context,
                          'Win Rate',
                          '${stats.winRate.toStringAsFixed(1)}%',
                          subtitle: '${stats.totalWins} Win / ${stats.totalLosses} Loss',
                          color: stats.winRate >= 50 ? AppColors.profit : AppColors.loss,
                          icon: Icons.emoji_events_outlined,
                        ),
                        _buildStatCard(
                          context,
                          'Total Trade',
                          '${stats.totalTrades}',
                          subtitle: 'Jumlah Setup Terbuka',
                          color: AppColors.primary,
                          icon: Icons.import_contacts_rounded,
                        ),
                        _buildStatCard(
                          context,
                          'Winning Streak',
                          '${stats.maxWinStreak} Beruntun',
                          subtitle: 'Rekor Profit Beruntun',
                          color: AppColors.profit,
                          icon: Icons.trending_up_rounded,
                        ),
                        _buildStatCard(
                          context,
                          'Losing Streak',
                          '${stats.maxLossStreak} Beruntun',
                          subtitle: 'Rekor Loss Beruntun',
                          color: AppColors.loss,
                          icon: Icons.trending_down_rounded,
                        ),
                        _buildStatCard(
                          context,
                          'Max Drawdown',
                          Formatters.formatPercent(-stats.maxDrawdownPercent),
                          subtitle: Formatters.formatCurrency(-stats.maxDrawdownAmount, selectedAccount.currency),
                          color: AppColors.loss,
                          icon: Icons.show_chart_rounded,
                        ),
                        _buildStatCard(
                          context,
                          'Profit Factor',
                          stats.profitFactor.isInfinite ? '∞' : stats.profitFactor.toStringAsFixed(2),
                          subtitle: 'Rasio Risk/Reward Gross',
                          color: stats.profitFactor >= 1.5 ? AppColors.profit : AppColors.loss,
                          icon: Icons.analytics_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Timeframe summaries: Today, Week, Month
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktivitas Periode Ini',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPeriodCol(
                                'Hari Ini',
                                tradesToday.length,
                                statsToday.totalProfitPercent,
                                statsToday.totalProfitAmount,
                                selectedAccount.currency,
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                              child: VerticalDivider(width: 32),
                            ),
                            Expanded(
                              child: _buildPeriodCol(
                                'Minggu Ini',
                                tradesThisWeek.length,
                                statsWeek.totalProfitPercent,
                                statsWeek.totalProfitAmount,
                                selectedAccount.currency,
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                              child: VerticalDivider(width: 32),
                            ),
                            Expanded(
                              child: _buildPeriodCol(
                                'Bulan Ini',
                                tradesThisMonth.length,
                                statsMonth.totalProfitPercent,
                                statsMonth.totalProfitAmount,
                                selectedAccount.currency,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Equity Curve Section with Zoom & Pan (TradingView style)
                _EquityCurveSection(
                  trades: trades,
                  account: selectedAccount,
                ),
                const SizedBox(height: 24),

                // Recent trades header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trade Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recent Trades List
                if (trades.isEmpty)
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('Belum ada trade dicatat', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.push('/trade/add'),
                              child: const Text('Catat Trade Pertama Anda'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trades.length > 5 ? 5 : trades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final trade = trades[index];
                      return _buildRecentTradeItem(context, trade, selectedAccount.currency);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value, {
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCol(String label, int tradeCount, double pnlPercent, double pnlAmount, String currency) {
    final color = pnlAmount >= 0 ? AppColors.profit : AppColors.loss;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$tradeCount Setup',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatPercent(pnlPercent),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          Formatters.formatCurrency(pnlAmount, currency),
          style: TextStyle(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTradeItem(BuildContext context, Trade trade, String currency) {
    final isWin = trade.status == 'Win';
    final isLoss = trade.status == 'Loss';
    final statusColor = isWin
        ? AppColors.profit
        : isLoss
            ? AppColors.loss
            : AppColors.neutral;

    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: () => context.push('/trade/detail/${trade.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trade.direction == 'Buy' 
                      ? AppColors.profit.withOpacity(0.1) 
                      : AppColors.loss.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trade.direction.toUpperCase(),
                  style: TextStyle(
                    color: trade.direction == 'Buy' ? AppColors.profit : AppColors.loss,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.pair,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trade.setups.isNotEmpty ? trade.setups.join(', ') : 'No Setup',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatDate(trade.entryTime),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatPercent(trade.profitLossPercent),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(trade.profitLossAmount, currency),
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquityCurveSection extends StatelessWidget {
  final List<Trade> trades;
  final TradingAccount account;

  const _EquityCurveSection({
    required this.trades,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kurva Ekuitas (Equity Curve)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Grafik pertumbuhan saldo berdasarkan histori trade',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: trades.isEmpty
                  ? const Center(child: Text('Belum ada data trade untuk grafik ekuitas.', style: TextStyle(color: AppColors.textSecondary)))
                  : _buildEquityCurveChart(context, trades, account),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityCurveChart(BuildContext context, List<Trade> trades, TradingAccount account) {
    // Sort trades oldest to newest
    final sorted = List<Trade>.from(trades)
      ..sort((a, b) => a.entryTime.compareTo(b.entryTime));

    final spots = <FlSpot>[FlSpot(0, account.initialBalance)];
    double currentBalance = account.initialBalance;
    
    double minY = account.initialBalance;
    double maxY = account.initialBalance;

    for (int i = 0; i < sorted.length; i++) {
      currentBalance += sorted[i].profitLossAmount;
      spots.add(FlSpot((i + 1).toDouble(), currentBalance));
      if (currentBalance < minY) minY = currentBalance;
      if (currentBalance > maxY) maxY = currentBalance;
    }

    final double diffY = maxY - minY;
    
    // Choose a nice, rounded interval based on the range to make Y axis extremely accurate
    double yInterval = 10.0;
    double adjustedMinY = minY - 10.0;
    double adjustedMaxY = maxY + 10.0;

    if (diffY > 0) {
      double rawInterval = diffY / 4;
      double exponent = (math.log(rawInterval) / math.ln10).floorToDouble();
      double fraction = rawInterval / math.pow(10, exponent);
      
      double niceFraction;
      if (fraction < 1.5) {
        niceFraction = 1.0;
      } else if (fraction < 3.0) {
        niceFraction = 2.0;
      } else if (fraction < 7.0) {
        niceFraction = 5.0;
      } else {
        niceFraction = 10.0;
      }
      
      yInterval = niceFraction * math.pow(10, exponent);
      
      adjustedMinY = (minY / yInterval).floorToDouble() * yInterval;
      adjustedMaxY = (maxY / yInterval).ceilToDouble() * yInterval;
      
      // Ensure there is some padding if data points are exactly on boundary
      if (minY - adjustedMinY < yInterval * 0.1) {
        adjustedMinY -= yInterval;
      }
      if (adjustedMaxY - maxY < yInterval * 0.1) {
        adjustedMaxY += yInterval;
      }
    }

    // Scrollable width calculation: each spot gets 22 pixels width
    final double spotSpacing = 22.0;
    final double computedWidth = spots.length * spotSpacing;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Padding: Card (16x2) + Main Layout (16x2) = 64px. Y-axis is 50px.
    // Net space for chart = screenWidth - 114.
    final double availableChartWidth = screenWidth - 114;
    final double chartWidth = computedWidth > availableChartWidth ? computedWidth : availableChartWidth;

    double xInterval = 2.0;
    if (spots.length > 150) {
      xInterval = 20.0;
    } else if (spots.length > 80) {
      xInterval = 10.0;
    } else if (spots.length > 30) {
      xInterval = 5.0;
    }

    return Row(
      children: [
        // 1. Fixed Y-Axis
        SizedBox(
          width: 50,
          height: 250,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: adjustedMinY,
              maxY: adjustedMaxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [],
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22, // Align with chart's bottomTitles height
                    getTitlesWidget: (_, __) => const SizedBox(),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(
                          _abbreviateAmount(value, account.currency),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          textAlign: TextAlign.end,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Scrollable Chart Body
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 250,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppColors.surface,
                        tooltipBorder: const BorderSide(color: AppColors.border, width: 1.5),
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              Formatters.formatCurrency(touchedSpot.y, account.currency),
                              const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: adjustedMinY,
                    maxY: adjustedMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hidden as it is fixed on the left
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: xInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: const Text('Start', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              );
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '#${value.toInt()}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                        left: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.25),
                              AppColors.primary.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _abbreviateAmount(double value, String currency) {
    final double absVal = value.abs();
    final String sign = value >= 0 ? '' : '-';
    
    if (currency == 'IDR') {
      if (absVal >= 1000000) {
        return '$sign${(absVal / 1000000).toStringAsFixed(1)}jt';
      } else if (absVal >= 1000) {
        return '$sign${(absVal / 1000).toStringAsFixed(0)}rb';
      }
      return '$sign${absVal.toStringAsFixed(0)}';
    } else if (currency == 'USC') {
      if (absVal >= 1000) {
        return '$sign${(absVal / 1000).toStringAsFixed(1)}K';
      }
      return '$sign${absVal.toStringAsFixed(0)}';
    } else {
      // USD
      if (absVal >= 1000000) {
        return '$sign\$${(absVal / 1000000).toStringAsFixed(1)}M';
      } else if (absVal >= 1000) {
        return '$sign\$${(absVal / 1000).toStringAsFixed(1)}K';
      }
      return '$sign\$${absVal.toStringAsFixed(2)}';
    }
  }
}
