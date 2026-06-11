import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String bio;

  const UpdateProfile({required this.name, required this.bio});

  @override
  List<Object?> get props => [name, bio];
}
