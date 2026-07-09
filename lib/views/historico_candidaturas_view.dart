import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoCandidaturasView extends StatefulWidget {
  const HistoricoCandidaturasView({super.key});

  @override
  State<HistoricoCandidaturasView> createState() =>
      _HistoricoCandidaturasViewState();
}

class _HistoricoCandidaturasViewState extends State<HistoricoCandidaturasView> {
  // Variáveis de estado
  String _filtroStatus = "Todos os Status";
  String _servicoEscolhido = "Todas as Service Lines";
  String _areaEscolhida = "Todas as Áreas";
  String _periodoEscolhido = "Sempre";
  
  List<String> _todasServiceLines = ["Todas as Service Lines"];
  List<String> _todasAreas = ["Todas as Áreas"];
  List<String> _niveisAtivos = [];
  List<String> _niveisSelecionados = [];

  bool _isLoading = true;
  List<Map<String, dynamic>> _listaCandidaturas = [];
  List<Map<String, dynamic>> _todosBadgesGlobais = [];
  dynamic estruturaGlobal;

  final List<String> _listaStatusWeb = [
    "Todos os Status",
    "Em Preenchimento",
    "Análise Talent",
    "Análise SLL",
    "Aceite (Aprovado)",
    "Pendente Correção",
    "Recusado"
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosHistorico();
  }

  void _atualizarNiveisDinamicos() {
    List<Map<String, dynamic>> badges = _todosBadgesGlobais;
    if (_servicoEscolhido != "Todas as Service Lines") {
      badges = badges.where((e) => e['sl'] == _servicoEscolhido).toList();
    }
    if (_areaEscolhida != "Todas as Áreas") {
      badges = badges.where((e) => e['area'] == _areaEscolhida).toList();
    }
    
    final todasL = badges.map((e) => e['nivel'].toString()).toSet().toList();
    todasL.sort();
    
    // Niveis Globais Base baseados na Area
    List<String> niveisParaRenderizar = [];
    if (_areaEscolhida != "Todas as Áreas" && estruturaGlobal != null) {
      final a = estruturaGlobal.areas?.firstWhere((element) => element.nome == _areaEscolhida, orElse: () => null);
      if (a != null && a.niveisAtivos != null) {
        final ativos = a.niveisAtivos.toString().split(' ').where((x) => x.isNotEmpty).toList();
        for (int i = 0; i < ativos.length; i++) {
           niveisParaRenderizar.add(String.fromCharCode(65 + i)); // A, B, C...
        }
      }
    }

    if (niveisParaRenderizar.isEmpty) {
      niveisParaRenderizar = todasL.map((nivel) {
        if (nivel.startsWith('Nível ')) return nivel.replaceFirst('Nível ', '').trim();
        if (nivel.length == 1) return nivel;
        return nivel;
      }).toList();
    }

    setState(() {
      _niveisAtivos = niveisParaRenderizar.toSet().toList()..sort();
      _niveisSelecionados.removeWhere((n) => !_niveisAtivos.contains(n));
    });
  }

  void _atualizarAreasPorSL(String sl) {
    setState(() {
      _servicoEscolhido = sl;
      _areaEscolhida = "Todas as Áreas";
      if (sl == "Todas as Service Lines") {
        _todasAreas = ["Todas as Áreas", ..._todosBadgesGlobais.map((e) => e['area'].toString()).toSet()];
      } else {
        _todasAreas = ["Todas as Áreas", ..._todosBadgesGlobais.where((e) => e['sl'] == sl).map((e) => e['area'].toString()).toSet()];
      }
      _todasAreas.sort();
      _atualizarNiveisDinamicos();
    });
  }

  void _atualizarSLPorArea(String area) {
    setState(() {
      _areaEscolhida = area;
      _atualizarNiveisDinamicos();
    });
  }

  void _alternarNivel(String nivel) {
    setState(() {
      _niveisSelecionados.contains(nivel)
          ? _niveisSelecionados.remove(nivel)
          : _niveisSelecionados.add(nivel);
    });
  }

  Future<void> _carregarDadosHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador');
    if (idUtilizador == null) return;

    final bd = BDLocalAjudante();
    
    final dadosH = await bd.obterHistoricoCandidaturas(idUtilizador);
    for (var d in dadosH) {
      if (d['status'] == 'Rascunho') d['status'] = 'Em Preenchimento';
      else if (d['status'] == 'Pendente' || d['status'] == 'Em Análise TM') d['status'] = 'Análise Talent';
      else if (d['status'] == 'Em Análise SLL') d['status'] = 'Análise SLL';
      else if (d['status'] == 'Pendente de Correção' || d['status'] == 'Em Correção') d['status'] = 'Pendente Correção';
    }
    final dadosC = await bd.obterCatalogo(idUtilizador);

    if (!mounted) return;
    setState(() {
      _listaCandidaturas = dadosH;
      _todosBadgesGlobais = List<Map<String, dynamic>>.from(dadosC['todos']);
      
      _todasServiceLines = ["Todas as Service Lines", ..._todosBadgesGlobais.map((e) => e['sl'].toString()).toSet().toList()..sort()];
      _atualizarAreasPorSL("Todas as Service Lines");
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _obterCandidaturasFiltradas() {
    DateTime now = DateTime.now();
    return _listaCandidaturas.where((item) {
      // Filtro Cascata
      bool slMatch = _servicoEscolhido == "Todas as Service Lines" || item["sl"] == _servicoEscolhido;
      bool areaMatch = _areaEscolhida == "Todas as Áreas" || item["area"] == _areaEscolhida;

      // Filtro Nível
      bool nivelMatch = true;
      if (_niveisSelecionados.isNotEmpty) {
        String nivelRaw = item["nivel"]?.toString() ?? "";
        String letra = "";
        if (nivelRaw.startsWith('Nível ')) letra = nivelRaw.replaceFirst('Nível ', '').trim();
        else if (nivelRaw.length == 1) letra = nivelRaw;
        else letra = nivelRaw.split(' ').first;
        
        nivelMatch = _niveisSelecionados.contains(letra);
      }

      // Filtro Status
      bool matchStatus = true;
      String st = item['status'].toString();
      if (_filtroStatus != "Todos os Status") {
        if (_filtroStatus == "Em Preenchimento") matchStatus = st == "Em Preenchimento";
        else if (_filtroStatus == "Análise Talent") matchStatus = st == "Análise Talent";
        else if (_filtroStatus == "Análise SLL") matchStatus = st == "Análise SLL";
        else if (_filtroStatus == "Aceite (Aprovado)") matchStatus = st == "Aceite" || st == "Aprovado";
        else if (_filtroStatus == "Pendente Correção") matchStatus = st == "Pendente Correção" || st == "Devolvido";
        else if (_filtroStatus == "Recusado") matchStatus = st == "Recusado" || st == "Rejeitado";
        else matchStatus = false;
      }

      // Filtro Periodo
      bool matchPeriodo = true;
      if (_periodoEscolhido != "Sempre" && item['data_submissao'] != null) {
        try {
          DateTime dt = DateTime.parse(item['data_submissao']);
          int diff = now.difference(dt).inDays;
          if (_periodoEscolhido == "Últimos 7 dias") matchPeriodo = diff <= 7;
          if (_periodoEscolhido == "Últimos 30 dias") matchPeriodo = diff <= 30;
          if (_periodoEscolhido == "Últimos 90 dias") matchPeriodo = diff <= 90;
          if (_periodoEscolhido == "Último Ano") matchPeriodo = diff <= 365;
        } catch (e) {
          matchPeriodo = true;
        }
      }

      return slMatch && areaMatch && nivelMatch && matchStatus && matchPeriodo;
    }).toList();
  }

  String _formatarDataStr(String? dataIso) {
    if (dataIso == null) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dataIso);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dataIso.split('T')[0];
    }
  }

  // Função auxiliar para determinar a cor do estado
  Color _obterCorStatus(String status) {
    if (status == "Aceite" || status == "Aprovado") return Colors.green;
    if (status == "Recusado" || status == "Rejeitado") return Colors.red;
    if (status == "Pendente Correção" || status == "Devolvido" || status == "Em Correção") return Colors.amber.shade700;
    if (status == "Em Preenchimento" || status == "Rascunho") return Colors.grey;
    return Colors.lightBlue; // Análise Talent e Análise SLL
  }

  IconData _obterIconePorArea(String area) {
    String a = area.toLowerCase();
    if (a.contains('devops')) return Icons.cloud_sync;
    if (a.contains('data') || a.contains('ai')) return Icons.analytics;
    if (a.contains('security')) return Icons.security;
    if (a.contains('talent')) return Icons.people_alt;
    return Icons.auto_awesome; // Default
  }

  Widget _construirImagemBadge(String? urlImagem, IconData iconeFallback, double raio) {
    if (urlImagem != null && urlImagem.isNotEmpty) {
      if (urlImagem.startsWith('http')) {
        return CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: raio,
          backgroundImage: NetworkImage(urlImagem),
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    return Icon(iconeFallback, color: const Color(0xFF34659D), size: raio * 1.5);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> candidaturasExibidas =
        _obterCandidaturasFiltradas();

    return LayoutConsultor(
      indexMenuInferior: 0,
      corpo: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // TÍTULO DA PÁGINA
              const Text(
                "Histórico de Candidaturas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),

              // SECÇÃO DE FILTROS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9), // Fundo suave para filtros
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pesquisa e Filtros", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 15),

                    // PERIODO
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _periodoEscolhido,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF34659D)),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          items: ["Sempre", "Últimos 7 dias", "Últimos 30 dias", "Últimos 90 dias", "Último Ano"]
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _periodoEscolhido = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // SERVICE LINE
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
                          menuMaxHeight: 300,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF34659D)),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          items: _todasServiceLines
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => _atualizarAreasPorSL(v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // AREA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _areaEscolhida,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF34659D)),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          items: _todasAreas
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => _atualizarSLPorArea(v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // NÍVEIS DE COMPETÊNCIA
                    const Text("Filtrar por Nível:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _niveisAtivos.map((n) {
                          bool sel = _niveisSelecionados.contains(n);
                          return GestureDetector(
                            onTap: () => _alternarNivel(n),
                            child: Container(
                              margin: const EdgeInsets.only(right: 15),
                              width: 45,
                              height: 45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFF34659D) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: sel ? const Color(0xFF34659D) : Colors.grey.shade300, width: 1.5),
                              ),
                              child: Text(n, style: TextStyle(color: sel ? Colors.white : const Color(0xFF34659D), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FILTRO STATUS (Scroll horizontal)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _listaStatusWeb.map((st) => _construirChipFiltro(st)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // LISTA DE RESULTADOS
              candidaturasExibidas.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "Nenhuma candidatura encontrada.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                              context.push('/pedido_status', extra: {'idPedido': item['id']});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: _construirImagemBadge(item['icone'], _obterIconePorArea(item['sl']), 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['titulo'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item['sl'],
                                              style: const TextStyle(
                                                color: Color(0xFF34659D), // Dark Blue for Service Line
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${item['area']} - Nível ${item['nivel']}",
                                              style: const TextStyle(
                                                color: Color(0xFF0980E9), // Light Blue for Area
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  const Divider(height: 1),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Submissão", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text(_formatarDataStr(item['data_submissao'] ?? item['data']), style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text("Última Ação", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text(_formatarDataStr(item['data_acao'] ?? item['data']), style: const TextStyle(fontSize: 11)),
                                        ],
                                      ),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: corEstado.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            item['status'],
                                            style: TextStyle(
                                              color: corEstado,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Ver Detalhes", style: TextStyle(color: Color(0xFF34659D), fontWeight: FontWeight.bold, fontSize: 12)),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right, color: Color(0xFF34659D), size: 16),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
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
