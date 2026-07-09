import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/file_validator.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;

  // VARIÁVEIS DINÂMICAS
  int _badgesObtidos = 0;
  int _totalBadgesSL = 1;
  List<Map<String, dynamic>> _aprendizagensAtivas = [];
  
  int _pontosTotais = 0;
  int _pontosObtidosEstaSemana = 0;
  int _posicaoRanking = 0;
  int _totalConsultores = 0;

  double _meusPontosMedia = 0;
  double _mediaServiceLine = 0;
  double _mediaEmpresa = 0;

  List<Map<String, dynamic>> _pontosUltimos6Meses = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final dbHelper = BDLocalAjudante();
      final prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('idUtilizador') ?? 1;

      Map<String, dynamic> dados = await dbHelper.obterDadosDashboard(userId);
      List<Map<String, dynamic>> ativasDB = List<Map<String, dynamic>>.from(dados['aprendizagensAtivas']);
      
      // Buscar rascunhos locais nas SharedPreferences
      final chaves = prefs.getKeys().where((k) => k.startsWith('rascunho_candidatura_'));
      
      for (String chave in chaves) {
        int idBadge = int.parse(chave.replaceFirst('rascunho_candidatura_', ''));
        // Verifica se o badge já não está na lista 'ativasDB' (para não haver duplicados)
        if (!ativasDB.any((element) => element['idBadge'] == idBadge)) {
           // Obter info do badge para preencher a UI
           Map<String, dynamic>? detalheBadge = await dbHelper.obterBadgeDetalhe(idBadge, userId);
           if (detalheBadge != null) {
              List<String> rascunhos = prefs.getStringList(chave) ?? [];
              if (rascunhos.isNotEmpty) {
                  Set<String> requisitosMapeados = {};
                  List<dynamic> requisitosDoBadge = detalheBadge['requisitos'] ?? [];
                  
                  for (String rascunhoStr in rascunhos) {
                    final mapa = jsonDecode(rascunhoStr);
                    String nome = mapa['name'];
                    String? reqExtraid = FileValidator.extrairRequisitoDoNome(nome);
                    if (reqExtraid != null) {
                      for (var req in requisitosDoBadge) {
                        String idReq = req['titulo']?.toString() ?? req['id']?.toString() ?? '';
                        if (idReq.toUpperCase() == reqExtraid.toUpperCase()) {
                          requisitosMapeados.add(reqExtraid.toUpperCase());
                          break;
                        }
                      }
                    }
                  }

                  ativasDB.add({
                    "titulo": detalheBadge['nomeBadge'],
                    "sl": detalheBadge['serviceLine'],
                    "area": detalheBadge['area'],
                    "nivel": detalheBadge['nivel'],
                    "idBadge": idBadge,
                    "reqValidados": requisitosMapeados.length, 
                    "reqTotais": detalheBadge['requisitosTotal'] == 0 ? 1 : detalheBadge['requisitosTotal'],
                    "estado": "Rascunho",
                  });
              }
           }
        }
      }

      setState(() {
        _pontosTotais = dados['pontosTotais'];
        _badgesObtidos = dados['badgesObtidos'];
        _totalBadgesSL = dados['totalBadgesSL'] == 0 ? 1 : dados['totalBadgesSL'];
        _posicaoRanking = dados['posicaoRanking'];
        _totalConsultores = dados['totalConsultores'];
        _aprendizagensAtivas = ativasDB;
        _pontosObtidosEstaSemana = dados['pontosObtidosEstaSemana'];
        _meusPontosMedia = dados['meusPontosMedia'];
        _mediaServiceLine = dados['mediaServiceLine'];
        _mediaEmpresa = dados['mediaEmpresa'];
        if (dados.containsKey('pontosUltimos6Meses')) {
          _pontosUltimos6Meses = List<Map<String, dynamic>>.from(dados['pontosUltimos6Meses']);
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar dashboard dinâmico: \$e");
      setState(() => _isLoading = false);
    }
  }

  // Arredondar a percentagem do gráfico principal (Badges)
  int _calcularPercentagemGlobal() {
    if (_totalBadgesSL == 0) return 0;
    double calculo = (_badgesObtidos / _totalBadgesSL) * 100;
    return calculo.ceil();
  }

  // Arredondar a percentagem das aprendizagens (Requisitos)
  int _calcularPercentagemAtiva(int reqValidados, int reqTotais) {
    if (reqTotais == 0) return 0;
    double calculo = (reqValidados / reqTotais) * 100;
    return calculo.ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LayoutConsultor(
        indexMenuInferior: 0,
        corpo: const Center(child: CircularProgressIndicator(color: Color(0xFF34659D))),
      );
    }

    int percentagemGlobal = _calcularPercentagemGlobal();

    return LayoutConsultor(
      indexMenuInferior: 0,
      // Stack para resolver o bug de "bater no topo" (overscroll background)
      corpo: Stack(
        children: [
          // FUNDO DIVIDIDO PARA O OVERSCROLL: Metade azul, metade cinza
          Column(
            children: [
              Expanded(child: Container(color: const Color(0xFF34659D))),
              Expanded(child: Container(color: const Color(0xFFE9EEF2))),
            ],
          ),

          // CONTEÚDO SCROLLÁVEL
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 1. ÁREA DE PROGRESSO SUPERIOR (Fundo inteiramente azul)
                _construirHeaderProgresso(percentagemGlobal),

                // 2. CORPO DA PÁGINA (Com cantos arredondados no topo cortando o azul)
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    // Garante que o fundo cinza preenche sempre o resto do ecrã
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9EEF2), // Cinza do tema
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3. CARDS DE PERFORMANCE E RANKING (Tamanhos iguais usando IntrinsicHeight)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _construirCardInfo(
                                  "Performance Global",
                                  "Total de Pontos",
                                  _pontosTotais.toString(),
                                  "+$_pontosObtidosEstaSemana obtidos esta semana",
                                  Icons.insights,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _construirCardInfo(
                                  "Ranking Pessoal",
                                  "Lugar atual",
                                  "#$_posicaoRankingº lugar",
                                  "de $_totalConsultores consultores na empresa",
                                  Icons.emoji_events_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 4. APRENDIZAGENS ATIVAS (Requisitos)
                        _construirAprendizagensAtivasSecao(),

                        const SizedBox(height: 30),

                        // 5. GRÁFICO DE COMPARAÇÃO E HISTÓRICO
                        _construirSeccaoGrafico(),
                        const SizedBox(height: 30),
                        _construirGrafico6Meses(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para a secção azul superior
  Widget _construirHeaderProgresso(int percentagem) {
    return Container(
      width: double.infinity,
      // Sem border radius aqui. O recorte é feito pelo contentor cinzento que se sobrepõe
      padding: const EdgeInsets.only(top: 25, bottom: 45, left: 20, right: 20),
      color: const Color(0xFF34659D),
      child: Column(
        children: [
          const Text(
            "O Meu Percurso de Badges",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: percentagem / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$percentagem%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Conquistados",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Faltam completar ${(_totalBadgesSL - _badgesObtidos)} badges da sua Service Line!",
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  // Widget para os cards com tamanhos equivalentes
  Widget _construirCardInfo(
      String titulo, String sub, String valor, String footer, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Estica os elementos igualmente
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: const Color(0xFF34659D), size: 24),
              const SizedBox(height: 10),
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          const SizedBox(height: 10),
          Text(footer,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Widget para as Aprendizagens Ativas
  Widget _construirAprendizagensAtivasSecao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Aprendizagens Ativas",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 15),
        ..._aprendizagensAtivas.map((aprendizagem) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _construirCardAprendizagem(
                aprendizagem['titulo'],
                aprendizagem['sl'],
                aprendizagem['area'] ?? '',
                aprendizagem['nivel'] ?? '',
                aprendizagem['idBadge'],
                aprendizagem['reqValidados'],
                aprendizagem['reqTotais'],
                aprendizagem['estado'] ?? 'Rascunho'),
          );
        }).toList(),
      ],
    );
  }

  // Widget individual para cada Aprendizagem Ativa
  Widget _construirCardAprendizagem(
      String titulo, String sl, String area, String nivel, int idBadge, int reqValidados, int reqTotais, String estado) {
    int percentagemAtiva = _calcularPercentagemAtiva(reqValidados, reqTotais);

    return InkWell(
      onTap: () =>
          context.push('/candidatura?idBadge=$idBadge'), // Ir para as candidaturas ao clicar
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
          border: estado == 'Em Correção' 
              ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Ícone Esquerdo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_outlined,
                  color: Color(0xFF34659D), size: 28),
            ),
            const SizedBox(width: 15),

            // Informação Central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sl,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$area - $nivel",
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Texto de requisitos
                  Text(
                    estado == 'Em Correção' 
                        ? "Devolvido para Correção" 
                        : "$reqValidados de $reqTotais ficheiros carregados",
                    style: TextStyle(
                        fontSize: 11,
                        color: estado == 'Em Correção' ? Colors.orange : Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // Barra de progresso linear
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value:
                                reqTotais == 0 ? 0 : reqValidados / reqTotais,
                            backgroundColor: const Color(0xFFE9EEF2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                estado == 'Em Correção' ? Colors.orange : const Color(0xFF0980E9)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("$percentagemAtiva%",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: estado == 'Em Correção' ? Colors.orange : const Color(0xFF0980E9))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget para a área do gráfico de barras
  Widget _construirSeccaoGrafico() {
    double valorMaximo =
        [_meusPontosMedia, _mediaServiceLine, _mediaEmpresa].reduce(max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Comparação de Média",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          const Text("O Meu Ritmo vs Médias (Pontos)",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _barraGrafico(
                  "Eu", _meusPontosMedia, valorMaximo, const Color(0xFF0980E9)),
              _barraGrafico("Média SL", _mediaServiceLine, valorMaximo,
                  const Color(0xFF34659D)),
              _barraGrafico(
                  "Empresa", _mediaEmpresa, valorMaximo, Colors.grey.shade300),
            ],
          ),
        ],
      ),
    );
  }

  // Construtor de barras individuais para o gráfico
  Widget _barraGrafico(String label, double valor, double maximo, Color cor, {double larguraBarra = 40.0}) {
    double alturaMaximaGrafico = 150.0;
    if (maximo == 0) maximo = 1;
    double alturaCalculada = (valor / maximo) * alturaMaximaGrafico;

    return Column(
      children: [
        Text("${valor.toInt()} pts",
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Container(
          width: larguraBarra,
          height: alturaCalculada,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Gráfico de 6 Meses
  Widget _construirGrafico6Meses() {
    if (_pontosUltimos6Meses.isEmpty) return const SizedBox.shrink();
    
    double maxPontos = 1;
    for (var mes in _pontosUltimos6Meses) {
      if (mes['pontos'] > maxPontos) {
        maxPontos = mes['pontos'].toDouble();
      }
    }

    final mesesNomes = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Progresso Mensal",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          const Text("Pontos obtidos nos últimos 6 meses",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _pontosUltimos6Meses.map((mes) {
              return _barraGrafico(
                  mesesNomes[mes['mes'] - 1], 
                  mes['pontos'].toDouble(), 
                  maxPontos, 
                  const Color(0xFF0980E9),
                  larguraBarra: 25.0);
            }).toList().reversed.toList(),
          ),
        ],
      ),
    );
  }
}
