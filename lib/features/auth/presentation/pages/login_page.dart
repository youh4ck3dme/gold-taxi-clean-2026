import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: BlocConsumer<AuthCubit, AuthState>(
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
            final isLoading = state is AuthLoading;
            return Stack(
              children: [
                // 1. Abstraktna bodkovana mapa v pozadi
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotGridPainter(),
                  ),
                ),

                // 2. Ambientne zlate svetlo (Aura)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          Color(0x1AC59B47), // Jemna zlata ziasra
                          Colors.transparent,
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Hlavny obsah (Skleneny panel)
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildStaggeredWidget(
                        index: 0,
                        child: _buildGlassCard(context, isLoading),
                      ),
                    ),
                  ),
                ),

                // 4. Top Label "Executive Class"
                Positioned(
                  top: 50,
                  left: 30,
                  child: _buildStaggeredWidget(
                    index: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC59B47),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'EXECUTIVE CLASS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xB3141414), // rgba(20,20,20,0.7)
                Color(0xD9050505), // rgba(5,5,5,0.85)
              ],
            ),
            border: Border.all(
              color: const Color(0x26C59B47), // rgba(197, 155, 71, 0.15)
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 80,
                offset: Offset(0, 40),
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaggeredWidget(index: 1, child: _buildLogoSection()),
                const SizedBox(height: 40),
                _buildStaggeredWidget(index: 2, child: _buildForm(context, isLoading)),
                const SizedBox(height: 24),
                _buildStaggeredWidget(index: 3, child: _buildFooter(context, isLoading)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: GoldMonogramPainter(),
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GOLD',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: Color(0xFFC59B47),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'EXECUTIVE TAXI',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 4.5,
                color: Color(0xFFC59B47),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Column(
      children: [
        GoldTextField(
          controller: _emailController,
          hintText: 'Používateľské meno / E-mail',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Zadajte E-mail';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        GoldTextField(
          controller: _passwordController,
          hintText: 'Heslo',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Zadajte heslo';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC59B47),
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'ZABUDNUTÉ HESLO?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                color: Colors.white54,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GoldButton(
          text: 'PRIHLÁSIŤ SA',
          isLoading: isLoading,
          onPressed: () {
            if (_formKey.currentState!.validate() && !isLoading) {
              context.read<AuthCubit>().login(
                _emailController.text,
                _passwordController.text,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Colors.white24)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ALEBO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2.0,
                  color: Colors.white54,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white24)),
          ],
        ),
        const SizedBox(height: 24),
        GoldOutlineButton(
          text: 'Pokračovať cez Google',
          icon: Icons.g_mobiledata_rounded,
          onPressed: () {
            if (!isLoading) {
              context.read<AuthCubit>().signInWithGoogle();
            }
          },
        ),
        const SizedBox(height: 32),
        _buildInvestorDemoButton(context, isLoading),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nemáte prístup? ',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Požiadať o členstvo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC59B47),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInvestorDemoButton(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC59B47).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC59B47).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'STAKEHOLDER REVIEW',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Color(0xFFC59B47),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isLoading ? null : () => context.read<AuthCubit>().magicLogin(),
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC59B47), size: 18),
            label: const Text(
              'INVESTOR DEMO MODE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredWidget({required int index, required Widget child}) {
    final double start = index * 0.15;
    final double end = start + 0.5;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }
}

class GoldTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const GoldTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  State<GoldTextField> createState() => _GoldTextFieldState();
}

class _GoldTextFieldState extends State<GoldTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _isFocused ? const Color(0x990A0A0A) : const Color(0x66000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? const Color(0x66C59B47) : const Color(0x08FFFFFF),
          width: 1,
        ),
        boxShadow: _isFocused
            ? [const BoxShadow(color: Color(0x0DC59B47), blurRadius: 15, spreadRadius: 2)]
            : [const BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2), blurStyle: BlurStyle.inner)],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? const Color(0xFFC59B47) : Colors.white30,
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: widget.onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isLoading ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: widget.isLoading ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 56, // Fixed height to prevent resizing when loading
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF8A6327), Color(0xFFC59B47), Color(0xFF8A6327)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66C59B47),
                blurRadius: 20,
                offset: Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF050505)),
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    color: Color(0xFF050505),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class GoldOutlineButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const GoldOutlineButton({super.key, required this.text, required this.icon, required this.onPressed});

  @override
  State<GoldOutlineButton> createState() => _GoldOutlineButtonState();
}

class _GoldOutlineButtonState extends State<GoldOutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0x1AFFFFFF) : const Color(0x05FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoldMonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8A6327), Color(0xFFFDF0A6), Color(0xFFC59B47)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.miter;

    // Kreslenie oktagonu (Osem-uholnik)
    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.3, 0);
    path.lineTo(w * 0.7, 0);
    path.lineTo(w, h * 0.3);
    path.lineTo(w, h * 0.7);
    path.lineTo(w * 0.7, h);
    path.lineTo(w * 0.3, h);
    path.lineTo(0, h * 0.7);
    path.lineTo(0, h * 0.3);
    path.close();

    canvas.drawPath(path, paint);

    // Kreslenie pismena 'G' do stredu
    paint.strokeWidth = 3.5;
    paint.strokeCap = StrokeCap.square;

    final gPath = Path();
    gPath.moveTo(w * 0.65, h * 0.35);
    gPath.lineTo(w * 0.40, h * 0.35);
    gPath.lineTo(w * 0.30, h * 0.50);
    gPath.lineTo(w * 0.40, h * 0.65);
    gPath.lineTo(w * 0.60, h * 0.65);
    gPath.lineTo(w * 0.60, h * 0.50);
    gPath.lineTo(w * 0.45, h * 0.50);

    canvas.drawPath(gPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF) // Priesvitna biela pre tichy vzhlad
      ..style = PaintingStyle.fill;

    const double spacing = 16.0;
    const double radius = 1.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Vytvorenie abstraktneho vzoru (niektore body preskocime pre "mapovy" feel)
        if ((x + y) % 3 != 0) {
           canvas.drawCircle(Offset(x, y), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
