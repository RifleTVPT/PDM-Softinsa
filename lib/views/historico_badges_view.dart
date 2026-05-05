import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class HistoricoBadgesView extends StatelessWidget {
  const HistoricoBadgesView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Ecrã de Badges Obtidos")),
    );
  }
}
