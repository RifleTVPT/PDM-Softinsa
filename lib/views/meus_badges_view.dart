import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class MeusBadgesView extends StatefulWidget {
  const MeusBadgesView({super.key});

  @override
  State<MeusBadgesView> createState() => _MeusBadgesViewState();
}

class _MeusBadgesViewState extends State<MeusBadgesView> {
  // Filtros
  final TextEditingController _pesquisaController = TextEditingController();
  String _servicoEscolhido = "Todas as Áreas";
  final List<String> _niveisSelecionados = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _todosNiveis = ['A', 'B', 'C', 'D', 'E'];

  // Dados Mockados
  final List<Map<String, dynamic>> _meusBadges = [
    {
      "id": 1,
      "titulo": "LowCode (Outsystems) - Nível A",
      "sl": "Hybrid Cloud",
      "nivel": "A",
      "data": "12/05/2025",
      "status": "Aprovado",
      "corStatus": Colors.green,
      "icone": Icons.auto_awesome
    },
    {
      "id": 2,
      "titulo": "DevOps Practices - Nível B",
      "sl": "DevOps",
      "nivel": "B",
      "data": "03/08/2025",
      "status": "Aprovado",
      "corStatus": Colors.green,
      "icone": Icons.cloud_sync
    },
  ];

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  void _alternarNivel(String nivel) {
    setState(() {
      _niveisSelecionados.contains(nivel)
          ? _niveisSelecionados.remove(nivel)
          : _niveisSelecionados.add(nivel);
    });
  }

  List<Map<String, dynamic>> _obterBadgesFiltrados() {
    return _meusBadges.where((badge) {
      bool textoMatch = _pesquisaController.text.isEmpty ||
          badge["titulo"]
              .toString()
              .toLowerCase()
              .contains(_pesquisaController.text.toLowerCase());
      bool slMatch = _servicoEscolhido == "Todas as Áreas" ||
          badge["sl"] == _servicoEscolhido;
      bool nivelMatch = _niveisSelecionados.contains(badge["nivel"]);
      return textoMatch && slMatch && nivelMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> badgesVisiveis = _obterBadgesFiltrados();

    return LayoutConsultor(
      corpo: Stack(
        children: [
          // Fundo dividido
          Column(
            children: [
              Expanded(child: Container(color: const Color(0xFF34659D))),
              Expanded(child: Container(color: const Color(0xFFF4F5F9))),
            ],
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // HEADER AZUL COM FILTROS
                Container(
                  color: const Color(0xFF34659D),
                  padding: const EdgeInsets.only(
                      top: 25, left: 20, right: 20, bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Os Meus Badges",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text("Consulte e partilhe as suas competências.",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 25),

                      // Filtro de Texto
                      TextField(
                        controller: _pesquisaController,
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Pesquisar nos meus badges...",
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF34659D)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Filtro de Área
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _servicoEscolhido,
                            isExpanded: true,
                            items: [
                              "Todas as Áreas",
                              "Hybrid Cloud",
                              "DevOps",
                              "Data & AI"
                            ]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _servicoEscolhido = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Filtro de Níveis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _todosNiveis.map((n) {
                          bool sel = _niveisSelecionados.contains(n);
                          return GestureDetector(
                            onTap: () => _alternarNivel(n),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? Colors.white : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Text(n,
                                  style: TextStyle(
                                      color: sel
                                          ? const Color(0xFF34659D)
                                          : Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // CORPO CINZA COM OS CARDS
                Container(
                  color: const Color(0xFFF4F5F9),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${badgesVisiveis.length} Badges Conquistados",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 15),
                      if (badgesVisiveis.isEmpty)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text("Nenhum badge encontrado.")))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: badgesVisiveis.length,
                          itemBuilder: (context, index) =>
                              _cardBadgeBonito(badgesVisiveis[index]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card redesenhado ao estilo do React
  Widget _cardBadgeBonito(Map<String, dynamic> badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Ícone gigante (Estilo Troféu do React)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFC0C0C0), width: 4),
                  ),
                  child: Icon(badge['icone'],
                      size: 40, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 15),
                Text(badge['titulo'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Área: ${badge['sl']}",
                    style:
                        const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/badge_detalhe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0980E9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Ver Detalhes do Badge",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // Rodapé do Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: badge['corStatus'], size: 10),
                const SizedBox(width: 8),
                Text("Status: ${badge['status']}",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
