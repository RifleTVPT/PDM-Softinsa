import 'package:flutter/material.dart';
import 'services/rotas.dart'; // Importa o ficheiro das rotas

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MaterialApp.router em vez de MaterialApp normal
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Softinsa Badges',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Aqui ligamos as configurações do GoRouter
      routerConfig: rotas,
    );
  }
}
