import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/expense_request.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../presentation/viewModels/accounts_viewmodel.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/date_range_dialog.dart';

/// Society expenses — the list, plus the form to add one.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref
      .read(accountsViewModelProvider.notifier)
      .loadExpenses(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _refresh);
  }

  Future<void> _openForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExpenseForm(),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('It will be removed from the books.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(accountsViewModelProvider.notifier).deleteExpense(id);
  }

  @override
  Widget build(BuildContext context) {
    listenForFeedback(ref, context, accountsViewModelProvider);

    final rows = ref
        .watch(accountsViewModelProvider)
        .rows(AccountsKeys.expenses);

    return Scaffold(
      appBar: AppBar(title: const Text('Society expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hint: 'Search expenses',
              ),
            ),
            Expanded(
              child: RowsView(
                rows: rows,
                onRefresh: _refresh,
                emptyIcon: Icons.payments_outlined,
                emptyTitle: 'No expenses recorded',
                builder: (items) => ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _buildExpense(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpense(Map<String, dynamic> row) {
    final id = pickInt(row, ['expense_id', 'id']);
    final name = pick(row, ['ex_name', 'name', 'expense_name']);
    final type = pick(row, ['ex_type', 'expense_type', 'type']);
    final invoice = pick(row, ['invoice_no', 'invoice', 'voucher_no']);

    return AppCard(
      onTap: id == null ? null : () => _confirmDelete(id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Expense',
                      style: AppTheme.title.copyWith(fontSize: 15),
                    ),
                    if (type != null) ...[
                      const SizedBox(height: 2),
                      Text(type, style: AppTheme.caption),
                    ],
                  ],
                ),
              ),
              Text(
                money(row['f_amount'] ?? row['final_amount'] ?? row['amount']),
                style: AppTheme.title.copyWith(
                  fontSize: 15,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(prettyDate(row['date']), style: AppTheme.caption),
              if (invoice != null) ...[
                const SizedBox(width: 12),
                Text('#$invoice', style: AppTheme.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The add-expense form.
///
/// `finalAmount` is what the society actually pays. The server stores amount,
/// tax and TDS separately and does not recompute the final figure, so it is
/// derived here as the secretary types and remains editable.
class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm();

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _tdsController = TextEditingController();
  final _finalController = TextEditingController();
  final _detailsController = TextEditingController();

  DateTime _date = DateTime.now();

  /// True until the secretary edits the final amount by hand, after which the
  /// derived value stops overwriting what they typed.
  bool _finalIsDerived = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_amountController, _taxController, _tdsController]) {
      c.addListener(_recalculate);
    }
    _finalController.addListener(() {
      // Only a real edit counts; _recalculate writes through the same field.
      if (!_writingDerived) _finalIsDerived = false;
    });
  }

  bool _writingDerived = false;

  void _recalculate() {
    if (!_finalIsDerived) return;
    final total =
        _num(_amountController) + _num(_taxController) - _num(_tdsController);

    _writingDerived = true;
    _finalController.text = total <= 0 ? '' : total.toStringAsFixed(2);
    _writingDerived = false;
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _typeController,
      _amountController,
      _taxController,
      _tdsController,
      _finalController,
      _detailsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(accountsViewModelProvider.notifier)
        .createExpense(
          ExpenseRequest(
            name: _nameController.text.trim(),
            expenseType: _typeController.text.trim().isEmpty
                ? null
                : _typeController.text.trim(),
            amount: _num(_amountController),
            tax: _num(_taxController),
            tds: _num(_tdsController),
            finalAmount: _num(_finalController),
            details: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
            date:
                '${_date.year.toString().padLeft(4, '0')}-'
                '${_date.month.toString().padLeft(2, '0')}-'
                '${_date.day.toString().padLeft(2, '0')}',
          ),
        );

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsViewModelProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Text('Add expense', style: AppTheme.headline),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Expense name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (optional)',
                  hintText: 'Repairs, Security, Utilities…',
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showSingleDateDialog(
                    context: context,
                    initial: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(prettyDate(_date), style: AppTheme.body2),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  final amount = double.tryParse((v ?? '').trim());
                  if (amount == null || amount < 0) return 'Enter the amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tax',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tdsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'TDS',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _finalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Final amount payable',
                  prefixText: '₹ ',
                  helperText: 'Amount + tax − TDS. Edit if it differs.',
                ),
                validator: (v) {
                  final amount = double.tryParse((v ?? '').trim());
                  if (amount == null || amount < 0) {
                    return 'Enter the final amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Save expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
