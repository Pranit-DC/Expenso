// features/transactions/screens/add_transaction_screen.dart
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
import '../../../core/widgets/tappable.dart';
import '../../../core/widgets/bottom_sheet_helper.dart';
import 'widgets/number_pad.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existingTransaction;
  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
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
          setState(() {
            if (key == '.' && _amountStr.contains('.')) return;
            if (_amountStr == '0' && key != '.') {
              _amountStr = key;
            } else {
              _amountStr += key;
            }
          });
        },
        onBackspace: () {
          HapticFeedback.lightImpact();
          setState(() {
            if (_amountStr.isNotEmpty) {
              _amountStr = _amountStr.substring(0, _amountStr.length - 1);
            }
          });
        },
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  void _showCategoryPickerBottomSheet(List<CategoryModel> categories) {
    BottomSheetHelper.openBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cashew Category grid mock (SS 5)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Tappable(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsFill.caretDown, size: 14, color: Color(0xFFCA5A5A)),
                            const SizedBox(width: 6),
                            const Text('Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Tappable(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsFill.caretUp, size: 14, color: Color(0xFF59A849)),
                            const SizedBox(width: 6),
                            const Text('Income', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
              itemCount: categories.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == categories.length) {
                  return Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  );
                }
                final cat = categories[idx];
                final catColor = Color(int.parse('FF${cat.colorHex}', radix: 16));
                return Tappable(
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          IconData(cat.iconCodePoint, fontFamily: PhosphorIconsFill.shoppingCart.fontFamily, fontPackage: 'phosphor_flutter'),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showTypeSelectorSheet() {
    // Replica of SS 1
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Transaction Type',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _TypeCard(
                icon: PhosphorIconsFill.checkCircle,
                title: 'Default',
                bullets: const [],
                isSelected: true,
              ),
              _TypeCard(
                icon: PhosphorIconsRegular.calendarBlank,
                title: 'Upcoming',
                bullets: const [
                  'A transaction that is unpaid',
                  'Does not count towards your total unless marked \'Paid\' or \'Deposited\'',
                ],
              ),
              _TypeCard(
                icon: PhosphorIconsRegular.calendarPlus,
                title: 'Subscription',
                bullets: const [
                  'Recurring transaction that will be shown on the subscriptions page',
                  'Does not count towards your total unless marked \'Paid\' or \'Deposited\'',
                  'Next transaction generated when current marked \'Paid\' or \'Deposited\'',
                ],
              ),
              _TypeCard(
                icon: PhosphorIconsRegular.arrowsLeftRight,
                title: 'Repetitive',
                bullets: const [
                  'Recurring transaction',
                  'Does not count towards your total unless marked \'Paid\' or \'Deposited\'',
                  'Next transaction generated when current marked \'Paid\' or \'Deposited\'',
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Color _getBaseColor(TransactionType t) {
    if (t == TransactionType.expense) return const Color(0xFFA5601F); // Cashew orange/brown from SS
    return const Color(0xFF59A849);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ref.watch(categoryProvider);

    final filteredCategories = categories.where((c) =>
        c.type == (_type == TransactionType.expense ? 0 : 1) || c.type == 2).toList();
    final selectedCategory = filteredCategories.where((c) => c.id == _selectedCategoryId).firstOrNull;

    final headerColor = selectedCategory != null
        ? Color(int.parse('FF${selectedCategory.colorHex}', radix: 16))
        : _getBaseColor(_type);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
             onPressed: _saveTransaction,
             style: FilledButton.styleFrom(
               backgroundColor: const Color(0xFF88A2D8), // Light purple from SS
               foregroundColor: Colors.black87,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               minimumSize: const Size(double.infinity, 56),
             ),
             child: const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Head Section (SS 2 & SS 3 segment control)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: headerColor,
              child: Column(
                children: [
                  // Segmented Bar area (darker background of headerColor)
                  Container(
                    color: Colors.black.withValues(alpha: 0.2), 
                    child: Row(
                      children: [
                        _SegTab('Expense', PhosphorIconsFill.caretDown, _type == TransactionType.expense, () => _setType(TransactionType.expense)),
                        _SegTab('Income', PhosphorIconsFill.caretUp, _type == TransactionType.income, () => _setType(TransactionType.income)),
                      ],
                    ),
                  ),
                  // Emoji + Amount Header
                  Tappable(
                    onTap: () => _showNumberPad(headerColor),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Row(
                        children: [
                          Tappable(
                            onTap: () => _showCategoryPickerBottomSheet(filteredCategories),
                            child: selectedCategory != null 
                              ? Icon(
                                  IconData(selectedCategory.iconCodePoint, fontFamily: PhosphorIconsFill.shoppingCart.fontFamily, fontPackage: 'phosphor_flutter'),
                                  size: 60, color: Colors.white)
                              : const Text('❓', style: TextStyle(fontSize: 60)),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${AppConstants.currencySymbol}${_amountStr.isEmpty ? "0" : _amountStr}',
                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Tappable(
                                onTap: () => _showCategoryPickerBottomSheet(filteredCategories),
                                child: Text(
                                  selectedCategory?.name ?? 'Select Category',
                                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Below Header Body (Chips and inputs)
            Padding(
               padding: const EdgeInsets.symmetric(vertical: 24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    // DATE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                             child: const Icon(PhosphorIconsRegular.calendarBlank, size: 24),
                           ),
                           const SizedBox(width: 12),
                           const Text('Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                           const Spacer(),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                             decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                             child: const Text('1 : 24', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           )
                         ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TYPES Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                           Tappable(
                             onTap: _showTypeSelectorSheet,
                             borderRadius: BorderRadius.circular(12),
                             child: Container(
                               padding: const EdgeInsets.all(10),
                               decoration: BoxDecoration(
                                 border: Border.all(color: colorScheme.outlineVariant),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: const Icon(PhosphorIconsRegular.info, size: 20),
                             ),
                           ),
                           const SizedBox(width: 8),
                           _Chip(label: 'Default', isSelected: true, onTap: _showTypeSelectorSheet),
                           _Chip(label: 'Upcoming'),
                           _Chip(label: 'Subscription'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Wallets Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                           _Chip(label: 'UPI', isSelected: false, isMint: true),
                           _Chip(label: 'Cash'),
                           _Chip(label: 'Stash'),
                           _Chip(label: '+', isIcon: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Budgets Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                           _Chip(label: 'No budget', isSelected: true),
                           _Chip(label: 'Budget'),
                           _Chip(label: '+', isIcon: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Goals Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                           _Chip(label: 'No goal', isSelected: true),
                           _Chip(label: 'Oneplus Nord 4 accessories'),
                           _Chip(label: '+', isIcon: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          suffixIcon: const Padding(
                             padding: EdgeInsets.all(12.0),
                             child: Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                          ),
                        ),
                      ),
                    )
                 ],
               ),
            )
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amountText = _amountStr.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter amount!')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category!')));
      return;
    }

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

class _SegTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _SegTab(this.title, this.icon, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: isSelected ? Colors.black.withValues(alpha: 0.15) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isMint;
  final bool isIcon;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.isSelected = false, this.isMint = false, this.isIcon = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tappable(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isIcon ? 14 : 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isMint ? const Color(0xFF63BA9E) : Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  final bool isSelected;
  const _TypeCard({required this.icon, required this.title, required this.bullets, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(icon, color: Colors.white, size: 24),
               const SizedBox(width: 12),
               Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (bullets.isNotEmpty) const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Padding(
                   padding: EdgeInsets.only(top: 6.0, right: 8.0),
                   child: CircleAvatar(radius: 2, backgroundColor: Colors.white70),
                 ),
                 Expanded(child: Text(b, style: const TextStyle(color: Colors.white70, height: 1.4))),
              ],
            ),
          ))
        ],
      ),
    );
  }
}
