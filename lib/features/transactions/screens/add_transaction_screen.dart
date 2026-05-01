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
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/tappable.dart';
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

  void _setType(TransactionType t) {
    if (t == _type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = t;
      _selectedCategoryId = null;
    });
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
            // Limit to 2 decimal places
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
    HapticFeedback.selectionClick();
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
            Text(
              _type == TransactionType.expense
                  ? 'Expense Categories'
                  : 'Income Categories',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (ctx, idx) {
                final cat = categories[idx];
                final catColor =
                    Color(int.parse('FF${cat.colorHex}', radix: 16));
                final isSelected = _selectedCategoryId == cat.id;
                return Tappable(
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor
                              : catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: catColor, width: 2.5)
                              : null,
                        ),
                        child: Icon(
                          IconData(cat.iconCodePoint,
                              fontFamily:
                                  PhosphorIconsFill.shoppingCart.fontFamily,
                              fontPackage: 'phosphor_flutter'),
                          color: isSelected ? Colors.white : catColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
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

  Color _getBaseColor(TransactionType t) {
    if (t == TransactionType.expense) return const Color(0xFFA5601F);
    return const Color(0xFF59A849);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    final filteredCategories = categories
        .where((c) =>
            c.type == (_type == TransactionType.expense ? 0 : 1) ||
            c.type == 2)
        .toList();
    final selectedCategory = filteredCategories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    final headerColor = selectedCategory != null
        ? Color(int.parse('FF${selectedCategory.colorHex}', radix: 16))
        : _getBaseColor(_type);

    final bool hasAmount =
        _amountStr.isNotEmpty && double.tryParse(_amountStr) != null
            ? double.parse(_amountStr) > 0
            : false;
    final bool canSave = hasAmount && _selectedCategoryId != null;
    final String buttonLabel =
        _isEditing ? 'Update Transaction' : 'Save Transaction';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            child: FilledButton(
              onPressed: _saveTransaction,
              style: FilledButton.styleFrom(
                backgroundColor:
                    canSave ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                foregroundColor: canSave
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                buttonLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header (type selector + category icon + amount) ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: headerColor,
              child: Column(
                children: [
                  // Segmented type bar
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        _SegTab(
                          'Expense',
                          PhosphorIconsFill.caretDown,
                          _type == TransactionType.expense,
                          () => _setType(TransactionType.expense),
                        ),
                        _SegTab(
                          'Income',
                          PhosphorIconsFill.caretUp,
                          _type == TransactionType.income,
                          () => _setType(TransactionType.income),
                        ),
                      ],
                    ),
                  ),
                  // Category icon + amount
                  Tappable(
                    onTap: () => _showNumberPad(headerColor),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Row(
                        children: [
                          Tappable(
                            onTap: () => _showCategoryPickerBottomSheet(
                                filteredCategories),
                            child: selectedCategory != null
                                ? Icon(
                                    IconData(
                                      selectedCategory.iconCodePoint,
                                      fontFamily: PhosphorIconsFill
                                          .shoppingCart.fontFamily,
                                      fontPackage: 'phosphor_flutter',
                                    ),
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : const Text('❓',
                                    style: TextStyle(fontSize: 60)),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${AppConstants.currencySymbol}${_amountStr.isEmpty ? "0" : _amountStr}',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Tappable(
                                onTap: () => _showCategoryPickerBottomSheet(
                                    filteredCategories),
                                child: Text(
                                  selectedCategory?.name ?? 'Select Category',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row — fully functional
                  Tappable(
                    onTap: _selectDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.calendarBlank,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Formatters.dateRelative(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy')
                                      .format(_selectedDate),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            PhosphorIconsRegular.caretRight,
                            size: 18,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Note / Title field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            PhosphorIconsRegular.notepad,
                            color: colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
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

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
}

// ── Segmented tab button ──
class _SegTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegTab(this.title, this.icon, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tappable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: isSelected
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
