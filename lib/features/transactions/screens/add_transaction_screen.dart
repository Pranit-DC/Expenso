// features/transactions/screens/add_transaction_screen.dart
// Cashew-inspired: color-coded header, animated type toggle, sticky save button.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/transaction_model.dart';
import '../../../core/database/models/category_model.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/category_repository.dart';
import '../../../core/utils/constants.dart';

// Cashew accent colors for expense / income
const _expenseColor = Color(0xFFCA5A5A);
const _incomeColor = Color(0xFF59A849);

class AddTransactionScreen extends ConsumerStatefulWidget {
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

  late AnimationController _headerAnimController;
  late Animation<Color?> _headerColorAnim;

  bool get _isEditing => widget.existingTransaction != null;

  Color get _activeColor =>
      _type == TransactionType.expense ? _expenseColor : _incomeColor;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

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

    _headerColorAnim = ColorTween(
      begin: _expenseColor,
      end: _incomeColor,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOutCubic,
    ));

    if (_type == TransactionType.income) {
      _headerAnimController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _setType(TransactionType t) {
    if (t == _type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = t;
      _selectedCategoryId = null;
    });
    if (t == TransactionType.income) {
      _headerAnimController.forward();
    } else {
      _headerAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    final filteredCategories = categories
        .where((c) =>
            c.type ==
                (_type == TransactionType.expense ? 0 : 1) ||
            c.type == 2)
        .toList();

    return Scaffold(
      // ── Sticky bottom save button (Cashew SaveBottomButton) ──
      bottomNavigationBar: _SaveBottomButton(
        isEditing: _isEditing,
        color: _activeColor,
        onSave: _saveTransaction,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Cashew-style color-coded header ──
          AnimatedBuilder(
            animation: _headerColorAnim,
            builder: (_, __) {
              final headerColor =
                  _headerColorAnim.value ?? _expenseColor;
              return SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: headerColor,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                actionsIconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(PhosphorIconsBold.trash,
                          color: Colors.white),
                      onPressed: _deleteTransaction,
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    color: headerColor,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 44),
                            // ── Type toggle inside header ──
                            _TypeToggle(
                              type: _type,
                              onChanged: _setType,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Large amount display (Cashew calculator style) ──
                  AnimatedBuilder(
                    animation: _headerColorAnim,
                    builder: (_, __) {
                      final activeColor =
                          _headerColorAnim.value ?? _expenseColor;
                      return _AmountDisplay(
                        controller: _amountController,
                        activeColor: activeColor,
                        theme: theme,
                        colorScheme: colorScheme,
                      );
                    },
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),

                  // ── Category label ──
                  Text(
                    'Category',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Category grid ──
                  _CategoryGrid(
                    categories: filteredCategories,
                    selectedId: _selectedCategoryId,
                    activeColor: _activeColor,
                    colorScheme: colorScheme,
                    onSelected: (id) =>
                        setState(() => _selectedCategoryId = id),
                  ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
                  const SizedBox(height: 24),

                  // ── Date selector ──
                  _DateSelector(
                    date: _selectedDate,
                    activeColor: _activeColor,
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: _pickDate,
                  ).animate().fadeIn(delay: 90.ms, duration: 300.ms),
                  const SizedBox(height: 12),

                  // ── Note field ──
                  TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(PhosphorIconsRegular.notepad,
                          color: colorScheme.onSurfaceVariant),
                    ),
                    maxLines: 1,
                  ).animate().fadeIn(delay: 120.ms, duration: 300.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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

    HapticFeedback.mediumImpact();
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
        content: const Text(
            'Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(transactionProvider.notifier)
                  .delete(widget.existingTransaction!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: _expenseColor),
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
        backgroundColor: _expenseColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      ),
    );
  }
}

// ── Cashew-style income/expense toggle inside header ──
class _TypeToggle extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _tab('Expense', TransactionType.expense,
              PhosphorIconsFill.arrowUp),
          _tab('Income', TransactionType.income,
              PhosphorIconsFill.arrowDown),
        ],
      ),
    );
  }

  Widget _tab(String label, TransactionType t, IconData icon) {
    final isSelected = type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: Colors.white
                      .withValues(alpha: isSelected ? 1 : 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: Colors.white
                      .withValues(alpha: isSelected ? 1 : 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Large amount display (Cashew calculator feel) ──
class _AmountDisplay extends StatelessWidget {
  final TextEditingController controller;
  final Color activeColor;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _AmountDisplay({
    required this.controller,
    required this.activeColor,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppConstants.currencySymbol,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: activeColor,
              fontSize: 34,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                fontSize: 34,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                ),
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

// ── Category grid ──
class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final Color activeColor;
  final ColorScheme colorScheme;
  final ValueChanged<String> onSelected;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.activeColor,
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
      children: categories.asMap().entries.map((entry) {
        final cat = entry.value;
        final isSelected = cat.id == selectedId;
        final catColor =
            Color(int.parse('FF${cat.colorHex}', radix: 16));

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(cat.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 76,
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.12)
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
                  IconData(cat.iconCodePoint,
                      fontFamily: 'Phosphor-Fill',
                      fontPackage: 'phosphor_flutter'),
                  size: 24,
                  color: isSelected
                      ? catColor
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? catColor
                        : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
            .animate(delay: (entry.key * 30).ms)
            .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 250.ms,
                curve: Curves.easeOutBack);
      }).toList(),
    );
  }
}

// ── Date selector ──
class _DateSelector extends StatelessWidget {
  final DateTime date;
  final Color activeColor;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DateSelector({
    required this.date,
    required this.activeColor,
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
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsFill.calendarBlank,
                color: activeColor, size: 22),
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

// ── Cashew SaveBottomButton — sticky footer ──
class _SaveBottomButton extends StatelessWidget {
  final bool isEditing;
  final Color color;
  final VoidCallback onSave;

  const _SaveBottomButton({
    required this.isEditing,
    required this.color,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: Icon(
              isEditing ? Icons.check_rounded : Icons.add_rounded,
              size: 22,
            ),
            label: Text(
              isEditing ? 'Update Transaction' : 'Save Transaction',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }
}
