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
    on<LoadEventsByMode>(_onLoadEventsByMode);
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

    final result = await getEvents(const GetEventsParams(limit: 20, offset: 0));

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (paginatedResponse) {
        final allEvents = paginatedResponse.data;
        // No longer filtering past events - let UI handle display
        final nearbyEvents = allEvents.where((event) => event.isStartingSoon).toList();
        emit(EventsLoaded(
          events: allEvents,
          filteredEvents: allEvents,
          nearbyEvents: nearbyEvents,
          paginationMeta: paginatedResponse.meta,
        ));
      },
    );
  }

  Future<void> _onLoadEventsByMode(
    LoadEventsByMode event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());

    final result = await getEvents(GetEventsParams(limit: 50, offset: 0, mode: event.mode));

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (paginatedResponse) {
        final allEvents = paginatedResponse.data;
        final nearbyEvents = allEvents.where((event) => event.isStartingSoon).toList();
        emit(EventsLoaded(
          events: allEvents,
          filteredEvents: allEvents,
          nearbyEvents: nearbyEvents,
          paginationMeta: paginatedResponse.meta,
        ));
      },
    );
  }

  Future<void> _onLoadEventsByCategory(
    LoadEventsByCategory event,
    Emitter<EventsState> emit,
  ) async {
    final result = await getEventsByCategory(
      GetEventsByCategoryParams(category: event.category, limit: 20, offset: 0),
    );

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (paginatedResponse) {
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          emit(currentState.copyWith(
            filteredEvents: paginatedResponse.data,
            selectedCategory: event.category,
            paginationMeta: paginatedResponse.meta,
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
        // Clear filter - show all events
        emit(currentState.copyWith(
          filteredEvents: currentState.events,
          selectedCategory: null,
        ));
      } else {
        // Apply category filter - show all events in category
        final filteredEvents = currentState.events
            .where((e) => e.category == event.category)
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
    // Set creating state
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(currentState.copyWith(isCreatingEvent: true));
    }

    final result = await createEvent(
      CreateEventParams(event: event.event),
    );

    result.fold(
      (failure) {
        // Set error message so UI can show snackbar
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          emit(currentState.copyWith(
            isCreatingEvent: false,
            createErrorMessage: 'Gagal bikin event: ${failure.message}',
          ));
        } else {
          // If not loaded state, emit error
          emit(EventsError(failure.message));
        }
      },
      (createdEvent) {
        // Get current state and add the new event
        if (state is EventsLoaded) {
          final currentState = state as EventsLoaded;
          final updatedEvents = [createdEvent, ...currentState.events];
          final isStartingSoon = createdEvent.startTime.difference(DateTime.now()).inHours <= 24;
          final updatedNearbyEvents = isStartingSoon
            ? [createdEvent, ...currentState.nearbyEvents]
            : currentState.nearbyEvents;

          // Apply category filter if selected
          final filteredEvents = currentState.selectedCategory == null
              ? updatedEvents
              : updatedEvents.where((e) => e.category == currentState.selectedCategory).toList();

          emit(EventsLoaded(
            events: updatedEvents,
            filteredEvents: filteredEvents,
            nearbyEvents: updatedNearbyEvents,
            selectedCategory: currentState.selectedCategory,
            isCreatingEvent: false,
            successMessage: 'Event berhasil dibuat! 🎉',
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