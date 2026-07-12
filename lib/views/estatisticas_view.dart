import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';

class EstatisticasView extends StatefulWidget {
  const EstatisticasView({super.key});

  @override
  State<EstatisticasView> createState() => _EstatisticasViewState();
}

class _EstatisticasViewState extends State<EstatisticasView> {
  bool _isLoading = true;
  double _meusPontos = 0;
  double _mediaSL = 0;
  double _mediaEmpresa = 0;
  int _posicaoRanking = 0;
  int _totalConsultores = 0;
  List<Map<String, dynamic>> _topRanking = [];

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final dados = await BDLocalAjudante().obterDadosDashboard(idUtilizador);
    final ranking = await BDLocalAjudante().obterRankingCompleto(idUtilizadorAtual: idUtilizador);
    if (!mounted) return;
    
    setState(() {
      _meusPontos = (dados['pontosTotais'] ?? 0).toDouble();
      _mediaSL = (dados['mediaServiceLine'] ?? 0).toDouble();
      _mediaEmpresa = (dados['mediaEmpresa'] ?? 0).toDouble();
      _posicaoRanking = dados['posicaoRanking'] ?? 0;
      _totalConsultores = dados['totalConsultores'] ?? 0;
      _topRanking = ranking.take(3).toList();
      _isLoading = false;
    });
  }

  // Cor dourada mais viva e vibrante
  final Color _douradoVivo = const Color(0xFFFFD500);

  @override
  Widget build(BuildContext context) {
    return LayoutConsultor(
      corpo: Stack(
        children: [
          // Fundo dividido para garantir que não há fundos brancos feios no overscroll
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
                // HEADER: PONTOS E RANKING (Cards Rápidos)
                // ==========================================
                Container(
                  width: double.infinity,
                  color: const Color(0xFF34659D),
                  padding: const EdgeInsets.only(
                      top: 25, left: 20, right: 20, bottom: 30),
                  child: Column(
                    children: [
                      const Text(
                        "O Seu Desempenho",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Acompanhe o seu progresso e posição atual.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 25),

                      // NOVA LÓGICA: Forçar a que ambos os cartões tenham a mesma altura
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cardDestaque("Pontos Acumulados",
                                _meusPontos.toInt().toString(), Icons.stars),
                            const SizedBox(width: 15),
                            _cardDestaque(
                                "Posição Ranking",
                                "$_posicaoRankingº / $_totalConsultores",
                                Icons.leaderboard),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // CORPO COM GRÁFICOS (Fundo Cinza)
                // ==========================================
                Container(
                  color: const Color(0xFFF4F5F9),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. GRÁFICO DE BARRAS
                      _seccaoTitulo("Comparação de Performance",
                          "Como se situa face aos seus colegas."),
                      const SizedBox(height: 15),
                      _construirGraficoBarras(),

                      const SizedBox(height: 40),

                      // 2. RADAR DE COMPETÊNCIAS
                      _seccaoTitulo("Distribuição de Competências",
                          "Áreas onde mais se destaca tecnicamente."),
                      const SizedBox(height: 15),
                      _construirVisualRadar(),

                      const SizedBox(height: 40),

                      // 3. RANKING TOP CONSULTORES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // CORREÇÃO: Colocámos o _seccaoTitulo dentro de um Expanded
                          Expanded(
                            child: _seccaoTitulo("Top Consultores SL",
                                "Os melhores da sua Service Line."),
                          ),
                          TextButton(
                              onPressed: () {},
                              child: const Text("Ver Tudo",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _listaRanking(),

                      const SizedBox(height: 40),

                      // BOTÃO EXPORTAÇÃO
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text("Exportar Relatório PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF34659D),
                            side: const BorderSide(color: Color(0xFF34659D)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
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

  // Cartão Destaque Atualizado com alinhamento dinâmico
  Widget _cardDestaque(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // Empurra o ícone para cima e o texto para baixo
          children: [
            Icon(icone,
                color: _douradoVivo,
                size: 28), // Ícone ligeiramente maior e mais vivo
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(titulo,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccaoTitulo(String titulo, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        Text(sub, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  // GRÁFICO DE BARRAS REESCRITO PARA NÃO TRANSBORDAR
  Widget _construirGraficoBarras() {
    double max = 5000;
    return Container(
      height: 250, // Aumentada a altura total da caixa para dar margem
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _barraUnica("Eu", _meusPontos, max, const Color(0xFF0980E9)),
          _barraUnica("Média SL", _mediaSL, max, const Color(0xFF34659D)),
          _barraUnica("Empresa", _mediaEmpresa, max, Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _barraUnica(String label, double valor, double max, Color cor) {
    // Reduzimos o teto da barra (agora 130) para garantir que há sempre espaço para o texto em cima e em baixo
    double altura = (valor / max) * 130;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("${valor.toInt()}",
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 5),
          Container(
            width: 40,
            height: altura,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _construirVisualRadar() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(
                4,
                (index) => Container(
                      width: (index + 1) * 45.0,
                      height: (index + 1) * 45.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                    )),
            const Icon(Icons.hub_outlined, color: Color(0xFF34659D), size: 40),
            const Positioned(
                top: 15,
                child: Text("Cloud",
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            const Positioned(
                bottom: 15,
                child: Text("Security",
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            const Positioned(
                right: 15,
                child: Text("LowCode",
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            const Positioned(
                left: 15,
                child: Text("Data&AI",
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _listaRanking() {
    if (_topRanking.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "Sem dados de ranking disponíveis.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _topRanking.asMap().entries
          .map((user) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02), blurRadius: 5)
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.key == 0
                        ? const Color(0xFFFFF7CC) // Fundo amarelo muito suave
                        : const Color(0xFFF4F5F9),
                    child: Text("${user.key + 1}º",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: user.key == 0
                                ? const Color(0xFFD48800) // Texto dourado forte
                                : Colors.black54)),
                  ),
                  title: Text(user.value['nome']?.toString() ?? 'Consultor',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: Text("${user.value['pontos'] ?? 0} pts",
                      style: const TextStyle(
                          color: Color(0xFF34659D),
                          fontWeight: FontWeight.bold)),
                ),
              ))
          .toList(),
    );
  }
}
