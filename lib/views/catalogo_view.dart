import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class CatalogoView extends StatelessWidget {
  const CatalogoView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      indexMenuInferior: 1,
      corpo: Center(child: Text("Explorar Badges")),
    );
  }
}
