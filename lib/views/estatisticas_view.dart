import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class EstatisticasView extends StatelessWidget {
  const EstatisticasView({super.key});

  @override
  Widget build(BuildContext context) {
    const azulSoftinsa = Color(0xFF1A468D);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: azulSoftinsa,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Estatísticas e Relatórios",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumo de Desempenho",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatBox(
                  "Pontos Totais",
                  "8000",
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(width: 15),
                _buildStatBox(
                  "Posição Geral",
                  "#12",
                  Icons.emoji_events_outlined,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Evolução Mensal (Placeholder)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  "Espaço reservado para package de gráficos\n(ex: fl_chart)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
