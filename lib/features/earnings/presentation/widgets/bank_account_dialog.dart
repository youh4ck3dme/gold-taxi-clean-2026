import 'package:flutter/material.dart';
import '../../data/models/bank_account_model.dart';

class BankAccountDialog extends StatefulWidget {
  final String driverId;
  final BankAccountModel? initialAccount;
  final Function(BankAccountModel) onSave;

  const BankAccountDialog({
    super.key,
    required this.driverId,
    this.initialAccount,
    required this.onSave,
  });

  @override
  State<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stripeAccountController;
  late TextEditingController _bankNameController;
  late TextEditingController _holderNameController;
  late TextEditingController _last4Controller;
  String _holderType = 'individual';
  String _currency = 'eur';

  @override
  void initState() {
    super.initState();
    _stripeAccountController = TextEditingController(text: widget.initialAccount?.stripeAccountId ?? '');
    _bankNameController = TextEditingController(text: widget.initialAccount?.bankName ?? '');
    _holderNameController = TextEditingController(text: widget.initialAccount?.accountHolderName ?? '');
    _last4Controller = TextEditingController(text: widget.initialAccount?.bankAccountLast4 ?? '');
    _holderType = widget.initialAccount?.accountHolderType ?? 'individual';
    _currency = widget.initialAccount?.currency ?? 'eur';
  }

  @override
  void dispose() {
    _stripeAccountController.dispose();
    _bankNameController.dispose();
    _holderNameController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialAccount == null ? 'Pridať Bankový Účet' : 'Upraviť Bankový Účet',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nastavenie účtu pre Stripe Connect a prevody zárobkov.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              
              // Stripe Account ID
              TextFormField(
                controller: _stripeAccountController,
                decoration: InputDecoration(
                  labelText: 'Stripe Account ID',
                  hintText: 'Napr. acct_1234567890',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zadajte Stripe Account ID';
                  }
                  if (!value.startsWith('acct_')) {
                    return 'Stripe Account ID musí začínať s "acct_"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Bank Name
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Názov banky',
                  hintText: 'Napr. Tatra Banka, a.s.',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Zadajte názov banky' : null,
              ),
              const SizedBox(height: 12),

              // Holder Name
              TextFormField(
                controller: _holderNameController,
                decoration: InputDecoration(
                  labelText: 'Meno majiteľa účtu',
                  hintText: 'Meno a priezvisko',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Zadajte meno majiteľa' : null,
              ),
              const SizedBox(height: 12),

              // Last 4 Digits
              TextFormField(
                controller: _last4Controller,
                decoration: InputDecoration(
                  labelText: 'Posledné 4 číslice účtu / IBANu',
                  hintText: 'Napr. 8899',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zadajte 4 číslice';
                  }
                  if (value.length != 4 || double.tryParse(value) == null) {
                    return 'Zadajte presne 4 čísla';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Account Holder Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _holderType,
                decoration: InputDecoration(
                  labelText: 'Typ účtu',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'individual', child: Text('Fyzická osoba (Individual)')),
                  DropdownMenuItem(value: 'company', child: Text('Právnická osoba (Company)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _holderType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Currency Dropdown
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: 'Mena',
                  prefixIcon: const Icon(Icons.euro),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'eur', child: Text('Euro (EUR)')),
                  DropdownMenuItem(value: 'usd', child: Text('Dolar (USD)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currency = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zrušiť'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newAccount = BankAccountModel(
                id: widget.initialAccount?.id ?? '',
                driverId: widget.driverId,
                stripeAccountId: _stripeAccountController.text.trim(),
                bankName: _bankNameController.text.trim(),
                accountHolderName: _holderNameController.text.trim(),
                bankAccountLast4: _last4Controller.text.trim(),
                accountHolderType: _holderType,
                currency: _currency,
                status: widget.initialAccount?.status ?? 'verified', // Mock as verified on save
                payoutEnabled: widget.initialAccount?.payoutEnabled ?? true,
              );
              widget.onSave(newAccount);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Uložiť'),
        ),
      ],
    );
  }
}
