import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/stats_calculator.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';
import '../../providers/account_provider.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Normalize date to midnight
  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Map<DateTime, List<Trade>> _groupTradesByDay(List<Trade> trades) {
    final Map<DateTime, List<Trade>> data = {};
    for (final trade in trades) {
      final date = _normalizeDate(trade.entryTime);
      data.putIfAbsent(date, () => []).add(trade);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount = ref.watch(selectedAccountProvider);
    final tradesState = ref.watch(tradeNotifierProvider);

    if (selectedAccount == null) {
      return const Center(child: Text('Silakan pilih akun trading terlebih dahulu.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return tradesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (trades) {
        final groupedTrades = _groupTradesByDay(trades);
        final selectedDateNormalized = _normalizeDate(_selectedDay ?? _focusedDay);
        final selectedDayTrades = groupedTrades[selectedDateNormalized] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kalender Trading',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              
              // Calendar Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    // TableCalendar styling for Dark Theme
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(color: AppColors.loss, fontWeight: FontWeight.bold),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      titleCentered: true,
                      titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                    ),
                    calendarBuilders: CalendarBuilders(
                      todayBuilder: (context, day, _) => _buildCalendarCell(day, groupedTrades, isToday: true),
                      selectedBuilder: (context, day, _) => _buildCalendarCell(day, groupedTrades, isSelected: true),
                      defaultBuilder: (context, day, _) => _buildCalendarCell(day, groupedTrades),
                      outsideBuilder: (context, day, _) => _buildCalendarCell(day, groupedTrades, isOutside: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Day Details Card
              _buildDayDetailSection(selectedDateNormalized, selectedDayTrades),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarCell(
    DateTime day, 
    Map<DateTime, List<Trade>> groupedTrades, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final normalized = _normalizeDate(day);
    final dayTrades = groupedTrades[normalized] ?? [];
    
    // Calculate PnL for cell
    double dailyPnl = 0;
    for (final t in dayTrades) {
      dailyPnl += t.profitLossPercent;
    }

    Color cellColor = Colors.transparent;
    Color borderVal = Colors.transparent;
    
    if (isSelected) {
      borderVal = AppColors.primary;
    } else if (isToday) {
      borderVal = AppColors.accent.withOpacity(0.5);
    }

    Color? textColor = isOutside ? AppColors.textMuted : AppColors.textPrimary;
    Color? pnlColor;
    
    if (dayTrades.isNotEmpty) {
      if (dailyPnl > 0) {
        cellColor = AppColors.profit.withOpacity(0.12);
        pnlColor = AppColors.profit;
      } else if (dailyPnl < 0) {
        cellColor = AppColors.loss.withOpacity(0.12);
        pnlColor = AppColors.loss;
      } else {
        cellColor = AppColors.neutral.withOpacity(0.12);
        pnlColor = AppColors.neutral;
      }
    }

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(8),
        border: borderVal != Colors.transparent ? Border.all(color: borderVal, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
              fontSize: 13,
            ),
          ),
          if (dayTrades.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              Formatters.formatPercent(dailyPnl),
              style: TextStyle(
                color: pnlColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${dayTrades.length} Setup',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayDetailSection(DateTime date, List<Trade> trades) {
    final selectedAccount = ref.read(selectedAccountProvider);
    if (selectedAccount == null) return const SizedBox();

    if (trades.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                Formatters.formatDate(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada trade pada hari ini.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/trade/add'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Trade'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = StatsCalculator.calculate(trades);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDate(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/trade/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Trade'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Performance metrics grid for that day
            _buildDayStatsGrid(stats, selectedAccount.currency),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 8),

            // Title
            Text(
              'Daftar Trade (${trades.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Trade items list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trade = trades[index];
                return _buildTradeRow(trade);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStatsGrid(TradeStats stats, String currency) {
    final profitColor = stats.totalProfitPercent >= 0 ? AppColors.profit : AppColors.loss;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: constraints.maxWidth > 600 ? 2.2 : 1.8,
          children: [
            _buildSmallStatTile('Total Profit (%)', Formatters.formatPercent(stats.totalProfitPercent), color: profitColor),
            _buildSmallStatTile('Total Profit ($currency)', Formatters.formatCurrency(stats.totalProfitAmount, currency), color: profitColor),
            _buildSmallStatTile('Win Rate', '${stats.winRate.toStringAsFixed(0)}%', color: stats.winRate >= 50 ? AppColors.profit : AppColors.loss),
            _buildSmallStatTile('Win / Loss', '${stats.totalWins} W / ${stats.totalLosses} L'),
            _buildSmallStatTile('Avg RR', stats.averageRR.toStringAsFixed(1)),
            _buildSmallStatTile('Total Trade', '${stats.totalTrades}'),
          ],
        );
      },
    );
  }

  Widget _buildSmallStatTile(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeRow(Trade trade) {
    final isWin = trade.status == 'Win';
    final isLoss = trade.status == 'Loss';
    final statusColor = isWin
        ? AppColors.profit
        : isLoss
            ? AppColors.loss
            : AppColors.neutral;

    return Card(
      color: AppColors.surfaceLight,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: () => context.push('/trade/detail/${trade.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.pair,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (trade.setups.isNotEmpty)
                      Text(
                        trade.setups.join(', '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatPercent(trade.profitLossPercent),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    trade.status,
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
