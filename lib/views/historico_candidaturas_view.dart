import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class HistoricoCandidaturasView extends StatefulWidget {
  const HistoricoCandidaturasView({super.key});

  @override
  State<HistoricoCandidaturasView> createState() =>
      _HistoricoCandidaturasViewState();
}

class _HistoricoCandidaturasViewState extends State<HistoricoCandidaturasView> {
  // Variáveis de estado para os filtros
  String _pesquisaTexto = "";
  String _filtroStatus =
      "Todos"; // Opções: Todos, Aprovados, Rejeitados, Em Análise

  // Simulação de Base de Dados (Vetores dinâmicos preparados para API futura)
  final List<Map<String, dynamic>> _listaCandidaturas = [
    {
      "id": 1,
      "sl": "Hybrid Cloud",
      "area": "LowCode (outsystems) - nível A",
      "status": "Aprovado",
      "data": "28/11/2025",
      "icone": Icons.cloud_done_outlined
    },
    {
      "id": 2,
      "sl": "Hybrid Cloud",
      "area": "LowCode (outsystems) - nível B",
      "status": "Rejeitado",
      "data": "25/11/2025",
      "icone": Icons.cloud_off_outlined
    },
    {
      "id": 3,
      "sl": "Hybrid Cloud",
      "area": "LowCode (outsystems) - nível C",
      "status": "Em Análise",
      "data": "25/11/2025",
      "icone": Icons.cloud_sync_outlined
    },
    {
      "id": 4,
      "sl": "Data & AI",
      "area": "Big Data Analytics - nível A",
      "status": "Aprovado",
      "data": "10/10/2025",
      "icone": Icons.data_usage
    },
    {
      "id": 5,
      "sl": "DevOps",
      "area": "CI/CD Pipelines - nível B",
      "status": "Em Análise",
      "data": "05/12/2025",
      "icone": Icons.all_inclusive
    },
  ];

  // Lógica para filtrar os dados da lista
  List<Map<String, dynamic>> _obterCandidaturasFiltradas() {
    return _listaCandidaturas.where((item) {
      // Filtro de Texto (Pesquisa)
      bool matchTexto = item['sl']
              .toString()
              .toLowerCase()
              .contains(_pesquisaTexto.toLowerCase()) ||
          item['area']
              .toString()
              .toLowerCase()
              .contains(_pesquisaTexto.toLowerCase());

      // Filtro de Status (Botões)
      bool matchStatus = true;
      if (_filtroStatus == "Aprovados") {
        matchStatus = item['status'] == "Aprovado";
      }
      if (_filtroStatus == "Rejeitados") {
        matchStatus = item['status'] == "Rejeitado";
      }
      if (_filtroStatus == "Em Análise") {
        matchStatus = item['status'] == "Em Análise";
      }

      return matchTexto && matchStatus;
    }).toList();
  }

  // Função auxiliar para determinar a cor do estado
  Color _obterCorStatus(String status) {
    if (status == "Aprovado") return Colors.green;
    if (status == "Rejeitado") return Colors.red;
    return Colors.orange; // Em Análise
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> candidaturasExibidas =
        _obterCandidaturasFiltradas();

    return LayoutConsultor(
      indexMenuInferior: 0,
      corpo: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // TÍTULO DA PÁGINA CENTRALIZADO
            const Center(
              child: Text(
                "Histórico completo de\ncandidaturas enviadas",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // BARRA DE PESQUISA
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                onChanged: (valor) {
                  setState(() {
                    _pesquisaTexto = valor;
                  });
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Pesquisar Pedido",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FILTRO (Scroll horizontal)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _construirChipFiltro("Todos"),
                  _construirChipFiltro("Aprovados"),
                  _construirChipFiltro("Rejeitados"),
                  _construirChipFiltro("Em Análise"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LISTA DE RESULTADOS
            Expanded(
              child: candidaturasExibidas.isEmpty
                  ? const Center(
                      child: Text(
                        "Nenhuma candidatura encontrada.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: candidaturasExibidas.length,
                      itemBuilder: (context, index) {
                        final item = candidaturasExibidas[index];
                        final corEstado = _obterCorStatus(item['status']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              context.push('/pedido_status');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // ÍCONE À ESQUERDA
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item['icone'],
                                      color: const Color(0xFF34659D),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // INFORMAÇÃO CENTRAL
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['sl'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['area'],
                                          style: const TextStyle(
                                            color: Color(0xFF34659D),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 3.0,
                                          children: [
                                            Text(
                                              item['status'],
                                              style: TextStyle(
                                                color: corEstado,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                            const Text(
                                              "•",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10),
                                            ),
                                            Text(
                                              "Ação: ${item['data']}",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // SETA DIREITA
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget construtor para os Filtros
  Widget _construirChipFiltro(String rotulo) {
    bool selecionado = _filtroStatus == rotulo;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroStatus = rotulo;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6), // Margem reduzida
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5), // Padding reduzido
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF34659D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? const Color(0xFF34659D) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.black87,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
            fontSize: 11, // Fonte compacta e ajustada
          ),
        ),
      ),
    );
  }
}
