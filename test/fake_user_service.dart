import 'package:swifty_companion/models/user.dart';
import 'package:swifty_companion/services/auth_service.dart';
import 'package:swifty_companion/services/user_service.dart';

/// Servicio falso: devuelve [user] (o uno vacío con ese login) sin tocar la red.
class FakeUserService extends UserService {
  FakeUserService([this.user])
    : super(
        auth: AuthService(clientId: '', clientSecret: ''),
      );

  final User? user;

  @override
  Future<User> fetchUser(String login) async =>
      user ??
      User(
        login: login,
        displayName: 'Perfil de $login',
        email: '',
        correctionPoints: 0,
        wallet: 0,
        cursus: const [],
        projects: const [],
      );
}
