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
  final int _totalBadgesSL = 8; // Ajustado para 8 para dar exatos 25%

  // DADOS DAS APRENDIZAGENS ATIVAS
  final List<Map<String, dynamic>> _aprendizagensAtivas = [
    {
      "titulo": "LowCode (Outsystems) - Nível A",
      "sl": "Hybrid Cloud",
      "reqValidados": 4,
      "reqTotais": 5,
    },
    {
      "titulo": "LowCode (Outsystems) - Nível B",
      "sl": "Hybrid Cloud",
      "reqValidados": 1,
      "reqTotais": 5,
    },
  ];

  // DADOS DE PERFORMANCE
  final int _pontosTotais = 8000;
  final int _badgesTotaisCard = 50;

  // DADOS DO GRÁFICO DE COMPARAÇÃO (Mantidos para a funcionalidade inferior)
  final double _meusPontosMedia = 350;
  final double _mediaServiceLine = 420;
  final double _mediaEmpresa = 380;

  int _calcularPercentagemGlobal() {
    if (_totalBadgesSL == 0) return 0;
    return ((_badgesObtidos / _totalBadgesSL) * 100).ceil();
  }

  int _calcularPercentagemAtiva(int reqValidados, int reqTotais) {
    if (reqTotais == 0) return 0;
    return ((reqValidados / reqTotais) * 100).ceil();
  }

  @override
  Widget build(BuildContext context) {
    int percentagemGlobal = _calcularPercentagemGlobal();

    // O LayoutConsultor já traz a AppBar com o Drawer (3 traços) e ícones a funcionar.
    return LayoutConsultor(
      indexMenuInferior: 0,
      corpo: Container(
        color: const Color(0xFFF5F7FA), // Fundo cinza da imagem
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Centraliza textos do topo
            children: [
              const Text(
                "Olá, Consultor!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "O meu progresso Geral",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Gráfico Circular Central (25%) idêntico à imagem
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: percentagemGlobal / 100,
                      strokeWidth: 14,
                      backgroundColor: Colors.grey[300],
                      color: const Color(0xFF0980E9), // Azul vivo da barra
                    ),
                  ),
                  Text(
                    "$percentagemGlobal%",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "dos Badges da sua\nService Line completos",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 35),

              // 3 Cartões Pequenos (Pontos, Badges, Expirar)
              Row(
                children: [
                  _buildSmallCard("Total de Pontos", _pontosTotais.toString()),
                  const SizedBox(width: 8),
                  _buildSmallCard(
                    "Badges Obtidos",
                    _badgesTotaisCard.toString(),
                  ),
                  const SizedBox(width: 8),
                  _buildSmallAlertCard(
                    "Próximo Expirar",
                    "LowCode - Nível B\n25 dias",
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Secção: Aprendizagens Ativas
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Aprendizagens ativas",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ..._aprendizagensAtivas.map((aprendizagem) {
                return _construirCardAprendizagem(
                  aprendizagem['titulo'],
                  aprendizagem['sl'],
                  aprendizagem['reqValidados'],
                  aprendizagem['reqTotais'],
                );
              }),

              const SizedBox(height: 30),

              // Gráfico de Barras mantido para preservar a funcionalidade
              _construirSeccaoGrafico(),
            ],
          ),
        ),
      ),
    );
  }

  // NOVO WIDGET: Cartões brancos de estatísticas
  Widget _buildSmallCard(String title, String value) {
    return Expanded(
      child: Container(
        height: 75,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO WIDGET: Cartão de Alerta (Próximo Expirar)
  Widget _buildSmallAlertCard(String title, String subtitle) {
    return Expanded(
      child: Container(
        height: 75,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ATUALIZADO: Card das aprendizagens para espelhar a imagem
  Widget _construirCardAprendizagem(
    String titulo,
    String sl,
    int validados,
    int totais,
  ) {
    int percentagemAtiva = _calcularPercentagemAtiva(validados, totais);

    return InkWell(
      onTap: () => context.push('/candidatura'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Ícone com contorno circular da imagem
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sl,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: totais == 0 ? 0 : validados / totais,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF0980E9),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "$percentagemAtiva%",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0980E9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MANTIDO: Gráfico de comparação para não quebrar o código anterior
  Widget _construirSeccaoGrafico() {
    double valorMaximo = [
      _meusPontosMedia,
      _mediaServiceLine,
      _mediaEmpresa,
    ].reduce(max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comparação de Média",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            "O Meu Ritmo vs Médias (Pontos)",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _barraGrafico(
                "Eu",
                _meusPontosMedia,
                valorMaximo,
                const Color(0xFF0980E9),
              ),
              _barraGrafico(
                "Média SL",
                _mediaServiceLine,
                valorMaximo,
                const Color(0xFF1A468D),
              ),
              _barraGrafico(
                "Empresa",
                _mediaEmpresa,
                valorMaximo,
                Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barraGrafico(String label, double valor, double maximo, Color cor) {
    double alturaCalculada = (valor / maximo) * 100.0;

    return Column(
      children: [
        Text(
          "${valor.toInt()} pts",
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: 35,
          height: alturaCalculada,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
