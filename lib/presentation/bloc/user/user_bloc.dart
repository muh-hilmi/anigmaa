import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../core/services/auth_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthService authService;

  UserBloc({required this.authService}) : super(UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<TogglePremium>(_onTogglePremium);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Get user from auth service
      final email = authService.userEmail ?? 'user@anigmaa.com';
      final name = authService.userName ?? 'Anigmaa User';

      // Mock user data
      final user = User(
        id: '1',
        name: name,
        email: email,
        avatar: 'https://i.pravatar.cc/300?img=12',
        bio: 'Passionate about connecting with people through amazing events! 🎉',
        interests: const ['Music', 'Sports', 'Technology', 'Food', 'Travel'],
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        lastLoginAt: DateTime.now(),
        settings: const UserSettings(),
        stats: const UserStats(
          eventsAttended: 48,
          eventsCreated: 12,
          followersCount: 156,
          followingCount: 89,
          reviewsGiven: 24,
          averageRating: 4.8,
        ),
        privacy: const UserPrivacy(),
        isVerified: true,
        isEmailVerified: true,
      );

      emit(UserLoaded(
        user: user,
        eventsHosted: user.stats.eventsCreated,
        eventsAttended: user.stats.eventsAttended,
        connections: user.stats.followersCount,
      ));
    } catch (e) {
      emit(UserError('Failed to load user profile: $e'));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      emit(UserLoading());

      await Future.delayed(const Duration(milliseconds: 800));

      final updatedUser = currentState.user.copyWith(
        name: event.name,
        bio: event.bio,
        interests: event.interests,
      );

      emit(currentState.copyWith(user: updatedUser));
    }
  }

  Future<void> _onTogglePremium(
    TogglePremium event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      // For now, just toggle isVerified as "premium" indicator
      final updatedUser = currentState.user.copyWith(
        isVerified: !currentState.user.isVerified,
      );

      emit(currentState.copyWith(user: updatedUser));
    }
  }

  Future<void> _onAddInterest(
    AddInterest event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      if (!currentState.user.interests.contains(event.interest)) {
        final updatedInterests = [...currentState.user.interests, event.interest];
        final updatedUser = currentState.user.copyWith(interests: updatedInterests);

        emit(currentState.copyWith(user: updatedUser));
      }
    }
  }

  Future<void> _onRemoveInterest(
    RemoveInterest event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;

      final updatedInterests = currentState.user.interests
          .where((interest) => interest != event.interest)
          .toList();

      final updatedUser = currentState.user.copyWith(interests: updatedInterests);

      emit(currentState.copyWith(user: updatedUser));
    }
  }
}
