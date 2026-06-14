import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import 'package:gold_taxi/core/widgets/loaders/shimmer_list_loader.dart';
import 'package:gold_taxi/models/event_model.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EventsBloc>()..add(const FetchEvents()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Udalosti')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return AppTextField(
                    controller: _searchController,
                    labelText: 'Vyhľadať udalosti',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<EventsBloc>().add(const FetchEvents());
                      },
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (value) {
                      context.read<EventsBloc>().add(FetchEvents(search: value));
                    },
                    validator: null,
                    hintText: 'Názov udalosti, kategória...',
                    keyboardType: TextInputType.text,
                  );
                }
              ),
            ),
            Expanded(
              child: BlocBuilder<EventsBloc, EventsState>(
                builder: (context, state) {
                  if (state is EventsLoading) {
                    return const ShimmerListLoader();
                  } else if (state is EventsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chyba: ${state.message}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<EventsBloc>().add(FetchEvents(
                                search: _searchController.text,
                                isRefresh: true,
                              ));
                            },
                            child: const Text('Skúsiť znova'),
                          )
                        ],
                      ),
                    );
                  } else if (state is EventsLoaded) {
                    final events = state.events;
                    if (events.isEmpty) {
                      return const Center(child: Text('Nenašli sa žiadne udalosti.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<EventsBloc>().add(FetchEvents(
                          search: _searchController.text,
                          isRefresh: true,
                        ));
                      },
                      child: ListView.builder(
                        itemCount: events.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _EventCard(event: event);
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final startDateStr = dateFormat.format(event.startDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/events/detail', extra: event);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.images.isNotEmpty)
              Image.network(
                event.images.first,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              )
            else
              Container(
                height: 120,
                color: Colors.blue[50],
                child: const Icon(Icons.event, size: 50, color: Colors.blue),
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
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (event.price != null)
                        Text(
                          event.price == 0 ? 'Zadarmo' : '${event.price!.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        startDateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
