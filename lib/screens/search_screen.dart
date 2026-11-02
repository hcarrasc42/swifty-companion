import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.users});

  final UserService users;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Los logins de 42 son minúsculas, dígitos, guion y guion bajo.
  static final _loginPattern = RegExp(r'^[a-z0-9_-]+$');

  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Devuelve el login normalizado, o null si no es válido (y fija el error).
  String? _validate() {
    final login = _controller.text.trim().toLowerCase();
    String? error;
    if (login.isEmpty) {
      error = 'Escribe un login';
    } else if (!_loginPattern.hasMatch(login)) {
      error = 'Solo letras, números, "-" y "_"';
    }
    setState(() => _error = error);
    return error == null ? login : null;
  }

  void _search() {
    final login = _validate();
    if (login == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(login: login, users: widget.users),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swifty Companion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: 'Login de 42',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _search, child: const Text('Buscar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
