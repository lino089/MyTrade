import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';

class TradeDetailScreen extends ConsumerWidget {
  final String tradeId;

  const TradeDetailScreen({
    super.key,
    required this.tradeId,
  });

  void _showFullScreenImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withOpacity(0.95),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: imageUrl.startsWith('data:image/')
                    ? Image.memory(
                        base64Decode(imageUrl.split(',')[1]),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Trade trade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Trade'),
        content: Text('Apakah Anda yakin ingin menghapus trade ${trade.pair} ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.loss),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tradeNotifierProvider.notifier).deleteTrade(trade.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade berhasil dihapus'), backgroundColor: AppColors.loss),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesState = ref.watch(tradeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Trading'),
      ),
      body: tradesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (trades) {
          final tradeIndex = trades.indexWhere((t) => t.id == tradeId);
          if (tradeIndex == -1) {
            return const Center(child: Text('Trade tidak ditemukan.'));
          }
          final trade = trades[tradeIndex];
          
          final isWin = trade.status == 'Win';
          final isLoss = trade.status == 'Loss';
          final statusColor = isWin
              ? AppColors.profit
              : isLoss
                  ? AppColors.loss
                  : AppColors.neutral;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          trade.pair,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: trade.direction == 'Buy' 
                                                ? AppColors.profit.withOpacity(0.12) 
                                                : AppColors.loss.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            trade.direction.toUpperCase(),
                                            style: TextStyle(
                                              color: trade.direction == 'Buy' ? AppColors.profit : AppColors.loss,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatDateTime(trade.entryTime),
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trade.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Core values Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricCol(context, 'HASIL (%)', Formatters.formatPercent(trade.profitLossPercent), statusColor),
                                _buildMetricCol(context, 'HASIL (\$)', Formatters.formatCurrency(trade.profitLossAmount), statusColor),
                                _buildMetricCol(context, 'RISK REWARD (RR)', trade.riskRewardRatio?.toStringAsFixed(1) ?? '-', AppColors.textPrimary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Setup & Parameters Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detail Transaksi', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            _buildInfoRow('Lot Size', trade.lotSize != null ? '${trade.lotSize}' : '-'),
                            _buildInfoRow('Risk (%)', trade.riskPercent != null ? '${trade.riskPercent}%' : '-'),
                            _buildInfoRow('Waktu Masuk (Entry)', Formatters.formatDateTime(trade.entryTime)),
                            _buildInfoRow(
                              'Waktu Keluar (Exit)', 
                              trade.exitTime != null ? Formatters.formatDateTime(trade.exitTime!) : '-',
                            ),
                            _buildInfoRow(
                              'Durasi Trade', 
                              Formatters.formatDuration(trade.entryTime, trade.exitTime),
                            ),
                            const Divider(height: 24),
                            
                            // Setups Tag List
                            const Text('Setup Digunakan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (trade.setups.isEmpty)
                              const Text('Tidak ada setup terpilih')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: trade.setups.map((setup) {
                                  return Chip(
                                    label: Text(setup, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppColors.surfaceLight,
                                    side: const BorderSide(color: AppColors.border),
                                    padding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Entry Checklist Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Checklist Alasan Entry', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            if (trade.entryChecklist.isEmpty)
                              const Text('Tidak ada alasan checklist terpilih', style: TextStyle(color: AppColors.textSecondary))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: AppConstants.defaultChecklist.length,
                                itemBuilder: (context, idx) {
                                  final item = AppConstants.defaultChecklist[idx];
                                  final isChecked = trade.entryChecklist.contains(item);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isChecked ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                          color: isChecked ? AppColors.profit : AppColors.textMuted,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          item,
                                          style: TextStyle(
                                            color: isChecked ? AppColors.textPrimary : AppColors.textMuted,
                                            decoration: isChecked ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Catatan Trading', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            if (trade.notes == null || trade.notes!.trim().isEmpty)
                              const Text('Belum ada catatan.', style: TextStyle(color: AppColors.textSecondary))
                            else
                              Text(
                                trade.notes!,
                                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Screenshots Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Screenshots', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildScreenshotPlaceholder(
                                    context,
                                    trade.screenshotBeforeUrl,
                                    'Sebelum Entry (Before)',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildScreenshotPlaceholder(
                                    context,
                                    trade.screenshotAfterUrl,
                                    'Setelah Close (After)',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(context, ref, trade),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.loss),
                            label: const Text('Hapus Trade', style: TextStyle(color: AppColors.loss)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.loss),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/trade/edit/${trade.id}'),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Trade'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCol(BuildContext context, String label, String value, Color color) {
    return Column(
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
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScreenshotPlaceholder(BuildContext context, String? url, String label) {
    final hasImage = url != null && url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? GestureDetector(
                    onTap: () => _showFullScreenImage(context, url, label),
                    child: Hero(
                      tag: url,
                      child: url.startsWith('data:image/')
                          ? Image.memory(
                              base64Decode(url.split(',')[1]),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28),
                              ),
                            ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                        SizedBox(height: 4),
                        Text('No Image', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
