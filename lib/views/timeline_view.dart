import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});
  @override
  Widget build(BuildContext context) {
    return const LayoutConsultor(
      corpo: Center(child: Text("Ecrã de Timeline/Objetivos")),
    );
  }
}
