import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.login, required this.users});

  final String login;
  final UserService users;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Se guarda el Future en el estado: si se creara dentro de build(), cada
  // reconstrucción volvería a llamar a la API.
  late final Future<User> _user = widget.users.fetchUser(widget.login);

  @override
  Widget build(BuildContext context) {
    // El AppBar muestra solo la flecha de "atrás" porque esta pantalla se
    // abrió con Navigator.push: Flutter sabe que hay una ruta anterior.
    return Scaffold(
      appBar: AppBar(title: Text(widget.login)),
      body: Center(
        child: FutureBuilder<User>(
          future: _user,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(error is UserException ? error.message : '$error');
            }
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final user = snapshot.data!;
            final level = user.mainCursus?.level;
            // Provisional: la pantalla completa llega en el paso 6.
            return Text(
              '${user.displayName}'
              '${level == null ? '' : ' · nivel $level'}',
            );
          },
        ),
      ),
    );
  }
}
