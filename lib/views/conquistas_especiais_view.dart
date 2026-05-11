import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class ConquistasEspeciaisView extends StatefulWidget {
  const ConquistasEspeciaisView({super.key});

  @override
  State<ConquistasEspeciaisView> createState() =>
      _ConquistasEspeciaisViewState();
}

class _ConquistasEspeciaisViewState extends State<ConquistasEspeciaisView> {
  final TextEditingController _pesquisaController = TextEditingController();

  // OBTIDAS (O Consultor já tem)
  final List<Map<String, dynamic>> _premiumObtidas = [
    {
      "id": 101,
      "titulo": "Certificação AWS Cloud Practitioner",
      "descricao": "Demonstra conhecimento global sobre a Cloud da AWS.",
      "bonus": 1000,
    },
  ];

  // DISPONÍVEIS NA PLATAFORMA (Ainda por conquistar)
  final List<Map<String, dynamic>> _premiumDisponiveis = [
    {
      "id": 102,
      "titulo": "Top Performer Q3 - Hybrid Cloud",
      "descricao": "Atribuído aos 5% melhores da Service Line.",
      "bonus": 500,
    },
    {
      "id": 103,
      "titulo": "Certificação Microsoft Azure Fundamentals",
      "descricao": "Validação de conceitos básicos de nuvem Microsoft.",
      "bonus": 800,
    },
  ];

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtrarLista(List<Map<String, dynamic>> lista) {
    if (_pesquisaController.text.isEmpty) return lista;
    return lista
        .where((b) => b['titulo']
            .toString()
            .toLowerCase()
            .contains(_pesquisaController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final obtidasVisiveis = _filtrarLista(_premiumObtidas);
    final disponiveisVisiveis = _filtrarLista(_premiumDisponiveis);

    return LayoutConsultor(
      corpo: Column(
        children: [
          // HEADER AZUL
          Container(
            width: double.infinity,
            color: const Color(0xFF34659D),
            padding:
                const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 25),
            child: Column(
              children: [
                const Text("Conquistas Especiais",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                const Text("Explore recompensas exclusivas e certificações.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                TextField(
                  controller: _pesquisaController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Pesquisar conquistas...",
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF34659D)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // CORPO COM DUAS SECÇÕES
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECÇÃO 1: OBTIDAS
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      SizedBox(width: 8),
                      Text("As Minhas Conquistas",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (obtidasVisiveis.isEmpty)
                    const Text("Nenhuma conquista obtida.",
                        style: TextStyle(color: Colors.grey))
                  else
                    ...obtidasVisiveis.map((b) => _cardPremium(b, true)),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),

                  // SECÇÃO 2: DISPONÍVEIS
                  const Row(
                    children: [
                      Icon(Icons.explore, color: Color(0xFF34659D)),
                      SizedBox(width: 8),
                      Text("Disponíveis na Plataforma",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (disponiveisVisiveis.isEmpty)
                    const Text("Nenhuma conquista disponível encontrada.",
                        style: TextStyle(color: Colors.grey))
                  else
                    ...disponiveisVisiveis.map((b) => _cardPremium(b, false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card unificado para as Premium (Obtidas e Disponíveis)
  Widget _cardPremium(Map<String, dynamic> badge, bool jaObtida) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: jaObtida
            ? Border.all(color: Colors.amber, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: jaObtida ? Colors.amber.shade50 : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(
                  color: jaObtida ? Colors.amber : const Color(0xFFC0C0C0),
                  width: 3),
            ),
            child: Icon(Icons.workspace_premium,
                size: 40,
                color: jaObtida ? Colors.amber.shade700 : Colors.grey),
          ),
          const SizedBox(height: 15),
          Text(badge['titulo'],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(badge['descricao'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 15),
          Text("+${badge['bonus']} Pontos Bónus",
              style: const TextStyle(
                  color: Color(0xFF0980E9), fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // Ambas vão para os detalhes, a vista detalhe tratará de mostrar o botão de partilha ou não consoante o ID passado
              onPressed: () => context.push('/badge_detalhe'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0980E9)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Ver Requisitos",
                  style: TextStyle(
                      color: Color(0xFF0980E9), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
