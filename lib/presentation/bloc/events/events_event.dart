import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventsEvent {}

class LoadEventsByMode extends EventsEvent {
  final String? mode; // 'trending', 'for_you', 'chill'

  const LoadEventsByMode({this.mode});

  @override
  List<Object?> get props => [mode];
}

class LoadEventsByCategory extends EventsEvent {
  final EventCategory category;

  const LoadEventsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterEventsByCategory extends EventsEvent {
  final EventCategory? category;

  const FilterEventsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class CreateEventRequested extends EventsEvent {
  final Event event;

  const CreateEventRequested(this.event);

  @override
  List<Object?> get props => [event];
}

class RefreshEvents extends EventsEvent {}

class RemoveEvent extends EventsEvent {
  final String eventId;

  const RemoveEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}