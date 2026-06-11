import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with current bloc state if available
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileLoaded) {
      final user = (profileBloc.state as ProfileLoaded).user;
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
            UpdateProfile(
              name: _nameController.text,
              bio: _bioController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ProfileBloc>(),
      child: Builder(
        builder: (context) {
          return BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil úspešne upravený!')),
                );
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Upraviť profil')),
              body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        labelText: 'Celé meno',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Prosím zadajte meno' : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _bioController,
                        labelText: 'O mne (Bio)',
                        maxLines: 4,
                        validator: null,
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          final isUpdating = state is ProfileUpdating;
                          return PrimaryButton(
                            text: isUpdating ? 'Ukladá sa...' : 'Uložiť zmeny',
                            onPressed: isUpdating ? null : () => _save(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
