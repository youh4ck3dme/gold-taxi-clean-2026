import 'package:equatable/equatable.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class FetchEvents extends EventsEvent {
  final String? search;
  final bool isRefresh;

  const FetchEvents({this.search, this.isRefresh = false});

  @override
  List<Object?> get props => [search, isRefresh];
}
