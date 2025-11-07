import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;
  final List<Event> filteredEvents;
  final List<Event> nearbyEvents;
  final EventCategory? selectedCategory;

  const EventsLoaded({
    required this.events,
    required this.filteredEvents,
    required this.nearbyEvents,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [events, filteredEvents, nearbyEvents, selectedCategory];

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    List<Event>? nearbyEvents,
    EventCategory? selectedCategory,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

class EventCreated extends EventsState {
  final Event event;

  const EventCreated(this.event);

  @override
  List<Object?> get props => [event];
}