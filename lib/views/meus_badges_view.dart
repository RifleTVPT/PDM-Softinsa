import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/imagem_badge_mobile.dart';

class MeusBadgesView extends StatefulWidget {
  const MeusBadgesView({super.key});

  @override
  State<MeusBadgesView> createState() => _MeusBadgesViewState();
}

class _MeusBadgesViewState extends State<MeusBadgesView> {
  // Filtros
  final TextEditingController _pesquisaController = TextEditingController();
  String _servicoEscolhido = "Todas as Service Lines";
  String _areaEscolhida = "Todas as Áreas";
  List<String> _niveisSelecionados = [];
  List<String> _todosNiveis = [];

  List<String> _todasServiceLines = ["Todas as Service Lines"];
  List<String> _todasAreas = ["Todas as Áreas"];

  List<Map<String, dynamic>> _todosBadgesGlobais = [];

  // Dados Dinâmicos
  bool _isLoading = true;
  List<Map<String, dynamic>> _meusBadges = [];
  int _idConsultor = -1;
  int _idUtilizador = -1;

  @override
  void initState() {
    super.initState();
    _carregarMeusBadges();
  }

  Future<void> _carregarMeusBadges() async {
    final bd = BDLocalAjudante();
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? -1;
    if (idUtilizador == -1) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final dados = await bd.obterMeusBadges(idUtilizador);
    final catalogo = await bd.obterCatalogo(idUtilizador);

    if (!mounted) return;

    setState(() {
      _idUtilizador = idUtilizador;
      _meusBadges = dados;
      if (dados.isNotEmpty) {
        _idConsultor = dados.first['idConsultor'] ?? -1;
      }

      // Armazenar os badges globais para construir os filtros com as mesmas opções do Catálogo
      _todosBadgesGlobais = List<Map<String, dynamic>>.from(catalogo['todos']);

      // Construir Service Lines com base no Catálogo GLOBAL
      _todasServiceLines = [
        "Todas as Service Lines",
        ..._todosBadgesGlobais.map((e) => e['sl'].toString()).toSet().toList()
          ..sort()
      ];

      _atualizarAreasPorSL("Todas as Service Lines");

      _isLoading = false;
    });
  }

  void _atualizarAreasPorSL(String sl) {
    _servicoEscolhido = sl;
    _areaEscolhida = "Todas as Áreas";
    if (sl == "Todas as Service Lines") {
      _todasAreas = [
        "Todas as Áreas",
        ..._todosBadgesGlobais.map((e) => e['area'].toString()).toSet()
      ];
    } else {
      _todasAreas = [
        "Todas as Áreas",
        ..._todosBadgesGlobais
            .where((e) => e['sl'] == sl)
            .map((e) => e['area'].toString())
            .toSet()
      ];
    }
    _atualizarNiveis();
  }

  void _atualizarNiveis() {
    var badges = _todosBadgesGlobais;
    if (_servicoEscolhido != "Todas as Service Lines") {
      badges = badges.where((e) => e['sl'] == _servicoEscolhido).toList();
    }
    if (_areaEscolhida != "Todas as Áreas") {
      badges = badges.where((e) => e['area'] == _areaEscolhida).toList();
    }
    _todosNiveis = badges.map((e) => e['nivel'].toString()).toSet().toList();
    _todosNiveis.sort();

    _niveisSelecionados.removeWhere((n) => !_todosNiveis.contains(n));
  }

  Future<void> _abrirGaleriaGlobal() async {
    if (_idUtilizador == -1) return;
    final url = Uri.parse(
        'https://softinsa-plataforma.onrender.com/galeria/$_idUtilizador');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir a galeria global.')),
        );
      }
    }
  }

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

  String _textoNivel(Map<String, dynamic> badge) {
    final letra = badge['nivel']?.toString() ?? '';
    final nome = badge['nomeNivel']?.toString() ?? 'Nível $letra';
    if (nome.contains('(')) return nome;
    return "$nome ($letra)";
  }

  List<Map<String, dynamic>> _obterBadgesFiltrados() {
    return _meusBadges.where((badge) {
      bool textoMatch = _pesquisaController.text.isEmpty ||
          badge["titulo"]
              .toString()
              .toLowerCase()
              .contains(_pesquisaController.text.toLowerCase());
      bool slMatch = _servicoEscolhido == "Todas as Service Lines" ||
          badge["sl"] == _servicoEscolhido;
      bool areaMatch =
          _areaEscolhida == "Todas as Áreas" || badge["area"] == _areaEscolhida;
      bool nivelMatch = _niveisSelecionados.isEmpty ||
          _niveisSelecionados.contains(badge["nivel"]);
      return textoMatch && slMatch && areaMatch && nivelMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LayoutConsultor(
        corpo: const Center(
            child: CircularProgressIndicator(color: Color(0xFF34659D))),
      );
    }

    // Safety checks para evitar crash no Dropdown devido ao Hot Reload (mantém o valor antigo)
    if (!_todasServiceLines.contains(_servicoEscolhido)) {
      _servicoEscolhido = _todasServiceLines.isNotEmpty
          ? _todasServiceLines.first
          : "Todas as Service Lines";
    }
    if (!_todasAreas.contains(_areaEscolhida)) {
      _areaEscolhida =
          _todasAreas.isNotEmpty ? _todasAreas.first : "Todas as Áreas";
    }

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
                // ==========================================
                // ZONA AZUL SUPERIOR (Filtros e Info)
                // ==========================================
                Container(
                  color: const Color(0xFF34659D),
                  padding: const EdgeInsets.only(
                      top: 25, left: 20, right: 20, bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: const Text("Os Meus Badges",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          if (_idConsultor != -1)
                            OutlinedButton.icon(
                              onPressed: _abrirGaleriaGlobal,
                              icon: const Icon(Icons.language,
                                  size: 14, color: Colors.white),
                              label: const Text("Ver Galeria",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                        ],
                      ),
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

                      // Filtros Lado a Lado (Service Line e Area) em Cascata
                      Row(
                        children: [
                          // Dropdown Service Line
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _servicoEscolhido,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      size: 18),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                  items: _todasServiceLines
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _servicoEscolhido = v!;
                                      _atualizarAreasPorSL(v);
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Dropdown Área
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _areaEscolhida,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      size: 18),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                  items: _todasAreas
                                      .map((a) => DropdownMenuItem(
                                            value: a,
                                            child: Text(a,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _areaEscolhida = v!;
                                      _atualizarNiveis();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filtro de Níveis
                      const Text("Filtrar por Nível:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white70)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _todosNiveis.map((n) {
                            bool sel = _niveisSelecionados.contains(n);
                            return GestureDetector(
                              onTap: () => _alternarNivel(n),
                              child: Container(
                                margin: const EdgeInsets.only(right: 15),
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
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // ZONA BRANCA INFERIOR (Resultados)
                // ==========================================
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
                        Border.all(color: const Color(0xFF34659D), width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 2)
                    ],
                  ),
                  child: ClipOval(
                    child: ImagemBadgeMobile(
                      urlImagem: badge['urlImagem']?.toString(),
                      tamanho: 80,
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text("Conquistado a ${_formatarData(badge['data'])}",
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
                _widgetExpiracao(badge),
                const SizedBox(height: 15),
                Text(badge['titulo'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text("${badge['sl']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34659D))),
                const SizedBox(height: 4),
                Text("${badge['area']}",
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 2),
                Text(_textoNivel(badge),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Requisitos e Pontos
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text("Requisitos",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("${badge['numeroRequisitos'] ?? 0}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.black12),
                      Column(
                        children: [
                          const Text("Pontos",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("${badge['pontos']}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4C51F7))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botão de Ver Detalhes
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/badge_detalhe',
                        extra: {'idBadge': badge['id'], 'from': 'meus_badges'}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0980E9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text("Ver Detalhes do Badge",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return "N/D";
    try {
      DateTime data = DateTime.parse(dataIso);
      return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
    } catch (e) {
      return dataIso;
    }
  }

  Widget _widgetExpiracao(Map<String, dynamic> badge) {
    if (badge['validadeMeses'] == null || badge['validadeMeses'] == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: 5),
        child: Text("Sem expiração",
            style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.bold)),
      );
    }

    if (badge['dataExpiracao'] != null) {
      try {
        DateTime expiracao = DateTime.parse(badge['dataExpiracao']);
        int dias = (expiracao.difference(DateTime.now()).inMilliseconds /
                Duration.millisecondsPerDay)
            .ceil();

        if (dias < 0) {
          return const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text("Expirado",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          );
        } else if (dias < 30) {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text("Expira em $dias dias",
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold)),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text("Expira em $dias dias",
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
          );
        }
      } catch (e) {
        return const SizedBox();
      }
    }
    return const SizedBox();
  }
}
