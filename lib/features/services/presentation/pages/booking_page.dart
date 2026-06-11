import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/models/service_model.dart';
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';

class BookingPage extends StatefulWidget {
  final ServiceModel service;

  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchSlotsForDate(_selectedDay!);
  }

  void _fetchSlotsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    context.read<BookingsBloc>().add(
          FetchAvailableSlots(
            serviceId: widget.service.id,
            date: dateStr,
          ),
        );
  }

  void _submit() {
    if (_selectedDay != null && _selectedTimeSlot != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      context.read<BookingsBloc>().add(
            SubmitBooking(
              serviceId: widget.service.id,
              date: dateStr,
              timeSlot: _selectedTimeSlot!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingsBloc, BookingsState>(
      listener: (context, state) {
        if (state is BookingSubmissionSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Rezervácia úspešná!'),
              content: Text(
                'Vaša rezervácia pre službu "${widget.service.name}" na ${_selectedTimeSlot!} dňa ${DateFormat('dd.MM.yyyy').format(_selectedDay!)} bola úspešne zaznamenaná.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pop(); // pop booking page
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is BookingSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chyba rezervácie: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Rezervácia termínu')),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.service.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Poskytuje: ${widget.service.provider}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    // Table Calendar Widget
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 30)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _selectedTimeSlot = null; // reset slot selection
                          });
                          _fetchSlotsForDate(selectedDay);
                        },
                        calendarFormat: CalendarFormat.twoWeeks,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blue[200],
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Dostupné časové sloty',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    BlocBuilder<BookingsBloc, BookingsState>(
                      buildWhen: (previous, current) =>
                          current is BookingsLoading ||
                          current is BookingsSlotsLoaded ||
                          current is BookingsError,
                      builder: (context, state) {
                        if (state is BookingsLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else if (state is BookingsError) {
                          return Center(
                            child: Text(
                              'Chyba pri načítaní slotov: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        } else if (state is BookingsSlotsLoaded) {
                          final slots = state.availableSlots;
                          if (slots.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Žiadne voľné termíny na tento deň.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: slots.map((slot) {
                              final isSelected = _selectedTimeSlot == slot;
                              return ChoiceChip(
                                label: Text(slot),
                                selected: isSelected,
                                selectedColor: Colors.blue,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTimeSlot = selected ? slot : null;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BlocBuilder<BookingsBloc, BookingsState>(
                builder: (context, state) {
                  final isSubmitting = state is BookingSubmissionInProgress;
                  final canSubmit = _selectedDay != null && _selectedTimeSlot != null && !isSubmitting;

                  return PrimaryButton(
                    text: isSubmitting ? 'Odosiela sa...' : 'Rezervovať termín',
                    onPressed: canSubmit ? _submit : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
