import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../models/trade.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trade_provider.dart';
import 'widgets/note_editor.dart';

class TradeFormScreen extends ConsumerStatefulWidget {
  final String? tradeId;

  const TradeFormScreen({
    super.key,
    this.tradeId,
  });

  @override
  ConsumerState<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends ConsumerState<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info Controllers
  String _selectedPair = AppConstants.defaultPairs.first;
  String _direction = 'Buy';
  DateTime _entryDate = DateTime.now();
  TimeOfDay _entryTime = TimeOfDay.now();
  TimeOfDay? _exitTime;
  
  // TP/SL/Result Controllers
  final _tpController = TextEditingController();
  final _slController = TextEditingController();
  String _result = 'TP';
  
  // Setups & Checklist
  final List<String> _selectedSetups = [];
  final List<String> _checkedList = [];
  
  // Notes
  final _notesController = TextEditingController();

  // Screenshots
  Uint8List? _beforeImageBytes;
  String? _beforeImageName;
  String? _beforeImageUrl;

  Uint8List? _afterImageBytes;
  String? _afterImageName;
  String? _afterImageUrl;

  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.tradeId != null) {
      _loadExistingTrade();
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _tpController.dispose();
    _slController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingTrade() {
    final trades = ref.read(tradeNotifierProvider).value ?? [];
    final tradeIndex = trades.indexWhere((t) => t.id == widget.tradeId);
    if (tradeIndex != -1) {
      final trade = trades[tradeIndex];
      setState(() {
        _selectedPair = trade.pair;
        _direction = trade.direction;
        _entryDate = trade.entryTime;
        _entryTime = TimeOfDay.fromDateTime(trade.entryTime);
        if (trade.exitTime != null) {
          _exitTime = TimeOfDay.fromDateTime(trade.exitTime!);
        }
        
        _tpController.text = trade.tp.toString();
        _slController.text = trade.sl.toString();
        _result = trade.result;
        
        _selectedSetups.addAll(trade.setups);
        _checkedList.addAll(trade.entryChecklist);
        _notesController.text = trade.notes ?? '';
        _beforeImageUrl = trade.screenshotBeforeUrl;
        _afterImageUrl = trade.screenshotAfterUrl;
      });
    }
  }

  Future<void> _pickImage(bool isBefore) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isBefore) {
            _beforeImageBytes = bytes;
            _beforeImageName = image.name;
          } else {
            _afterImageBytes = bytes;
            _afterImageName = image.name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e'), backgroundColor: AppColors.loss),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedAccount = ref.read(selectedAccountProvider);
    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Akun trading tidak terpilih'), backgroundColor: AppColors.loss),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.userId ?? 'mock-user-123';

      final entryDateTime = DateTime(
        _entryDate.year,
        _entryDate.month,
        _entryDate.day,
        _entryTime.hour,
        _entryTime.minute,
      );

      DateTime? exitDateTime;
      if (_exitTime != null) {
        exitDateTime = DateTime(
          _entryDate.year,
          _entryDate.month,
          _entryDate.day,
          _exitTime!.hour,
          _exitTime!.minute,
        );
        if (exitDateTime.isBefore(entryDateTime)) {
          exitDateTime = exitDateTime.add(const Duration(days: 1));
        }
      }

      final tp = double.parse(_tpController.text.trim());
      final sl = double.parse(_slController.text.trim());
      
      final double pnlAmount;
      if (_result == 'TP') {
        pnlAmount = tp;
      } else if (_result == 'SL') {
        pnlAmount = -sl;
      } else {
        pnlAmount = 0.0;
      }

      // Percentage calculation relative to initial balance
      final double pnlPercent = (selectedAccount.initialBalance > 0)
          ? (pnlAmount / selectedAccount.initialBalance) * 100
          : 0.0;

      final status = _result == 'TP' ? 'Win' : (_result == 'SL' ? 'Loss' : 'Break Even');
      final id = widget.tradeId ?? const Uuid().v4();

      // Handle screenshots
      String? beforeUrl = _beforeImageUrl;
      if (_beforeImageBytes != null && _beforeImageName != null) {
        beforeUrl = await ref.read(tradeNotifierProvider.notifier).uploadScreenshot(
              id,
              _beforeImageBytes!,
              _beforeImageName!,
              true,
            );
      }

      String? afterUrl = _afterImageUrl;
      if (_afterImageBytes != null && _afterImageName != null) {
        afterUrl = await ref.read(tradeNotifierProvider.notifier).uploadScreenshot(
              id,
              _afterImageBytes!,
              _afterImageName!,
              false,
            );
      }

      final trade = Trade(
        id: id,
        userId: userId,
        accountId: selectedAccount.id,
        pair: _selectedPair,
        direction: _direction,
        entryTime: entryDateTime,
        exitTime: exitDateTime,
        profitLossPercent: pnlPercent,
        profitLossAmount: pnlAmount,
        status: status,
        tp: tp,
        sl: sl,
        result: _result,
        setups: _selectedSetups,
        entryChecklist: _checkedList,
        screenshotBeforeUrl: beforeUrl,
        screenshotAfterUrl: afterUrl,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.tradeId != null) {
        await ref.read(tradeNotifierProvider.notifier).updateTrade(trade);
      } else {
        await ref.read(tradeNotifierProvider.notifier).addTrade(trade);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.tradeId != null ? 'Trade diperbarui!' : 'Trade baru ditambahkan!'),
            backgroundColor: AppColors.profit,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.loss),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tradeId != null;
    final selectedAccount = ref.watch(selectedAccountProvider);
    final currency = selectedAccount?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Catatan Trade' : 'Tambah Catatan Trade'),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyimpan catatan trading...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic Parameters Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Informasi Dasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPairDropdown(),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDirectionSelector(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDatePicker(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Jam Entry',
                                        time: _entryTime,
                                        onSelected: (time) {
                                          setState(() => _entryTime = time);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTimePicker(
                                        label: 'Jam Exit (Opsional)',
                                        time: _exitTime,
                                        onSelected: (time) {
                                          setState(() => _exitTime = time);
                                        },
                                        isClearable: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Trade Results Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hasil Trading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _tpController,
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Target Profit ($currency)',
                                          hintText: 'Misal: 50.0',
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Harus diisi';
                                          if (double.tryParse(val) == null) return 'Angka tidak valid';
                                          if (double.parse(val) < 0) return 'Tidak boleh negatif';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _slController,
                                        style: const TextStyle(color: AppColors.textPrimary),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: 'Stop Loss ($currency)',
                                          hintText: 'Misal: 20.0',
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Harus diisi';
                                          if (double.tryParse(val) == null) return 'Angka tidak valid';
                                          if (double.parse(val) < 0) return 'Tidak boleh negatif';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Hasil Transaksi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 8),
                                _buildResultChips(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Setup Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Setup Terpakai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                const Text('Pilih satu atau lebih setup yang teridentifikasi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 12),
                                _buildSetupChips(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checklist Entry Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Checklist Konfirmasi Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                const Text('Centang kriteria yang terpenuhi sebelum posisi diambil', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 12),
                                _buildChecklistGrid(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Screenshots Upload Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Screenshot Market', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildImageUploadArea(
                                        label: 'Sebelum Entry (Before)',
                                        imageUrl: _beforeImageUrl,
                                        bytes: _beforeImageBytes,
                                        onTap: () => _pickImage(true),
                                        onClear: () {
                                          setState(() {
                                            _beforeImageBytes = null;
                                            _beforeImageUrl = null;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildImageUploadArea(
                                        label: 'Setelah Close (After)',
                                        imageUrl: _afterImageUrl,
                                        bytes: _afterImageBytes,
                                        onTap: () => _pickImage(false),
                                        onClear: () {
                                          setState(() {
                                            _afterImageBytes = null;
                                            _afterImageUrl = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Note Card
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: NoteEditor(
                              controller: _notesController,
                              label: 'Catatan & Evaluasi',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            isEdit ? 'Simpan Perubahan' : 'Catat Transaksi',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPairDropdown() {
    return DropdownButtonFormField<String>(
      value: AppConstants.defaultPairs.contains(_selectedPair) ? _selectedPair : AppConstants.defaultPairs.first,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(labelText: 'Pair Mata Uang'),
      items: AppConstants.defaultPairs.map((pair) {
        return DropdownMenuItem(
          value: pair,
          child: Text(pair),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedPair = val;
          });
        }
      },
    );
  }

  Widget _buildDirectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arah Posisi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('BUY')),
                selected: _direction == 'Buy',
                selectedColor: AppColors.profit.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _direction == 'Buy' ? AppColors.profit : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _direction = 'Buy');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('SELL')),
                selected: _direction == 'Sell',
                selectedColor: AppColors.loss.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _direction == 'Sell' ? AppColors.loss : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _direction = 'Sell');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _entryDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
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
        if (date != null) {
          setState(() {
            _entryDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal Entry',
          suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
        ),
        child: Text(
          DateFormat('EEEE, dd MMMM yyyy').format(_entryDate),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required Function(TimeOfDay) onSelected,
    bool isClearable = false,
  }) {
    return InkWell(
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: const TimePickerThemeData(
                  backgroundColor: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (selected != null) {
          onSelected(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isClearable && time != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _exitTime = null;
                    });
                  },
                )
              : const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textSecondary),
        ),
        child: Text(
          time != null ? time.format(context) : '-',
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildResultChips() {
    final results = ['TP', 'SL', 'Break Even'];
    return Row(
      children: results.map((res) {
        final isSel = _result == res;
        Color selColor = AppColors.neutral;
        Color labelColor = AppColors.textSecondary;
        if (res == 'TP') {
          selColor = AppColors.profit;
          if (isSel) labelColor = AppColors.profit;
        } else if (res == 'SL') {
          selColor = AppColors.loss;
          if (isSel) labelColor = AppColors.loss;
        } else {
          if (isSel) labelColor = AppColors.textPrimary;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Center(child: Text(res.toUpperCase())),
              selected: isSel,
              selectedColor: selColor.withOpacity(0.12),
              labelStyle: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _result = res);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSetupChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.defaultSetups.map((setup) {
        final isSel = _selectedSetups.contains(setup);
        return ChoiceChip(
          label: Text(setup),
          selected: isSel,
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSel ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSetups.add(setup);
              } else {
                _selectedSetups.remove(setup);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildChecklistGrid() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AppConstants.defaultChecklist.length,
      itemBuilder: (context, idx) {
        final item = AppConstants.defaultChecklist[idx];
        final isChecked = _checkedList.contains(item);
        
        return CheckboxListTile(
          title: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          value: isChecked,
          activeColor: AppColors.profit,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _checkedList.add(item);
              } else {
                _checkedList.remove(item);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildImageUploadArea({
    required String label,
    required String? imageUrl,
    required Uint8List? bytes,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasImage = bytes != null || (imageUrl != null && imageUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : imageUrl!.startsWith('data:image/')
                                ? Image.memory(base64Decode(imageUrl.split(',')[1]), fit: BoxFit.cover)
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, color: AppColors.textMuted),
                                    ),
                                  ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 12, color: Colors.white),
                            onPressed: onClear,
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 28),
                        SizedBox(height: 6),
                        Text('Pilih Gambar', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
