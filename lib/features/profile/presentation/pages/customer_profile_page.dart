import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late TextEditingKeyedControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = TextEditingKeyedControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _initializeControllers(ProfileLoaded state) {
    _controllers.name.text = state.user.name;
    _controllers.phone.text = state.user.phone ?? '';
    
    final saved = state.user.savedAddresses;
    _controllers.homeAddress.text = saved['home']?['address'] as String? ?? '';
    _controllers.workAddress.text = saved['work']?['address'] as String? ?? '';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zadajte telefónne číslo';
    }
    // Remove spaces and hyphens
    final normalized = value.replaceAll(RegExp(r'[\s\-]'), '');
    // Regex matching: +421XXXXXXXXX, 421XXXXXXXXX, or local 09XXXXXXXX
    final phoneRegex = RegExp(r'^(\+421\d{9}|421\d{9}|09\d{8})$');
    if (!phoneRegex.hasMatch(normalized)) {
      return 'Neplatný formát (napr. +421 901 234 567 alebo 0901 234 567)';
    }
    return null;
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-]'), '');
  }

  void _saveChanges(BuildContext context, ProfileLoaded state) async {
    if (_formKey.currentState!.validate()) {
      final normalizedPhone = _normalizePhone(_controllers.phone.text);
      
      final Map<String, dynamic> existingAddresses = Map.from(state.user.savedAddresses);
      
      final Map<String, dynamic> homeMap = existingAddresses['home'] != null
          ? Map<String, dynamic>.from(existingAddresses['home'] as Map)
          : {'label': 'Domov', 'lat': 0.0, 'lng': 0.0};
      homeMap['address'] = _controllers.homeAddress.text.trim();

      final Map<String, dynamic> workMap = existingAddresses['work'] != null
          ? Map<String, dynamic>.from(existingAddresses['work'] as Map)
          : {'label': 'Práca', 'lat': 0.0, 'lng': 0.0};
      workMap['address'] = _controllers.workAddress.text.trim();

      final savedAddresses = {
        'home': homeMap,
        'work': workMap,
      };

      await context.read<ProfileCubit>().updateCustomerProfile(
            fullName: _controllers.name.text.trim(),
            phone: normalizedPhone,
            savedAddresses: savedAddresses,
          );
      
      if (!context.mounted) return;
      
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil úspešne uložený')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_isEditing) {
          _initializeControllers(state);
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Môj Profil'),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      _initializeControllers(state);
                    }
                    _isEditing = !_isEditing;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () => getIt<AuthCubit>().logout(),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Avatar and Name display
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.amber.shade100,
                          child: Icon(Icons.person, size: 55, color: Colors.amber.shade900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            'Zákazník',
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Fields section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_circle_outlined, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'Osobné údaje',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (_isEditing) ...[
                            TextFormField(
                              controller: _controllers.name,
                              decoration: const InputDecoration(
                                labelText: 'Celé meno',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Zadajte meno' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _controllers.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefónne číslo',
                                prefixIcon: Icon(Icons.phone),
                                hintText: '+421 / 09...',
                              ),
                              validator: _validatePhone,
                            ),
                          ] else ...[
                            _buildInfoRow('Celé meno', user.name),
                            const SizedBox(height: 16),
                            _buildInfoRow('Telefón', user.phone ?? 'Neuvedené'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saved Addresses section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bookmark_outline, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'Uložené adresy',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (_isEditing) ...[
                            TextFormField(
                              controller: _controllers.homeAddress,
                              decoration: const InputDecoration(
                                labelText: 'Adresa Domov',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _controllers.workAddress,
                              decoration: const InputDecoration(
                                labelText: 'Adresa Práca',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                            ),
                          ] else ...[
                            _buildAddressRow(
                              Icons.home,
                              'Domov',
                              user.savedAddresses['home']?['address'] as String? ?? 'Nastaviť adresu',
                            ),
                            const SizedBox(height: 16),
                            _buildAddressRow(
                              Icons.work,
                              'Práca',
                              user.savedAddresses['work']?['address'] as String? ?? 'Nastaviť adresu',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _saveChanges(context, state),
                      child: const Text('Uložiť zmeny', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String address) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(address, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class TextEditingKeyedControllers {
  final name = TextEditingController();
  final phone = TextEditingController();
  final homeAddress = TextEditingController();
  final workAddress = TextEditingController();

  void dispose() {
    name.dispose();
    phone.dispose();
    homeAddress.dispose();
    workAddress.dispose();
  }
}
