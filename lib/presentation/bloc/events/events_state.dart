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
  final bool isCreatingEvent;
  final String? createErrorMessage;
  final String? successMessage;

  const EventsLoaded({
    required this.events,
    required this.filteredEvents,
    required this.nearbyEvents,
    this.selectedCategory,
    this.isCreatingEvent = false,
    this.createErrorMessage,
    this.successMessage,
  });

  @override
  List<Object?> get props => [
        events,
        filteredEvents,
        nearbyEvents,
        selectedCategory,
        isCreatingEvent,
        createErrorMessage,
        successMessage,
      ];

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    List<Event>? nearbyEvents,
    EventCategory? selectedCategory,
    bool? isCreatingEvent,
    String? createErrorMessage,
    String? successMessage,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isCreatingEvent: isCreatingEvent ?? this.isCreatingEvent,
      createErrorMessage: createErrorMessage,
      successMessage: successMessage,
    );
  }

  EventsLoaded clearMessages() {
    return EventsLoaded(
      events: events,
      filteredEvents: filteredEvents,
      nearbyEvents: nearbyEvents,
      selectedCategory: selectedCategory,
      isCreatingEvent: isCreatingEvent,
      createErrorMessage: null,
      successMessage: null,
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