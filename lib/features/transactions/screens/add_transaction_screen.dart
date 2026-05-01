// features/transactions/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/bottom_sheet_helper.dart';
import 'widgets/number_pad.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;
  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late TransactionType _type;
  String _amountStr = '';
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTransaction!;
      _type = t.type;
      _amountStr = t.amount.toStringAsFixed(2);
      if (_amountStr.endsWith('.00')) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 3);
      }
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      _selectedCategoryId = t.categoryId;
    } else {
      _type = TransactionType.expense;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showNumberPad(Color activeColor) {
    BottomSheetHelper.openBottomSheet(
      context: context,
      child: NumberPad(
        activeColor: activeColor,
        onKeyPressed: (key) {
          HapticFeedback.lightImpact();
          if (!mounted) return;
          setState(() {
            if (key == '.' && _amountStr.contains('.')) return;
            if (_amountStr.contains('.')) {
              final parts = _amountStr.split('.');
              if (parts[1].length >= 2) return;
            }
            if (_amountStr == '0' && key != '.') {
              _amountStr = key;
            } else {
              _amountStr += key;
            }
          });
        },
        onBackspace: () {
          HapticFeedback.lightImpact();
          if (!mounted) return;
          setState(() {
            if (_amountStr.isNotEmpty) {
              _amountStr = _amountStr.substring(0, _amountStr.length - 1);
            }
          });
        },
        onClear: () {
          HapticFeedback.heavyImpact();
          if (!mounted) return;
          setState(() => _amountStr = '');
        },
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _showCategoryPickerBottomSheet(List<CategoryModel> categories) {
    BottomSheetHelper.openBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _type == TransactionType.expense
                    ? 'Expense Categories'
                    : 'Income Categories',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (ctx, idx) {
                final cat = categories[idx];
                final catColor = Color(int.parse('FF${cat.colorHex}', radix: 16));
                final isSelected = _selectedCategoryId == cat.id;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(cat.iconCodePoint,
                              fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
                              fontPackage: 'phosphor_flutter'),
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    final filteredCategories = categories
        .where((c) => c.type == (_type == TransactionType.expense ? 0 : 1) || c.type == 2)
        .toList();
    final selectedCategory = filteredCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    final bool hasAmount = _amountStr.isNotEmpty && double.tryParse(_amountStr) != null
            ? double.parse(_amountStr) > 0
            : false;
    final bool canSave = hasAmount && _selectedCategoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Segmented Type Button ──
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  _selectedCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 32),

            // ── Amount Input (Minimal) ──
            InkWell(
              onTap: () => _showNumberPad(colorScheme.primary),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.currencySymbol}${_amountStr.isEmpty ? "0" : _amountStr}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Category Selector ──
            ListTile(
              onTap: () => _showCategoryPickerBottomSheet(filteredCategories),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectedCategory != null
                      ? Color(int.parse('FF${selectedCategory.colorHex}', radix: 16))
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selectedCategory != null
                      ? IconData(selectedCategory.iconCodePoint,
                          fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
                          fontPackage: 'phosphor_flutter')
                      : Icons.category,
                  color: selectedCategory != null
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                selectedCategory?.name ?? 'Select Category',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: selectedCategory != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 16),

            // ── Date Selector ──
            ListTile(
              onTap: _selectDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              leading: const Icon(Icons.calendar_today),
              title: Text(Formatters.dateRelative(_selectedDate)),
              subtitle: Text(DateFormat('EEEE, d MMMM yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 16),

            // ── Note Field ──
            TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 48),

            // ── Save Button ──
            FilledButton.icon(
              onPressed: canSave ? _saveTransaction : null,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Update Transaction' : 'Save Transaction'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amountText = _amountStr.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0 || _selectedCategoryId == null) return;

    HapticFeedback.mediumImpact();
    final transaction = TransactionModel(
      id: _isEditing ? widget.existingTransaction!.id : const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (_isEditing) {
      ref.read(transactionProvider.notifier).update(transaction);
    } else {
      ref.read(transactionProvider.notifier).add(transaction);
    }
    Navigator.of(context).pop();
  }
}
