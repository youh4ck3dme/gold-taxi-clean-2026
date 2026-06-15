import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/fields/app_text_field.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Prihlásenie',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/earth.webp'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.45),
                BlendMode.darken,
              ),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ), // transparent white liquid glass
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.25,
                          ), // shiny glass border
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: BlocConsumer<AuthCubit, AuthState>(
                        listener: (context, state) {
                          if (state is AuthError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          return Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Vitajte v Gold-Taxi',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // White text for better contrast on glass
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(0, 1.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                AppTextField(
                                  controller: _usernameController,
                                  labelText: 'Používateľské meno / E-mail',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: AppColors.grey700,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.grey800,
                                    fontSize: 16,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Zadajte meno';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _passwordController,
                                  labelText: 'Heslo',
                                  obscureText: true,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.grey700,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.grey800,
                                    fontSize: 16,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Zadajte heslo';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  text: 'Prihlásiť sa',
                                  isLoading: state is AuthLoading,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().login(
                                        _usernameController.text,
                                        _passwordController.text,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    icon: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: AppColors.grey800,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    label: const Text(
                                      'Pokračovať cez Google',
                                      style: TextStyle(
                                        color: AppColors.grey800,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: AppColors.grey200,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: state is AuthLoading
                                        ? null
                                        : () {
                                            context
                                                .read<AuthCubit>()
                                                .signInWithGoogle();
                                          },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
