import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_current_user.dart';
import '../../../domain/usecases/get_user_by_id.dart';
import '../../../domain/usecases/search_users.dart';
import '../../../domain/usecases/follow_user.dart';
import '../../../domain/usecases/unfollow_user.dart';
import '../../../domain/usecases/get_user_followers.dart';
import '../../../domain/usecases/get_user_following.dart';
import '../../../domain/usecases/update_current_user.dart';
import '../../../domain/repositories/post_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthService authService;
  final GetCurrentUser? getCurrentUser;
  final UpdateCurrentUser? updateCurrentUser;
  final GetUserById? getUserById;
  final SearchUsers? searchUsers;
  final FollowUser? followUser;
  final UnfollowUser? unfollowUser;
  final GetUserFollowers? getUserFollowers;
  final GetUserFollowing? getUserFollowing;
  final PostRepository? postRepository;

  UserBloc({
    required this.authService,
    this.getCurrentUser,
    this.updateCurrentUser,
    this.getUserById,
    this.searchUsers,
    this.followUser,
    this.unfollowUser,
    this.getUserFollowers,
    this.getUserFollowing,
    this.postRepository,
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
    on<LoadUserPostsEvent>(_onLoadUserPosts);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      // Try to use API if available
      if (getCurrentUser != null) {
        print('[UserBloc] Calling getCurrentUser API...');
        final result = await getCurrentUser!(NoParams());

        result.fold(
          (failure) {
            // Fallback to mock data if API fails
            print('[UserBloc] API failed with: ${failure.message}');
            print('[UserBloc] Falling back to mock data');
            _loadMockUserProfile(emit);
          },
          (user) {
            print('[UserBloc] API success! User ID: ${user.id}, Name: ${user.name}, Email: ${user.email}');
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
        print('[UserBloc] getCurrentUser use case not available, using mock data');
        _loadMockUserProfile(emit);
      }
    } catch (e) {
      print('[UserBloc] Exception caught: $e');
      emit(UserError('Failed to load user profile: $e'));
    }
  }

  void _loadMockUserProfile(Emitter<UserState> emit) {
    // Get user from auth service
    final email = authService.userEmail ?? 'user@anigmaa.com';
    final name = authService.userName ?? 'Anigmaa User';

    // Mock user data - MINIMAL DATA (no dummy bio/avatar)
    final user = User(
      id: '1',
      name: name,
      email: email,
      avatar: null, // No dummy avatar
      bio: null, // No dummy bio
      interests: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastLoginAt: DateTime.now(),
      settings: const UserSettings(),
      stats: const UserStats(
        eventsAttended: 0,
        eventsCreated: 0,
        followersCount: 0, // Fixed: no dummy follower count
        followingCount: 0,
        reviewsGiven: 0,
        averageRating: 0.0,
      ),
      privacy: const UserPrivacy(),
      isVerified: false,
      isEmailVerified: true,
    );

    emit(UserLoaded(
      user: user,
      eventsHosted: user.stats.eventsCreated,
      eventsAttended: user.stats.eventsAttended,
      connections: user.stats.followersCount,
      postsCount: 0,
      totalInvitedAttendees: 0,
    ));
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    if (state is! UserLoaded) return;

    final currentState = state as UserLoaded;
    emit(UserLoading());

    try {
      // Prepare update data - only include fields that are provided
      final Map<String, dynamic> updateData = {};
      if (event.name != null) updateData['name'] = event.name;
      if (event.bio != null) updateData['bio'] = event.bio;
      if (event.avatar != null) updateData['avatar'] = event.avatar;
      if (event.interests != null) updateData['interests'] = event.interests;
      if (event.phone != null) updateData['phone'] = event.phone;
      if (event.dateOfBirth != null) updateData['date_of_birth'] = event.dateOfBirth!.toIso8601String();
      if (event.gender != null) updateData['gender'] = event.gender;
      if (event.location != null) updateData['location'] = event.location;

      print('[UserBloc] Updating user profile with data: $updateData');

      // Call API to update user
      if (updateCurrentUser != null) {
        final result = await updateCurrentUser!(
          UpdateCurrentUserParams(userData: updateData),
        );

        result.fold(
          (failure) {
            print('[UserBloc] Update failed: ${failure.message}');
            emit(UserError('Gagal update profil: ${failure.message}'));
            // Restore previous state
            emit(currentState);
          },
          (updatedUser) {
            print('[UserBloc] Update successful: ${updatedUser.name}, bio: ${updatedUser.bio}');
            emit(currentState.copyWith(user: updatedUser));
          },
        );
      } else {
        // Fallback to local update if API not available
        print('[UserBloc] API not available, doing local update');
        final updatedUser = currentState.user.copyWith(
          name: event.name ?? currentState.user.name,
          bio: event.bio ?? currentState.user.bio,
          avatar: event.avatar ?? currentState.user.avatar,
          interests: event.interests ?? currentState.user.interests,
          phone: event.phone ?? currentState.user.phone,
          dateOfBirth: event.dateOfBirth ?? currentState.user.dateOfBirth,
          gender: event.gender ?? currentState.user.gender,
          location: event.location ?? currentState.user.location,
        );
        emit(currentState.copyWith(user: updatedUser));
      }
    } catch (e) {
      print('[UserBloc] Update error: $e');
      emit(UserError('Terjadi kesalahan: $e'));
      // Restore previous state
      emit(currentState);
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
      if (getUserById != null) {
        final result = await getUserById!(
          GetUserByIdParams(userId: event.userId),
        );

        result.fold(
          (failure) => emit(UserError('Failed to load user: ${failure.toString()}')),
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
        emit(const UserError('GetUserById use case not available'));
      }
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

  Future<void> _onLoadUserPosts(
    LoadUserPostsEvent event,
    Emitter<UserState> emit,
  ) async {
    // Only load posts if current state is UserLoaded
    if (state is! UserLoaded) return;

    final currentState = state as UserLoaded;

    if (postRepository == null) {
      print('[UserBloc] PostRepository not available');
      return;
    }

    try {
      final result = await postRepository!.getUserPosts(
        event.userId,
        limit: 50,
      );

      result.fold(
        (failure) {
          print('[UserBloc] Failed to load user posts: ${failure.message}');
          // Keep current state, just log error
        },
        (paginatedPosts) {
          print('[UserBloc] Loaded ${paginatedPosts.data.length} posts for user ${event.userId}');
          emit(currentState.copyWith(
            userPosts: paginatedPosts.data,
            postsCount: paginatedPosts.data.length,
          ));
        },
      );
    } catch (e) {
      print('[UserBloc] Exception loading user posts: $e');
    }
  }
}
