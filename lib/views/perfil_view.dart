import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class PerfilView extends StatelessWidget {
  const PerfilView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Dados do Utilizador / Configurações")),
    );
  }
}
