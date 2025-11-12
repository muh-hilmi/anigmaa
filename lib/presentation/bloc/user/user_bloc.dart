import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/search_users.dart';
import '../../../domain/usecases/follow_user.dart';
import '../../../domain/usecases/unfollow_user.dart';
import '../../../domain/usecases/get_user_followers.dart';
import '../../../domain/usecases/get_user_following.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthService authService;
  final GetCurrentUser? getCurrentUser;
  final SearchUsers? searchUsers;
  final FollowUser? followUser;
  final UnfollowUser? unfollowUser;
  final GetUserFollowers? getUserFollowers;
  final GetUserFollowing? getUserFollowing;

  UserBloc({
    required this.authService,
    this.getCurrentUser,
    this.searchUsers,
    this.followUser,
    this.unfollowUser,
    this.getUserFollowers,
    this.getUserFollowing,
  }) : super(UserInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<LoadUserById>(_onLoadUserById);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<TogglePremium>(_onTogglePremium);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
    on<SearchUsersEvent>(_onSearchUsers);
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<LoadFollowersEvent>(_onLoadFollowers);
    on<LoadFollowingEvent>(_onLoadFollowing);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      // Try to use API if available
      if (getCurrentUser != null) {
        final result = await getCurrentUser!(NoParams());

        result.fold(
          (failure) {
            // Fallback to mock data if API fails
            _loadMockUserProfile(emit);
          },
          (user) {
            emit(UserLoaded(
              user: user,
              eventsHosted: user.stats.eventsCreated,
              eventsAttended: user.stats.eventsAttended,
              connections: user.stats.followersCount,
              postsCount: 0, // TODO: Get from actual posts data
              totalInvitedAttendees: 0, // TODO: Calculate from events attendees
            ));
          },
        );
      } else {
        // No API available, use mock data
        _loadMockUserProfile(emit);
      }
    } catch (e) {
      emit(UserError('Failed to load user profile: $e'));
    }
  }

  void _loadMockUserProfile(Emitter<UserState> emit) {
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
      postsCount: 24,
      totalInvitedAttendees: 342,
    ));
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

  Future<void> _onLoadUserById(
    LoadUserById event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      // For now, just load the current user profile
      // TODO: Implement getUserById use case
      add(LoadUserProfile());
    } catch (e) {
      emit(UserError('Failed to load user: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    if (searchUsers == null) {
      emit(const UsersSearchError('Search feature not available'));
      return;
    }

    emit(UsersSearchLoading());

    try {
      final result = await searchUsers!(
        SearchUsersParams(query: event.query),
      );

      result.fold(
        (failure) => emit(UsersSearchError(failure.toString())),
        (users) => emit(UsersSearchLoaded(users)),
      );
    } catch (e) {
      emit(UsersSearchError('Failed to search users: $e'));
    }
  }

  Future<void> _onFollowUser(
    FollowUserEvent event,
    Emitter<UserState> emit,
  ) async {
    if (followUser == null) {
      emit(const UserError('Follow feature not available'));
      return;
    }

    try {
      final result = await followUser!(
        FollowUserParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(failure.toString())),
        (_) => emit(const UserActionSuccess('Successfully followed user')),
      );
    } catch (e) {
      emit(UserError('Failed to follow user: $e'));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUserEvent event,
    Emitter<UserState> emit,
  ) async {
    if (unfollowUser == null) {
      emit(const UserError('Unfollow feature not available'));
      return;
    }

    try {
      final result = await unfollowUser!(
        UnfollowUserParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(failure.toString())),
        (_) => emit(const UserActionSuccess('Successfully unfollowed user')),
      );
    } catch (e) {
      emit(UserError('Failed to unfollow user: $e'));
    }
  }

  Future<void> _onLoadFollowers(
    LoadFollowersEvent event,
    Emitter<UserState> emit,
  ) async {
    if (getUserFollowers == null) {
      emit(const UserError('Followers feature not available'));
      return;
    }

    emit(FollowersLoading());

    try {
      final result = await getUserFollowers!(
        GetUserFollowersParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(failure.toString())),
        (followers) => emit(FollowersLoaded(followers)),
      );
    } catch (e) {
      emit(UserError('Failed to load followers: $e'));
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowingEvent event,
    Emitter<UserState> emit,
  ) async {
    if (getUserFollowing == null) {
      emit(const UserError('Following feature not available'));
      return;
    }

    emit(FollowingLoading());

    try {
      final result = await getUserFollowing!(
        GetUserFollowingParams(userId: event.userId),
      );

      result.fold(
        (failure) => emit(UserError(failure.toString())),
        (following) => emit(FollowingLoaded(following)),
      );
    } catch (e) {
      emit(UserError('Failed to load following: $e'));
    }
  }
}
