import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/services/api_service.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import '../cubits/cart_cubit.dart';
import '../cubits/cart_state.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  String _paymentMethod = 'cod'; // default COD (cash on delivery)
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartLoaded cartState) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = getIt<ApiService>();

      // WooCommerce API order format
      final orderData = {
        'payment_method': _paymentMethod,
        'payment_method_title': _paymentMethod == 'cod' ? 'Na dobierku' : 'Kartou online',
        'set_paid': false,
        'billing': {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'address_1': _addressController.text,
          'city': _cityController.text,
          'postcode': _zipController.text,
          'country': 'SK',
          'email': _emailController.text,
          'phone': _phoneController.text,
        },
        'shipping': {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'address_1': _addressController.text,
          'city': _cityController.text,
          'postcode': _zipController.text,
          'country': 'SK',
        },
        'line_items': cartState.items.map((item) {
          return {
            'product_id': item.product.id,
            'quantity': item.quantity,
          };
        }).toList(),
      };

      final cartCubit = context.read<CartCubit>();

      final response = await apiService.post(
        '/wp-json/wc/v3/orders',
        data: orderData,
      );

      final orderId = response['id'].toString();

      // Clear local cart
      await cartCubit.clearCart();
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      context.go('/order-confirmation', extra: orderId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri odosielaní objednávky: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokladňa')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const Center(child: Text('Nemáte žiadne položky v košíku.'));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontaktné údaje',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _firstNameController,
                          labelText: 'Meno',
                          validator: (v) => v == null || v.isEmpty ? 'Meno je povinné' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _lastNameController,
                          labelText: 'Priezvisko',
                          validator: (v) => v == null || v.isEmpty ? 'Priezvisko je povinné' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailController,
                    labelText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'E-mail je povinný' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneController,
                    labelText: 'Telefón',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Telefón je povinný' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Doručovacia adresa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _addressController,
                    labelText: 'Ulica a číslo domu',
                    validator: (v) => v == null || v.isEmpty ? 'Ulica je povinná' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: _cityController,
                          labelText: 'Mesto',
                          validator: (v) => v == null || v.isEmpty ? 'Mesto je povinné' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: AppTextField(
                          controller: _zipController,
                          labelText: 'PSČ',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'PSČ je povinné' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Spôsob platby',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                    child: const Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Dobierka (platba pri prevzatí)'),
                          value: 'cod',
                        ),
                        RadioListTile<String>(
                          title: Text('Platobná karta (online)'),
                          value: 'stripe',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Celková suma:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${state.total.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: _isSubmitting ? 'Odosiela sa...' : 'Záväzne objednať',
                    onPressed: _isSubmitting ? null : () => _submitOrder(state),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
