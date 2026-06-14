import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mock_geocoding_service.dart';
import '../../../../models/ride_stop.dart';
import '../cubits/ride_cubit.dart';

class MultiStopTimeline extends StatelessWidget {
  final String pickupAddress;
  final String dropoffAddress;

  const MultiStopTimeline({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideCubit, RideState>(
      builder: (context, state) {
        final stops = state.intermediateStops;
        final cubit = context.read<RideCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alt_route, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Plánovanie trasy a zastávky',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Pickup Node
            _buildTimelineNode(
              context: context,
              icon: Icons.my_location,
              iconColor: Colors.green,
              title: 'Štart',
              subtitle: pickupAddress,
              isFirst: true,
              isLast: stops.isEmpty && dropoffAddress.isEmpty,
            ),

            // 2. Intermediate Stops (Reorderable)
            if (stops.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stops.length,
                  // ignore: deprecated_member_use
                  onReorder: cubit.reorderStops,
                  itemBuilder: (context, index) {
                    final stop = stops[index];
                    return Container(
                      key: ValueKey(stop.id),
                      margin: const EdgeInsets.only(left: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.amber.shade200, width: 2),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.place, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stop.location.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_indicator, color: Colors.grey),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                          onPressed: () => cubit.removeIntermediateStop(stop.id),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  stop.location.address,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                const SizedBox(height: 8),

                                // Wait for me option
                                Row(
                                  children: [
                                    const Text('Počkaj ma:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: stop.isWaitingEnabled,
                                      onChanged: (val) {
                                        cubit.toggleWaitTime(stop.id, val, val ? 10 : 0);
                                      },
                                      activeThumbColor: AppColors.secondary,
                                    ),
                                    if (stop.isWaitingEnabled) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${stop.waitingMinutes} min (+${(stop.waitingMinutes * 0.30).toStringAsFixed(2)} €)',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  ],
                                ),
                                if (stop.isWaitingEnabled)
                                  Slider(
                                    value: stop.waitingMinutes.toDouble(),
                                    min: 5,
                                    max: 30,
                                    divisions: 5,
                                    label: '${stop.waitingMinutes} min',
                                    activeColor: Colors.amber.shade700,
                                    inactiveColor: Colors.amber.shade100,
                                    onChanged: (val) {
                                      cubit.toggleWaitTime(stop.id, true, val.toInt());
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // 3. Add stop button
            if (stops.length < 3)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 12),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.secondary),
                    label: const Text('Pridať medzipristátie', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddStopDialog(context),
                  ),
                ),
              ),

            // 4. Dropoff Node
            _buildTimelineNode(
              context: context,
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: 'Cieľ',
              subtitle: dropoffAddress,
              isFirst: false,
              isLast: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineNode({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isLast ? Colors.transparent : Colors.amber.shade200,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 16, bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pridať zastávku'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: MockGeocodingService.kosiceLocations.take(4).map((location) {
              return ListTile(
                title: Text(location.name),
                subtitle: Text(location.address),
                onTap: () {
                  context.read<RideCubit>().addIntermediateStop(location);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zrušiť'),
            ),
          ],
        );
      },
    );
  }
}
