import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;

  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objednávka potvrdená'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ďakujeme za vašu objednávku!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Vaša objednávka č. #$orderId bola úspešne prijatá a momentálne ju spracovávame.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Potvrdenie a detaily objednávky sme vám odoslali na e-mail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Pokračovať v nákupe',
              onPressed: () {
                context.go('/products');
              },
            ),
          ],
        ),
      ),
    );
  }
}
