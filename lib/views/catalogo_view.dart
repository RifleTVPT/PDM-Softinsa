import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';

class CatalogoView extends StatefulWidget {
  const CatalogoView({super.key});

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  bool _isLoading = true;

  // Controladores e Filtros
  final TextEditingController _pesquisaController = TextEditingController();
  String _servicoEscolhido = "Todas as Service Lines";
  List<String> _todasServiceLines = ["Todas as Service Lines"];
  String _areaEscolhida = "Todas as Áreas";
  List<String> _todasAreas = ["Todas as Áreas"];
  final List<String> _niveisSelecionados = [];
  List<String> _todosNiveis = [];

  // Dados Dinâmicos
  List<Map<String, dynamic>> _badgesRecomendados = [];
  List<Map<String, dynamic>> _todosBadges = [];

  @override
  void initState() {
    super.initState();
    _carregarCatalogo();
  }

  Future<void> _carregarCatalogo() async {
    try {
      final dbHelper = BDLocalAjudante();
      final users = await dbHelper.listar('UTILIZADOR');
      int userId = 1; // Fallback
      if (users.isNotEmpty) {
        userId = users.first['ID_UTILIZADOR'] as int;
      }

      Map<String, dynamic> dados = await dbHelper.obterCatalogo(userId);

      setState(() {
        _todosBadges = List<Map<String, dynamic>>.from(dados['todos']);
        _badgesRecomendados = List<Map<String, dynamic>>.from(dados['recomendados']);
        
        // Mapear icones dinamicamente para não alterar o design da UI
        for (var b in _todosBadges) {
          b['icone'] = _obterIconePorArea(b['sl']);
        }
        for (var b in _badgesRecomendados) {
          b['icone'] = _obterIconePorArea(b['sl']);
        }
        // Extrair SLs, Areas e Niveis disponiveis
        _todasServiceLines = ["Todas as Service Lines", ..._todosBadges.map((e) => e['sl'].toString()).toSet().toList()..sort()];
        _atualizarAreasPorSL("Todas as Service Lines");
        
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar catálogo: \$e");
      setState(() => _isLoading = false);
    }
  }

  void _atualizarAreasPorSL(String sl) {
    _servicoEscolhido = sl;
    _areaEscolhida = "Todas as Áreas";
    if (sl == "Todas as Service Lines") {
      _todasAreas = ["Todas as Áreas", ..._todosBadges.map((e) => e['area'].toString()).toSet()];
    } else {
      _todasAreas = ["Todas as Áreas", ..._todosBadges.where((e) => e['sl'] == sl).map((e) => e['area'].toString()).toSet()];
    }
    _atualizarNiveis();
  }

  void _atualizarNiveis() {
    var badges = _todosBadges;
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

  IconData _obterIconePorArea(String area) {
    String a = area.toLowerCase();
    if (a.contains('devops')) return Icons.cloud_sync;
    if (a.contains('data') || a.contains('ai')) return Icons.analytics;
    if (a.contains('security')) return Icons.security;
    if (a.contains('talent')) return Icons.people_alt;
    return Icons.auto_awesome; // Default (Hybrid Cloud, etc)
  }

  Widget _construirImagemBadge(String? urlImagem, IconData iconeFallback, double raio) {
    if (urlImagem != null && urlImagem.isNotEmpty) {
      // Assuming network URL for now, could be local asset if no network but this mimics Web
      if (urlImagem.startsWith('http')) {
        return CircleAvatar(
          backgroundColor: const Color(0xFFF4F5F9),
          radius: raio,
          backgroundImage: NetworkImage(urlImagem),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      } else {
        return CircleAvatar(
          backgroundColor: const Color(0xFFF4F5F9),
          radius: raio,
          backgroundImage: AssetImage('assets/images/$urlImagem'),
          onBackgroundImageError: (_, __) {},
        );
      }
    }
    
    return CircleAvatar(
      backgroundColor: const Color(0xFFF4F5F9),
      radius: raio,
      child: Icon(iconeFallback, color: const Color(0xFF34659D), size: raio),
    );
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

      bool areaMatch = _areaEscolhida == "Todas as Áreas" ||
          badge["area"] == _areaEscolhida;

      bool nivelMatch = _niveisSelecionados.isEmpty ||
          _niveisSelecionados.contains(badge["nivel"]);

      return textoMatch && slMatch && areaMatch && nivelMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LayoutConsultor(
        indexMenuInferior: 1,
        corpo: const Center(child: CircularProgressIndicator(color: Color(0xFF34659D))),
      );
    }

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
                        height: 180, // Aumentado para evitar overflow
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _badgesRecomendados.length,
                          itemBuilder: (context, index) {
                            var rec = _badgesRecomendados[index];
                            return GestureDetector(
                              onTap: () => context.push('/badge_detalhe', extra: {'idBadge': rec['id'], 'from': 'catalogo'}),
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
                                        _construirImagemBadge(rec['urlImagem'], rec['icone'], 20),
                                        const Spacer(),
                                        const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      rec['titulo'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rec['sl'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF34659D), // Azul Softinsa
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${rec['area']} - ${rec['nivel']}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.bold),
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
                            items: _todasServiceLines
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _atualizarAreasPorSL(v!);
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Dropdown de Área
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
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFF34659D)),
                            items: _todasAreas
                                .map((a) =>
                                    DropdownMenuItem(value: a, child: Text(a)))
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
                      const SizedBox(height: 20),

                      // 3. Filtro por Níveis (Bolinhas)
                      const Text("Filtrar por Nível:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black54)),
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
                            return GestureDetector(
                              onTap: () {
                                context.push('/badge_detalhe', extra: {'idBadge': badge['id'], 'from': 'catalogo'});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5))
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Imagem com anel azul
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF4C51F7), width: 2), // Azul estilo Web
                                      ),
                                      child: _construirImagemBadge(badge['urlImagem'], badge['icone'], 35),
                                    ),
                                    const SizedBox(height: 15),
                                    
                                    // Título
                                    Text(
                                      badge['titulo'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Service Line
                                    Text(
                                      "Service Line ${badge['sl']}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4C51F7)),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Área e Nível
                                    Text(
                                      "Área de ${badge['area']} - Nível ${badge['nivel']}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF555555)),
                                    ),
                                    const SizedBox(height: 15),
                                    
                                    // Caixas de Requisitos e Pontos
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text("Requisitos", style: TextStyle(fontSize: 10, color: Colors.black54)),
                                              const SizedBox(height: 2),
                                              Text("${badge['numeroRequisitos']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF0FF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text("Pontos", style: TextStyle(fontSize: 10, color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Text("${badge['pontos']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4C51F7))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Botões
                                    SizedBox(
                                      width: double.infinity,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (badge['obtido'] == true) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text("Já obteve este Badge"),
                                                  content: const Text("Este badge já faz parte do seu perfil."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(); // Close dialog
                                                      },
                                                      child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(); // Close dialog
                                                        context.push('/badge_detalhe', extra: {'idBadge': badge['id'], 'from': 'catalogo'});
                                                      },
                                                      child: const Text("Ver Registo de Obtenção", style: TextStyle(color: Color(0xFF0980E9), fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            context.push('/candidatura', extra: {'idBadgeSelecionado': badge['id']});
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4C51F7),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                          elevation: 0,
                                        ),
                                        child: const Text("+ Candidatar-me", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 45,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          context.push('/badge_detalhe', extra: {'idBadge': badge['id'], 'from': 'catalogo'});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.black45),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                        ),
                                        child: const Text("Ver Detalhes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
                                      ),
                                    ),
                                  ],
                                ),
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
