import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gold_taxi/models/event_model.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/features/shared/presentation/widgets/reviews_list.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final startDateStr = dateFormat.format(event.startDate);
    final endDateStr = dateFormat.format(event.endDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail udalosti')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.images.isNotEmpty)
              Image.network(
                event.images.first,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 60),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.blue[100],
                child: const Center(
                  child: Icon(Icons.event, size: 80, color: Colors.blue),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      if (event.price != null)
                        Text(
                          event.price == 0
                              ? 'Zadarmo'
                              : '${event.price!.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),

                  // Date and Time Info
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Začiatok: $startDateStr',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Koniec: $endDateStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Info
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 32),

                  // Description
                  const Text(
                    'O udalosti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description.replaceAll(
                      RegExp(r'<[^>]*>|&[^;]+;'),
                      '',
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),

                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: 'Registrovať sa na udalosť',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registrácia úspešná (Zástupná akcia)'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32),
                  ReviewsList(postId: event.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
