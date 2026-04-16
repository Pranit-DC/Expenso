// features/transactions/screens/add_transaction_screen.dart
// Full-featured screen for adding or editing a transaction.

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
import '../../../core/utils/constants.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// Pass an existing transaction to edit, or null to create new.
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TransactionType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    if (_isEditing) {
      final t = widget.existingTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toStringAsFixed(2);
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
    _amountController.dispose();
    _noteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    // Filter categories by current transaction type
    final filteredCategories = categories
        .where(
            (c) => c.type == (_type == TransactionType.expense ? 0 : 1) || c.type == 2)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(PhosphorIconsBold.trash, color: colorScheme.error),
              onPressed: _deleteTransaction,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Type Toggle ──
              _TypeToggle(
                type: _type,
                colorScheme: colorScheme,
                onChanged: (t) => setState(() {
                  _type = t;
                  _selectedCategoryId = null;
                }),
              ),
              const SizedBox(height: 24),

              // ── Amount Input ──
              _AmountField(
                controller: _amountController,
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 24),

              // ── Category Selector ──
              Text(
                'Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _CategoryGrid(
                categories: filteredCategories,
                selectedId: _selectedCategoryId,
                colorScheme: colorScheme,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: 24),

              // ── Date Picker ──
              _DateSelector(
                date: _selectedDate,
                colorScheme: colorScheme,
                theme: theme,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // ── Note Input ──
              TextField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  prefixIcon: Icon(PhosphorIconsRegular.notepad,
                      color: colorScheme.onSurfaceVariant),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 32),

              // ── Save Button ──
              FilledButton.icon(
                onPressed: _saveTransaction,
                icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
                label: Text(
                  _isEditing ? 'Update Transaction' : 'Save Transaction',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: _type == TransactionType.income
                      ? Colors.green.shade600
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveTransaction() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    final transaction = TransactionModel(
      id: _isEditing ? widget.existingTransaction!.id : const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (_isEditing) {
      ref.read(transactionProvider.notifier).update(transaction);
    } else {
      ref.read(transactionProvider.notifier).add(transaction);
    }

    Navigator.of(context).pop();
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref
                  .read(transactionProvider.notifier)
                  .delete(widget.existingTransaction!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Sub-Widgets
// ══════════════════════════════════════════════════

/// Income / Expense toggle.
class _TypeToggle extends StatelessWidget {
  final TransactionType type;
  final ColorScheme colorScheme;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({
    required this.type,
    required this.colorScheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleButton(
            label: 'Expense',
            icon: PhosphorIconsFill.arrowUp,
            isSelected: type == TransactionType.expense,
            color: Colors.red.shade400,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _toggleButton(
            label: 'Income',
            icon: PhosphorIconsFill.arrowDown,
            isSelected: type == TransactionType.income,
            color: Colors.green.shade400,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : colorScheme.outline),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large amount input with currency symbol.
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _AmountField({
    required this.controller,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            AppConstants.currencySymbol,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category selection grid.
class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ColorScheme colorScheme;
  final ValueChanged<String> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.colorScheme,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No categories available',
          style: TextStyle(color: colorScheme.outline),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedId;
        final catColor = Color(int.parse('FF${cat.colorHex}', radix: 16));

        return GestureDetector(
          onTap: () => onSelected(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? catColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconData(cat.iconCodePoint, fontFamily: 'Phosphor-Fill', fontPackage: 'phosphor_flutter'),
                  size: 24,
                  color: isSelected ? catColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? catColor : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Date selector tile.
class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DateSelector({
    required this.date,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final isToday = today == selected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsFill.calendarBlank,
                color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              isToday ? 'Today' : DateFormat('EEE, d MMM yyyy').format(date),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(PhosphorIconsRegular.caretRight,
                color: colorScheme.outline, size: 20),
          ],
        ),
      ),
    );
  }
}
