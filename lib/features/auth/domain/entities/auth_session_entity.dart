import 'package:equatable/equatable.dart';

class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({required this.username, required this.isLoggedIn});

  final String username;
  final bool isLoggedIn;

  @override
  List<Object> get props => [username, isLoggedIn];
}
