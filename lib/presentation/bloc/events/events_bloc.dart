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

    // Note: Backend doesn't support mode parameter yet, so we filter on client-side
    final result = await getEvents(GetEventsParams(limit: 50, offset: 0, mode: event.mode));

    result.fold(
      (failure) => emit(EventsError(failure.message)),
      (paginatedResponse) {
        final allEvents = paginatedResponse.data;

        // Apply client-side filtering based on mode
        final filteredByMode = _filterEventsByMode(allEvents, event.mode);

        final nearbyEvents = filteredByMode.where((event) => event.isStartingSoon).toList();
        emit(EventsLoaded(
          events: filteredByMode,
          filteredEvents: filteredByMode,
          nearbyEvents: nearbyEvents,
          paginationMeta: paginatedResponse.meta,
        ));
      },
    );
  }

  /// Filter and sort events based on discovery mode
  List<Event> _filterEventsByMode(List<Event> events, String mode) {
    final now = DateTime.now();

    switch (mode) {
      case 'trending':
        // Trending: Most popular events (high attendance) and starting soon
        final sortedEvents = List<Event>.from(events);
        sortedEvents.sort((a, b) {
          // First priority: events starting within next 7 days
          final aStartingSoon = a.startTime.difference(now).inDays <= 7;
          final bStartingSoon = b.startTime.difference(now).inDays <= 7;

          if (aStartingSoon && !bStartingSoon) return -1;
          if (!aStartingSoon && bStartingSoon) return 1;

          // Second priority: number of attendees (popularity)
          final attendeeDiff = b.currentAttendees.compareTo(a.currentAttendees);
          if (attendeeDiff != 0) return attendeeDiff;

          // Third priority: closer start time
          return a.startTime.compareTo(b.startTime);
        });
        return sortedEvents;

      case 'chill':
        // Chill: Relaxed events (meetup, food, music) and free events
        final chillCategories = ['meetup', 'food', 'music'];
        final chillEvents = events.where((event) {
          final categoryStr = event.category.toString().split('.').last.toLowerCase();
          return event.isFree || chillCategories.contains(categoryStr);
        }).toList();

        // Sort by start time (upcoming first)
        chillEvents.sort((a, b) {
          // Prioritize free events
          if (a.isFree && !b.isFree) return -1;
          if (!a.isFree && b.isFree) return 1;

          // Then by start time
          return a.startTime.compareTo(b.startTime);
        });

        return chillEvents.isNotEmpty ? chillEvents : events;

      case 'for_you':
      default:
        // For You: Diverse mix of categories, balanced recommendation
        final sortedEvents = List<Event>.from(events);

        // Create a balanced mix: some popular, some upcoming, some diverse categories
        sortedEvents.sort((a, b) {
          final now = DateTime.now();

          // Score based on multiple factors
          int scoreA = 0;
          int scoreB = 0;

          // Factor 1: Starting within next 14 days (+3 points)
          if (a.startTime.difference(now).inDays <= 14 && a.startTime.isAfter(now)) {
            scoreA += 3;
          }
          if (b.startTime.difference(now).inDays <= 14 && b.startTime.isAfter(now)) {
            scoreB += 3;
          }

          // Factor 2: Good attendance (+2 points if > 10 people)
          if (a.currentAttendees > 10) scoreA += 2;
          if (b.currentAttendees > 10) scoreB += 2;

          // Factor 3: Free events (+1 point)
          if (a.isFree) scoreA += 1;
          if (b.isFree) scoreB += 1;

          // Compare scores
          final scoreDiff = scoreB.compareTo(scoreA);
          if (scoreDiff != 0) return scoreDiff;

          // If equal scores, sort by start time
          return a.startTime.compareTo(b.startTime);
        });

        return sortedEvents;
    }
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