import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../widgets/sms_verification_dialog.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  final _referredByController = TextEditingController();

  late TextEditingKeyedControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = TextEditingKeyedControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    _referredByController.dispose();
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
      // Capture cubit reference before any async gaps
      final profileCubit = context.read<ProfileCubit>();

      // Check if phone has changed and verify via SMS OTP
      if (normalizedPhone != (state.user.phone ?? '')) {
        await profileCubit.sendPhoneOtp(normalizedPhone);

        if (!context.mounted) return;

        final verified = await SmsVerificationDialog.show(
          context,
          phone: normalizedPhone,
          profileCubit: context.read<ProfileCubit>(),
        );

        if (verified != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Overenie telefónneho čísla zlyhalo.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      final Map<String, dynamic> existingAddresses = Map.from(
        state.user.savedAddresses,
      );

      final Map<String, dynamic> homeMap = existingAddresses['home'] != null
          ? Map<String, dynamic>.from(existingAddresses['home'] as Map)
          : {'label': 'Domov', 'lat': 0.0, 'lng': 0.0};
      homeMap['address'] = _controllers.homeAddress.text.trim();

      final Map<String, dynamic> workMap = existingAddresses['work'] != null
          ? Map<String, dynamic>.from(existingAddresses['work'] as Map)
          : {'label': 'Práca', 'lat': 0.0, 'lng': 0.0};
      workMap['address'] = _controllers.workAddress.text.trim();

      final savedAddresses = {'home': homeMap, 'work': workMap};

      await profileCubit.updateCustomerProfile(
        fullName: _controllers.name.text.trim(),
        phone: normalizedPhone,
        savedAddresses: savedAddresses,
      );

      if (!context.mounted) return;

      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil úspešne uložený')));
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

        return SingleChildScrollView(
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
                      child: Icon(
                        Icons.person,
                        size: 55,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Zákazník',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loyalty Points Card
              Card(
                color: Colors.amber.shade600,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Moje vernostné body',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${state.loyaltyPoints} b.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Referral & Share Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.share, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Odporuč a zarob',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Zdieľaj svoj kód s priateľmi. Ak sa zaregistrujú s tvojím kódom, obaja získate zľavu 5 € na ďalšiu jazdu!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              user.referralCode ?? 'Žiadny kód',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('Zdieľať'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final refCode = user.referralCode;
                              if (refCode != null) {
                                Share.share(
                                  'Zaregistruj sa v Gold-taxi s mojím kódom $refCode a získaj zľavu 5 € na svoju prvú jazdu! Stiahni si aplikáciu tu: https://gold-taxi.sk',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      if (user.referredBy == null) ...[
                        const Divider(height: 32),
                        const Text(
                          'Bol si odporúčaný? Zadaj kód priateľa:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _referredByController,
                                decoration: const InputDecoration(
                                  hintText: 'Napr. JOZO50',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                              onPressed: () async {
                                final code = _referredByController.text.trim();
                                if (code.isEmpty) return;
                                final error = await context
                                    .read<ProfileCubit>()
                                    .applyReferralCode(code);
                                if (!context.mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                } else {
                                  _referredByController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Referenčný kód úspešne uplatnený! Získali ste zľavu 5 €.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Uplatniť'),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Divider(height: 32),
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Referenčný kód bol uplatnený',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account Fields section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_circle_outlined,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Osobné údaje',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.close : Icons.edit,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_isEditing) {
                                  _initializeControllers(state);
                                }
                                _isEditing = !_isEditing;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      if (_isEditing) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _controllers.name,
                                decoration: const InputDecoration(
                                  labelText: 'Celé meno',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Zadajte meno'
                                    : null,
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
                            ],
                          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                          user.savedAddresses['home']?['address'] as String? ??
                              'Nastaviť adresu',
                        ),
                        const SizedBox(height: 16),
                        _buildAddressRow(
                          Icons.work,
                          'Práca',
                          user.savedAddresses['work']?['address'] as String? ??
                              'Nastaviť adresu',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _saveChanges(context, state),
                  child: const Text(
                    'Uložiť zmeny',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (!user.isDriver) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_taxi, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Chcete u nás jazdiť?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Zaregistrujte sa ako vodič, nahrajte potrebné dokumenty a začnite zarábať s Gold-Taxi.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () =>
                              _showDriverRegistrationDialog(context),
                          child: const Text(
                            'Zaregistrovať sa ako vodič',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Orders & Bookings Header
              const Text(
                'Moja aktivita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Orders Section
              _buildActivityCard(
                title: 'Moje objednávky',
                icon: Icons.shopping_bag_outlined,
                itemCount: state.orders.length,
                child: state.orders.isEmpty
                    ? const Text('Žiadne objednávky')
                    : Column(
                        children: state.orders.take(3).map((order) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('Objednávka #${order['id']}'),
                            subtitle: Text(order['status'] ?? 'Neznámy stav'),
                            trailing: Text(
                              '${order['total']} ${order['currency'] ?? "€"}',
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // Bookings Section
              _buildActivityCard(
                title: 'Moje rezervácie',
                icon: Icons.calendar_today_outlined,
                itemCount: state.bookings.length,
                child: state.bookings.isEmpty
                    ? const Text('Žiadne rezervácie')
                    : Column(
                        children: state.bookings.take(3).map((booking) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              booking['title']?['rendered'] ?? 'Rezervácia',
                            ),
                            subtitle: Text(booking['date'] ?? ''),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // Logout button at bottom
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Odhlásiť sa',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () => getIt<AuthCubit>().logout(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String title,
    required IconData icon,
    required int itemCount,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (itemCount > 0)
                  Text(
                    '$itemCount položiek',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
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
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDriverRegistrationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final vehicleTypeController = TextEditingController();
    final vehiclePlateController = TextEditingController();
    List<String> selectedClasses = ['standard'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Registrácia vodiča'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: vehicleTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Značka a model vozidla',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Zadajte model vozidla'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: vehiclePlateController,
                        decoration: const InputDecoration(
                          labelText: 'EČV (ŠPZ) vozidla',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Zadajte ŠPZ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Triedy služieb',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text('Štandard (Standard)'),
                        value: selectedClasses.contains('standard'),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedClasses.add('standard');
                            } else {
                              selectedClasses.remove('standard');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Komfort (Comfort)'),
                        value: selectedClasses.contains('comfort'),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedClasses.add('comfort');
                            } else {
                              selectedClasses.remove('comfort');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Prémiová (Premium)'),
                        value: selectedClasses.contains('premium'),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              selectedClasses.add('premium');
                            } else {
                              selectedClasses.remove('premium');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Zrušiť'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedClasses.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vyberte aspoň jednu triedu služieb'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext);

                      // Call cubit to register
                      await context.read<ProfileCubit>().registerAsDriver(
                        vehicleType: vehicleTypeController.text.trim(),
                        vehiclePlate: vehiclePlateController.text.trim(),
                        serviceClasses: selectedClasses,
                      );
                    }
                  },
                  child: const Text('Registrovať'),
                ),
              ],
            );
          },
        );
      },
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
