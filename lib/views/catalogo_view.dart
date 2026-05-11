import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class CatalogoView extends StatefulWidget {
  const CatalogoView({super.key});

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  // Controladores e Filtros
  final TextEditingController _pesquisaController = TextEditingController();
  String _servicoEscolhido = "Todas as Service Lines";
  final List<String> _niveisSelecionados = [];
  final List<String> _todosNiveis = ['A', 'B', 'C', 'D', 'E'];

  // Dados Mockados - RECOMENDADOS PARA O CONSULTOR (Baseado no histórico)
  final List<Map<String, dynamic>> _badgesRecomendados = [
    {
      "id": 101,
      "titulo": "LowCode (Outsystems) - Nível B",
      "sl": "Hybrid Cloud",
      "pontos": 300,
      "icone": Icons.auto_awesome
    },
    {
      "id": 102,
      "titulo": "DevOps Practices - Nível C",
      "sl": "DevOps",
      "pontos": 500,
      "icone": Icons.cloud_sync
    },
    {
      "id": 103,
      "titulo": "Data Science - Nível A",
      "sl": "Data & AI",
      "pontos": 150,
      "icone": Icons.analytics
    },
  ];

  // Dados Mockados - TODOS OS BADGES (Simula a resposta da BD/API)
  final List<Map<String, dynamic>> _todosBadges = [
    {
      "id": 1,
      "titulo": "LowCode (Outsystems) - Nível A",
      "sl": "Hybrid Cloud",
      "nivel": "A",
      "pontos": 150,
      "icone": Icons.auto_awesome
    },
    {
      "id": 2,
      "titulo": "DevOps Practices - Nível B",
      "sl": "DevOps",
      "nivel": "B",
      "pontos": 300,
      "icone": Icons.cloud_sync
    },
    {
      "id": 3,
      "titulo": "Talent Sourcing - Nível A",
      "sl": "Talent Management",
      "nivel": "A",
      "pontos": 100,
      "icone": Icons.people_alt
    },
    {
      "id": 4,
      "titulo": "Data Science Foundations - Nível C",
      "sl": "Data & AI",
      "nivel": "C",
      "pontos": 500,
      "icone": Icons.analytics
    },
    {
      "id": 5,
      "titulo": "Cybersecurity Basics - Nível A",
      "sl": "Security",
      "nivel": "A",
      "pontos": 150,
      "icone": Icons.security
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

  // Lógica de filtragem combinada
  List<Map<String, dynamic>> _obterBadgesFiltrados() {
    return _todosBadges.where((badge) {
      bool textoMatch = _pesquisaController.text.isEmpty ||
          badge["titulo"]
              .toString()
              .toLowerCase()
              .contains(_pesquisaController.text.toLowerCase());

      bool slMatch = _servicoEscolhido == "Todas as Service Lines" ||
          badge["sl"] == _servicoEscolhido;

      bool nivelMatch = _niveisSelecionados.isEmpty ||
          _niveisSelecionados.contains(badge["nivel"]);

      return textoMatch && slMatch && nivelMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> badgesVisiveis = _obterBadgesFiltrados();

    return LayoutConsultor(
      indexMenuInferior: 1, // 1 = Catálogo
      corpo: Stack(
        children: [
          // Fundo fixo dividido para o overscroll (topo azul, fundo cinza)
          Column(
            children: [
              Expanded(child: Container(color: const Color(0xFF34659D))),
              Expanded(child: Container(color: const Color(0xFFF4F5F9))),
            ],
          ),

          // Conteúdo Principal Scrollável
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // ZONA AZUL SUPERIOR (Header + Recomendados)
                // ==========================================
                Container(
                  width: double.infinity,
                  color: const Color(0xFF34659D), // Fundo Azul garantido
                  padding: const EdgeInsets.only(top: 20, bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TEXTOS DO HEADER
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Catálogo de Badges",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Explore todas as competências e certificações disponíveis na Softinsa.",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.3),
                            ),
                            SizedBox(height: 30),
                            Text(
                              "Recomendados para si",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 15),
                          ],
                        ),
                      ),

                      // LISTA HORIZONTAL DE RECOMENDADOS
                      SizedBox(
                        height: 140, // Altura dos cards recomendados
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _badgesRecomendados.length,
                          itemBuilder: (context, index) {
                            var rec = _badgesRecomendados[index];
                            return GestureDetector(
                              onTap: () => context.push('/badge_detalhe'),
                              child: Container(
                                width: 220, // Largura de cada card
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              const Color(0xFFF4F5F9),
                                          radius: 20,
                                          child: Icon(rec['icone'],
                                              color: const Color(0xFF34659D),
                                              size: 20),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      rec['titulo'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${rec['pontos']} Pontos",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0980E9)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // ZONA CINZA INFERIOR (Filtros + Resultados)
                // ==========================================
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF4F5F9), // Fundo Cinza garantido
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pesquisa e Filtros",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 15),

                      // 1. Barra de Pesquisa (com fundo branco para destacar no cinza)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 5)
                          ],
                        ),
                        child: TextField(
                          controller: _pesquisaController,
                          onChanged: (value) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: "Pesquisar por badge...",
                            prefixIcon:
                                Icon(Icons.search, color: Color(0xFF34659D)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 2. Dropdown de Service Line
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _servicoEscolhido,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF34659D)),
                            items: [
                              "Todas as Service Lines",
                              "Hybrid Cloud",
                              "DevOps",
                              "Data & AI",
                              "Security",
                              "Talent Management"
                            ]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _servicoEscolhido = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Filtro por Níveis (Bolinhas)
                      const Text("Filtrar por Nível:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black54)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _todosNiveis.map((n) {
                          bool sel = _niveisSelecionados.contains(n);
                          return GestureDetector(
                            onTap: () => _alternarNivel(n),
                            child: Container(
                              width: 45,
                              height: 45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF34659D)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: sel
                                        ? const Color(0xFF34659D)
                                        : Colors.grey.shade300,
                                    width: 1.5),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: Colors.blue.withOpacity(0.2),
                                            blurRadius: 8)
                                      ]
                                    : null,
                              ),
                              child: Text(n,
                                  style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF34659D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 35),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: 25),

                      // TÍTULO RESULTADOS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Catálogo Completo",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A))),
                          Text("${badgesVisiveis.length} encontrados",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // LISTA DE BADGES
                      if (badgesVisiveis.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              "Nenhum badge corresponde à sua pesquisa.",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: badgesVisiveis.length,
                          itemBuilder: (context, index) {
                            var badge = badgesVisiveis[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10)
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE9EEF2),
                                  radius: 25,
                                  child: Icon(badge['icone'],
                                      color: const Color(0xFF34659D), size: 24),
                                ),
                                title: Text(
                                  badge['titulo'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Service Line: ${badge['sl']}\n${badge['pontos']} Pontos",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF34659D),
                                    size: 16,
                                  ),
                                ),
                                onTap: () {
                                  context.push('/badge_detalhe');
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
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
}
