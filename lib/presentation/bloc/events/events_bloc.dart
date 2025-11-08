import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_event.dart';
import '../../../domain/usecases/get_events.dart';
import '../../../domain/usecases/get_events_by_category.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final GetEvents getEvents;
  final GetEventsByCategory getEventsByCategory;
  final CreateEvent createEvent;

  EventsBloc({
    required this.getEvents,
    required this.getEventsByCategory,
    required this.createEvent,
  }) : super(EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadEventsByCategory>(_onLoadEventsByCategory);
    on<FilterEventsByCategory>(_onFilterEventsByCategory);
    on<CreateEventRequested>(_onCreateEvent);
    on<RefreshEvents>(_onRefreshEvents);
    on<RemoveEvent>(_onRemoveEvent);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());

    final result = await getEvents(const NoParams());

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (events) {
        // Filter untuk hanya menampilkan event yang belum selesai
        final futureEvents = events.where((event) => !event.hasEnded).toList();
        final nearbyEvents = futureEvents.where((event) => event.isStartingSoon).toList();
        emit(EventsLoaded(
          events: events,
          filteredEvents: futureEvents,
          nearbyEvents: nearbyEvents,
        ));
      },
    );
  }

  Future<void> _onLoadEventsByCategory(
    LoadEventsByCategory event,
    Emitter<EventsState> emit,
  ) async {
    final result = await getEventsByCategory(
      GetEventsByCategoryParams(category: event.category),
    );

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (events) {
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          emit(currentState.copyWith(
            filteredEvents: events,
            selectedCategory: event.category,
          ));
        }
      },
    );
  }

  void _onFilterEventsByCategory(
    FilterEventsByCategory event,
    Emitter<EventsState> emit,
  ) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;

      if (event.category == null) {
        // Clear filter - tapi tetap hanya tampilkan event yang belum selesai
        final futureEvents = currentState.events.where((e) => !e.hasEnded).toList();
        emit(currentState.copyWith(
          filteredEvents: futureEvents,
          selectedCategory: null,
        ));
      } else {
        // Apply filter - dan hanya tampilkan event yang belum selesai
        final filteredEvents = currentState.events
            .where((e) => e.category == event.category && !e.hasEnded)
            .toList();

        emit(currentState.copyWith(
          filteredEvents: filteredEvents,
          selectedCategory: event.category,
        ));
      }
    }
  }

  Future<void> _onCreateEvent(
    CreateEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    final result = await createEvent(
      CreateEventParams(event: event.event),
    );

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (createdEvent) {
        // Get current state and add the new event
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          final updatedEvents = [createdEvent, ...currentState.events];
          final isStartingSoon = createdEvent.startTime.difference(DateTime.now()).inHours <= 24;
          final updatedNearbyEvents = isStartingSoon
            ? [createdEvent, ...currentState.nearbyEvents]
            : currentState.nearbyEvents;

          // Filter untuk hanya menampilkan event yang belum selesai
          final filteredFutureEvents = currentState.selectedCategory == null
              ? updatedEvents.where((e) => !e.hasEnded).toList()
              : updatedEvents.where((e) => e.category == currentState.selectedCategory && !e.hasEnded).toList();

          emit(EventsLoaded(
            events: updatedEvents,
            filteredEvents: filteredFutureEvents,
            nearbyEvents: updatedNearbyEvents,
            selectedCategory: currentState.selectedCategory,
          ));
        } else {
          // If no current state, just reload
          add(LoadEvents());
        }
      },
    );
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<EventsState> emit,
  ) async {
    add(LoadEvents());
  }

  void _onRemoveEvent(
    RemoveEvent event,
    Emitter<EventsState> emit,
  ) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;

      // Remove event from all lists
      final updatedEvents = currentState.events
          .where((e) => e.id != event.eventId)
          .toList();
      final updatedFilteredEvents = currentState.filteredEvents
          .where((e) => e.id != event.eventId)
          .toList();
      final updatedNearbyEvents = currentState.nearbyEvents
          .where((e) => e.id != event.eventId)
          .toList();

      emit(EventsLoaded(
        events: updatedEvents,
        filteredEvents: updatedFilteredEvents,
        nearbyEvents: updatedNearbyEvents,
        selectedCategory: currentState.selectedCategory,
      ));
    }
  }
}