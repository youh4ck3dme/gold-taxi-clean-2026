import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class DriverOnboardingPage extends StatefulWidget {
  const DriverOnboardingPage({super.key});

  @override
  State<DriverOnboardingPage> createState() => _DriverOnboardingPageState();
}

class _DriverOnboardingPageState extends State<DriverOnboardingPage> {
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  XFile? _profilePhoto;
  XFile? _idCardPhoto;
  XFile? _licensePhoto;

  bool _isUploading = false;

  Future<void> _pickImage(int step) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // Size validation (5 MB limit)
      final size = await image.length();
      if (size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Súbor je príliš veľký. Maximálna veľkosť je 5 MB.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      setState(() {
        if (step == 0) {
          _profilePhoto = image;
        } else if (step == 1) {
          _idCardPhoto = image;
        } else if (step == 2) {
          _licensePhoto = image;
        }
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitDocuments() async {
    if (_profilePhoto == null ||
        _idCardPhoto == null ||
        _licensePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nahrajte prosím všetky tri dokumenty.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final profileBytes = await _profilePhoto!.readAsBytes();
      final idCardBytes = await _idCardPhoto!.readAsBytes();
      final licenseBytes = await _licensePhoto!.readAsBytes();

      if (mounted) {
        await context.read<ProfileCubit>().uploadDriverDocuments(
          profilePhotoBytes: profileBytes,
          profilePhotoName: _profilePhoto!.name,
          idCardBytes: idCardBytes,
          idCardName: _idCardPhoto!.name,
          licenseBytes: licenseBytes,
          licenseName: _licensePhoto!.name,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dokumenty boli úspešne odoslané na kontrolu.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/profile');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba nahrávania: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrácia vodiča - Dokumenty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Nahrávam a šifrujem dokumenty...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Toto môže chvíľu trvať.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitDocuments();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      }
                    },
                    steps: [
                      Step(
                        isActive: _currentStep >= 0,
                        state: _profilePhoto != null
                            ? StepState.complete
                            : StepState.indexed,
                        title: const Text('Profilová fotografia'),
                        subtitle: const Text(
                          'Obrázok tváre pre klientsku aplikáciu',
                        ),
                        content: _buildUploadBox(0, _profilePhoto),
                      ),
                      Step(
                        isActive: _currentStep >= 1,
                        state: _idCardPhoto != null
                            ? StepState.complete
                            : StepState.indexed,
                        title: const Text('Občiansky preukaz'),
                        subtitle: const Text(
                          'Fotka prednej strany občianskeho preukazu',
                        ),
                        content: _buildUploadBox(1, _idCardPhoto),
                      ),
                      Step(
                        isActive: _currentStep >= 2,
                        state: _licensePhoto != null
                            ? StepState.complete
                            : StepState.indexed,
                        title: const Text(
                          'Technický preukaz / Taxikárska licencia',
                        ),
                        subtitle: const Text('Oprávnenie vykonávať taxislužbu'),
                        content: _buildUploadBox(2, _licensePhoto),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUploadBox(int step, XFile? photo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _pickImage(step),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
              ),
              child: photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(photo.path, fit: BoxFit.cover)
                          : Image.file(File(photo.path), fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kliknite pre nahratie fotografie',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Max. 5 MB, formáty: JPG, PNG',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
            ),
          ),
          if (photo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    photo.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (step == 0) _profilePhoto = null;
                      if (step == 1) _idCardPhoto = null;
                      if (step == 2) _licensePhoto = null;
                    });
                  },
                  child: const Text(
                    'Zmazať',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
