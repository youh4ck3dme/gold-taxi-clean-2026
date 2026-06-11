import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController roleController = TextEditingController(text: 'customer');

    return Scaffold(
      appBar: AppBar(title: const Text('Registrácia')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pop(context);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Heslo'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Celé meno'),
                  ),
                  TextField(
                    controller: roleController,
                    decoration: const InputDecoration(
                      labelText: 'Rola (customer/driver)',
                      hintText: 'customer',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state is AuthLoading)
                    const CircularProgressIndicator(),
                  if (state is AuthError)
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                            RegisterRequested(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              fullName: fullNameController.text.trim(),
                              role: roleController.text.trim(),
                            ),
                          );
                    },
                    child: const Text('Registrovať sa'),
                  ),
                ].map((widget) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: widget,
                    )).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
