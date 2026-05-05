import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class NotificacoesView extends StatelessWidget {
  const NotificacoesView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Ecrã de Notificações")),
    );
  }
}
