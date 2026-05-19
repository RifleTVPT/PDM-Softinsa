import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';

class HistoricoBadgesView extends StatelessWidget {
  const HistoricoBadgesView({super.key});

  @override
  Widget build(BuildContext context) {
    const azulSoftinsa = Color(0xFF1A468D);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: azulSoftinsa,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Histórico e Certificados",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4, // Mock de dados para UI
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EEF2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: azulSoftinsa),
              ),
              title: Text(
                "Badge Nível ${String.fromCharCode(65 + index)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  "Concluído a: ${10 + index}/05/2026",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              trailing: const Icon(
                Icons.file_download_outlined,
                color: Colors.grey,
              ),
              onTap: () {
                // Lógica de download do PDF do certificado (futuro)
              },
            ),
          );
        },
      ),
    );
  }
}
