import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final User user;
  final int eventsHosted;
  final int eventsAttended;
  final int connections;

  const UserLoaded({
    required this.user,
    required this.eventsHosted,
    required this.eventsAttended,
    required this.connections,
  });

  @override
  List<Object?> get props => [user, eventsHosted, eventsAttended, connections];

  UserLoaded copyWith({
    User? user,
    int? eventsHosted,
    int? eventsAttended,
    int? connections,
  }) {
    return UserLoaded(
      user: user ?? this.user,
      eventsHosted: eventsHosted ?? this.eventsHosted,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      connections: connections ?? this.connections,
    );
  }
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
