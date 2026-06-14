import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gold_taxi/models/service_model.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/features/shared/presentation/widgets/reviews_list.dart';

class ServiceDetailPage extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail služby')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (service.images.isNotEmpty)
              Image.network(
                service.images.first,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 250,
                  child: Center(child: Icon(Icons.image_not_supported, size: 60)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${service.rating.toStringAsFixed(1)} (${service.reviewCount} hodnotení)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Poskytuje: ${service.provider}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${service.price.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Popis služby',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Rezervovať službu',
                    onPressed: () {
                      context.push('/booking', extra: service);
                    },
                  ),
                  const Divider(height: 32),
                  ReviewsList(postId: service.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
