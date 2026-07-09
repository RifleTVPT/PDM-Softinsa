import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/rotas.dart';
import 'services/notificacoes.dart';
import 'services/app_state.dart';

bool _isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );
    final exp = payload['exp'];
    if (exp == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now());
  } catch (e) {
    return true; // Na dúvida, expirou
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Erro ao iniciar Firebase: $e");
  }

  // login
  // Lemos a memória do telemóvel
  final prefs = await SharedPreferences.getInstance();
  // Vemos se a variável 'isLogged' é true. Se não existir, assume false.
  bool isLogged = prefs.getBool('isLogged') ?? false;
  String? token = prefs.getString('jwtToken');

  if (isLogged && token != null) {
    if (_isTokenExpired(token)) {
      isLogged = false;
      await prefs.remove('jwtToken');
      await prefs.setBool('isLogged', false);
    }
  } else {
    isLogged = false;
  }

  // Decide a rota, se isLogged for true vai para dashboard, senão vai para login
  final String rotaInicial = isLogged ? '/dashboard' : '/';

  // Criamos o router com a rota decidida
  final GoRouter router = criarRouter(rotaInicial);

  try {
    final navigatorKey = router.routerDelegate.navigatorKey;
    await Notificacoes().inicializar(navigatorKey);
    print("Firebase e Notificações iniciados com sucesso!");
  } catch (e) {
    print("Erro ao iniciar Notificações: $e");
  }

  // Passamos o router para a nossa App, envolvida no Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router; // Recebe o router configurado no main

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Softinsa Badges',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34659D)),
        useMaterial3: true,
      ),
      // Ligamos o nosso router dinâmico
      routerConfig: router,
    );
  }
}
