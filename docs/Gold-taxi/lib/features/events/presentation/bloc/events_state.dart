import 'package:equatable/equatable.dart';
import 'package:gold_taxi/models/event_model.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventModel> events;

  const EventsLoaded({required this.events});

  @override
  List<Object?> get props => [events];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}
