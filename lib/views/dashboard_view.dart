import 'dart:math';
import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // DADOS DO GRÁFICO PRINCIPAL
  final int _badgesObtidos = 2;
  final int _totalBadgesSL = 10;

  // DADOS DAS APRENDIZAGENS ATIVAS
  final List<Map<String, dynamic>> _aprendizagensAtivas = [
    {
      "titulo": "LowCode (outsystems) - nível A",
      "sl": "Hybrid Cloud",
      "reqValidados": 2,
      "reqTotais": 3,
    },
    {
      "titulo": "DevOps Practices - nível B",
      "sl": "Cloud & DevOps",
      "reqValidados": 1,
      "reqTotais": 4,
    }
  ];

  // DADOS DE PERFORMANCE E RANKING
  final int _pontosTotais = 8000;
  final int _pontosObtidosEstaSemana = 20;
  final int _posicaoRanking = 12;
  final int _totalConsultores = 120;

  // DADOS DO GRÁFICO DE COMPARAÇÃO
  final double _meusPontosMedia = 350;
  final double _mediaServiceLine = 420;
  final double _mediaEmpresa = 380;

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
                                  "de $_totalConsultores consultores da sua Service Line",
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

                        // 5. GRÁFICO DE COMPARAÇÃO
                        _construirSeccaoGrafico(),
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
            "Faltam ${(_totalBadgesSL - _badgesObtidos)} badges para completar a sua Service Line!",
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
                aprendizagem['reqValidados'],
                aprendizagem['reqTotais']),
          );
        }).toList(),
      ],
    );
  }

  // Widget individual para cada Aprendizagem Ativa
  Widget _construirCardAprendizagem(
      String titulo, String sl, int reqValidados, int reqTotais) {
    int percentagemAtiva = _calcularPercentagemAtiva(reqValidados, reqTotais);

    return InkWell(
      onTap: () =>
          context.push('/candidatura'), // Ir para as candidaturas ao clicar
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
                    "Service Line: $sl",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),

                  // Texto de requisitos
                  Text(
                    "$reqValidados de $reqTotais requisitos validados",
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0980E9)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("$percentagemAtiva%",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0980E9))),
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
  Widget _barraGrafico(String label, double valor, double maximo, Color cor) {
    double alturaMaximaGrafico = 150.0;
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
          width: 40,
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
}
