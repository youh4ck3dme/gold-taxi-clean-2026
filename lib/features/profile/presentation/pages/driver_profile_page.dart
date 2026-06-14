import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  
  List<String> _selectedServiceClasses = [];
  bool _isOnline = false;

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  void _initializeFields(ProfileLoaded state) {
    final record = state.driverRecord ?? const {};
    _vehicleTypeController.text = record['vehicle_type'] as String? ?? '';
    _vehiclePlateController.text = record['vehicle_plate'] as String? ?? '';
    _selectedServiceClasses = List<String>.from(record['service_classes'] ?? ['standard']);
    _isOnline = record['is_online'] as bool? ?? false;
  }

  void _saveChanges(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vyberte aspoň jednu triedu služieb'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await context.read<ProfileCubit>().updateDriverProfile(
            vehicleType: _vehicleTypeController.text.trim(),
            vehiclePlate: _vehiclePlateController.text.trim(),
            serviceClasses: _selectedServiceClasses,
            isOnline: _isOnline,
          );
      
      if (!context.mounted) return;
      
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil vodiča bol úspešne uložený')),
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
          _initializeFields(state);
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Vodiča'),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      _initializeFields(state);
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
                  // Driver header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.local_taxi, size: 55, color: Colors.green.shade900),
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
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Vodič',
                            style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Online / Offline Status Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prevádzkový stav',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isOnline ? 'Ste online a prijímate jazdy' : 'Ste offline',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _isOnline,
                            activeTrackColor: Colors.green,
                            onChanged: (val) {
                              setState(() {
                                _isOnline = val;
                              });
                              // Save state instantly to backend as well to match drivers flow
                              context.read<ProfileCubit>().updateDriverProfile(
                                    vehicleType: _vehicleTypeController.text.trim(),
                                    vehiclePlate: _vehiclePlateController.text.trim(),
                                    serviceClasses: _selectedServiceClasses,
                                    isOnline: val,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Details Card
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
                              Icon(Icons.directions_car_filled_outlined, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Údaje o vozidle',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (_isEditing) ...[
                            TextFormField(
                              controller: _vehicleTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Typ vozidla (značka / model)',
                                prefixIcon: Icon(Icons.car_repair),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Zadajte model vozidla' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vehiclePlateController,
                              decoration: const InputDecoration(
                                labelText: 'EČV vozidla (ŠPZ)',
                                prefixIcon: Icon(Icons.pin),
                                hintText: 'napr. KE-123AB',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Zadajte ŠPZ vozidla' : null,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Triedy služieb',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            _buildServiceCheckbox('standard', 'Štandard (Standard)'),
                            _buildServiceCheckbox('comfort', 'Komfort (Comfort)'),
                            _buildServiceCheckbox('premium', 'Prémiová (Premium)'),
                          ] else ...[
                            _buildInfoRow('Model vozidla', _vehicleTypeController.text.isNotEmpty ? _vehicleTypeController.text : 'Neuvedené'),
                            const SizedBox(height: 16),
                            _buildInfoRow('EČV (ŠPZ)', _vehiclePlateController.text.isNotEmpty ? _vehiclePlateController.text : 'Neuvedené'),
                            const SizedBox(height: 16),
                            _buildServiceClassesRow(_selectedServiceClasses),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _saveChanges(context),
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

  Widget _buildServiceCheckbox(String code, String label) {
    final isSelected = _selectedServiceClasses.contains(code);
    return CheckboxListTile(
      value: isSelected,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedServiceClasses.add(code);
          } else {
            _selectedServiceClasses.remove(code);
          }
        });
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

  Widget _buildServiceClassesRow(List<String> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Triedy služieb', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: classes.map((c) {
            String label = c.toUpperCase();
            Color color = Colors.blue;
            if (c == 'standard') {
              label = 'ŠTANDARD';
              color = Colors.grey;
            } else if (c == 'comfort') {
              label = 'KOMFORT';
              color = Colors.amber;
            } else if (c == 'premium') {
              label = 'PREMIUM';
              color = Colors.deepPurple;
            }
            return Chip(
              label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}
