import 'package:swifty_companion/models/user.dart';
import 'package:swifty_companion/services/auth_service.dart';
import 'package:swifty_companion/services/user_service.dart';

/// Servicio falso: devuelve [user] (o uno vacío con ese login) sin tocar la
/// red. Si se le pasan [errors], las primeras llamadas lanzan esos errores en
/// orden.
class FakeUserService extends UserService {
  FakeUserService([this.user, List<Object> errors = const []])
    : _errors = [...errors],
      super(
        auth: AuthService(clientId: '', clientSecret: ''),
      );

  final User? user;
  final List<Object> _errors;

  @override
  Future<Map<String, String>> imageHeaders() async => const {};

  @override
  Future<User> fetchUser(String login) async {
    if (_errors.isNotEmpty) throw _errors.removeAt(0);
    return user ??
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
}
