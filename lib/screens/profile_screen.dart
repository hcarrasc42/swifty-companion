import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.login});

  final String login;

  @override
  Widget build(BuildContext context) {
    // El AppBar muestra solo la flecha de "atrás" porque esta pantalla se
    // abrió con Navigator.push: Flutter sabe que hay una ruta anterior.
    return Scaffold(
      appBar: AppBar(title: Text(login)),
      body: Center(child: Text('Perfil de $login')),
    );
  }
}
