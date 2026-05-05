import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class BadgeDetalheView extends StatelessWidget {
  const BadgeDetalheView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Informação detalhada do Badge")),
    );
  }
}
