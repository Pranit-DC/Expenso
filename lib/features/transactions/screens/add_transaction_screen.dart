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
import '../../../core/database/repositories/budget_repository.dart';
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
              itemCount: categories.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == categories.length) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCategorySheet();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add New',
                          style: TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final cat = categories[idx];
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
                              ? Theme.of(context).colorScheme.primary
                              : Color(int.parse('FF${cat.colorHex}', radix: 16)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(cat.iconCodePoint,
                              fontFamily: PhosphorIconsFill.shoppingCart.fontFamily,
                              fontPackage: 'phosphor_flutter'),
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Color(int.parse('FF${cat.colorHex}', radix: 16)),
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

  void _showAddCategorySheet() {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    BottomSheetHelper.openBottomSheet(
      context: context,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Custom Category',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Subscriptions',
                prefixIcon: Icon(Icons.label_outline),
              ),
              onSubmitted: (_) => _createCategory(controller.text.trim()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _createCategory(controller.text.trim()),
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _createCategory(String name) {
    if (name.isEmpty) return;

    final newCat = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      iconCodePoint: PhosphorIconsFill.tag.codePoint,
      colorHex: Theme.of(context).colorScheme.primary.toARGB32().toRadixString(16).substring(2).toUpperCase(),
      type: _type == TransactionType.expense ? 0 : 1,
      isDefault: false,
    );

    ref.read(categoryProvider.notifier).add(newCat);
    setState(() => _selectedCategoryId = newCat.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);
    final budget = ref.watch(budgetProvider);
    final transactions = ref.watch(transactionProvider);

    final filteredCategories = categories
        .where((c) => c.type == (_type == TransactionType.expense ? 0 : 1) || c.type == 2)
        .toList();
    final selectedCategory = filteredCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    final now = DateTime.now();
    final monthSpent = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.id != widget.existingTransaction?.id)
        .fold(0.0, (s, t) => s + t.amount);

    final currentInput = double.tryParse(_amountStr) ?? 0.0;
    final bool hasAmount = _amountStr.isNotEmpty && currentInput > 0;
    final bool canSave = hasAmount && _selectedCategoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Note Field (Moved Up) ──
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
            const SizedBox(height: 32),

            // ── Amount Input ──
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
            const SizedBox(height: 24),

            // ── Budget Impact (Non-interactive, moved up for reachability) ──
            _BudgetImpact(
              limit: budget.monthlyLimit,
              spent: monthSpent,
              currentInput: currentInput,
              isExpense: _type == TransactionType.expense,
            ),

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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton.icon(
            onPressed: canSave ? _saveTransaction : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(_isEditing ? 'Update Transaction' : 'Save Transaction'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
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

class _BudgetImpact extends StatelessWidget {
  final double limit;
  final double spent;
  final double currentInput;
  final bool isExpense;

  const _BudgetImpact({
    required this.limit,
    required this.spent,
    required this.currentInput,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (limit <= 0 || !isExpense) return const SizedBox.shrink();

    final totalNew = spent + currentInput;
    final progress = (totalNew / limit).clamp(0.0, 1.0);
    final isOver = totalNew > limit;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isOver
        ? colorScheme.error
        : (progress > 0.8 ? Colors.orange : colorScheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOver ? PhosphorIconsFill.warning : PhosphorIconsFill.chartPieSlice,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOver ? 'Budget Exceeded' : 'Monthly Budget Impact',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isOver ? colorScheme.error : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isOver 
                        ? 'Over by ${Formatters.currencyCompact(totalNew - limit)}'
                        : '${Formatters.currencyCompact(limit - totalNew)} remaining',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currencyCompact(totalNew),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% of limit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
