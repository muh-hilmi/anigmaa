import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends UserEvent {}

class UpdateUserProfile extends UserEvent {
  final String name;
  final String bio;
  final List<String> interests;

  const UpdateUserProfile({
    required this.name,
    required this.bio,
    required this.interests,
  });

  @override
  List<Object?> get props => [name, bio, interests];
}

class TogglePremium extends UserEvent {}

class AddInterest extends UserEvent {
  final String interest;

  const AddInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

class RemoveInterest extends UserEvent {
  final String interest;

  const RemoveInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}
