import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class EstatisticasView extends StatelessWidget {
  const EstatisticasView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Ecrã de Estatísticas")),
    );
  }
}
