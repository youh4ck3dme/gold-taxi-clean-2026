import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_cubit.dart';

class SmsVerificationDialog extends StatefulWidget {
  final String phone;

  const SmsVerificationDialog({super.key, required this.phone});

  static Future<bool?> show(
    BuildContext context, {
    required String phone,
    required ProfileCubit profileCubit,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider.value(
        value: profileCubit,
        child: SmsVerificationDialog(phone: phone),
      ),
    );
  }

  @override
  State<SmsVerificationDialog> createState() => _SmsVerificationDialogState();
}

class _SmsVerificationDialogState extends State<SmsVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimer = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer -= 1);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resendCode() async {
    _startTimer();
    setState(() {
      _errorMessage = null;
    });
    // Trigger OTP sending
    await context.read<ProfileCubit>().sendPhoneOtp(widget.phone);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overovací kód bol znova odoslaný.')),
      );
    }
  }

  void _verifyCode() async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Zadajte kompletný 6-miestny kód';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<ProfileCubit>().verifyPhoneOtp(
      widget.phone,
      code,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Neplatný overovací kód. Skúste to znova.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.sms_outlined, size: 48, color: Colors.amber),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Overenie čísla',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Zadajte 6-miestny kód zaslaný na číslo\n${widget.phone}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // OTP Input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  height: 48,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.amber,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_controllers.map((c) => c.text).join().length == 6) {
                        _verifyCode();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),

            // Actions
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _verifyCode,
                child: const Text(
                  'Overiť',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Resend / timer row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _resendTimer == 0 ? _resendCode : null,
                    child: Text(
                      'Znovu odoslať kód',
                      style: TextStyle(
                        color: _resendTimer == 0 ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_resendTimer > 0)
                    Text(
                      '(${_resendTimer}s)',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Zrušiť',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
