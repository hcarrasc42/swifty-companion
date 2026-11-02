import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/search_screen.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final auth = AuthService(
    clientId: dotenv.env['FT_UID'] ?? '',
    clientSecret: dotenv.env['FT_SECRET'] ?? '',
  );

  runApp(MyApp(users: UserService(auth: auth)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.users});

  /// Se pasa a las pantallas que consultan la API.
  final UserService users;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swifty Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: SearchScreen(users: users),
    );
  }
}
