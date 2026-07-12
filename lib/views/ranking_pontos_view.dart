import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import '../services/api_servico.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RankingPontosView extends StatefulWidget {
  const RankingPontosView({super.key});

  @override
  State<RankingPontosView> createState() => _RankingPontosViewState();
}

class _RankingPontosViewState extends State<RankingPontosView> {
  bool _isLoading = true;
  int _idUtilizador = -1;
  String _nomeCompleto = "Consultor";
  Map<String, dynamic>? _estatisticas;
  List<Map<String, dynamic>> _rankingCompleto = [];
  bool _verTudo = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    _idUtilizador = prefs.getInt('idUtilizador') ?? 1;
    _nomeCompleto = prefs.getString('nomeCompleto') ?? 'Consultor';

    Map<String, dynamic>? stats = await ApiServico().fetchEstatisticasConsultor(_idUtilizador);
    
    if (stats == null) {
      final bd = BDLocalAjudante();
      stats = await bd.obterEstatisticasConsultor(_idUtilizador);
    }

    if (!mounted) return;
    setState(() {
      _estatisticas = stats;
      _rankingCompleto = List<Map<String, dynamic>>.from(stats!['rankingCompleto'] ?? []);
      _isLoading = false;
    });
  }

  // EXPORTAR PARA PDF (TABULAR)
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Relatório de Estatísticas - $_nomeCompleto', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Gerado em: ${DateTime.now().toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Text('Classificação Atual: ${_estatisticas!['kpis']['ranking']} de ${_estatisticas!['kpis']['totalConsultores']}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Total de Pontos: ${_estatisticas!['kpis']['pontos']}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Catálogo concluído: ${_estatisticas!['kpis']['percentagemBadges']}%', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              pw.Text('Evolução Mensal', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Mês', 'Pontos Acumulados'],
                data: List<List<String>>.generate(
                  _estatisticas!['graficoLinha']['labels'].length,
                  (index) => [
                    _estatisticas!['graficoLinha']['labels'][index],
                    _estatisticas!['graficoLinha']['data'][index].toString()
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Evolução do Número de Badges', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Mês', 'Badges Normais', 'Badges Especiais'],
                data: List<List<String>>.generate(
                  _estatisticas!['graficoBarras']['labels'].length,
                  (index) => [
                    _estatisticas!['graficoBarras']['labels'][index].toString(),
                    _estatisticas!['graficoBarras']['normais'][index].toString(),
                    _estatisticas!['graficoBarras']['especiais'][index].toString(),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Ranking Completo', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Posição', 'Nome', 'Service Line', 'Área', 'Pontos', 'Badges'],
                data: _rankingCompleto.map((r) => [
                  '${r['pos']}',
                  '${r['nome']}',
                  '${r['serviceLine']}',
                  '${r['area']}',
                  '${r['pontos']}',
                  '${r['badges']}',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Estatisticas_$_nomeCompleto.pdf');
      await file.writeAsBytes(await pdf.save());
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Gerado com Sucesso! A abrir...')));
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar PDF: $e')));
    }
  }

  // EXPORTAR PARA EXCEL
  Future<void> _exportarExcel() async {
    var excel = ex.Excel.createExcel();
    
    // Folha 1: Resumo
    ex.Sheet sheetResumo = excel['Resumo'];
    sheetResumo.appendRow([ex.TextCellValue('KPI'), ex.TextCellValue('Valor')]);
    sheetResumo.appendRow([ex.TextCellValue('Ranking Pessoal'), ex.IntCellValue(_estatisticas!['kpis']['ranking'])]);
    sheetResumo.appendRow([ex.TextCellValue('Total de Consultores'), ex.IntCellValue(_estatisticas!['kpis']['totalConsultores'])]);
    sheetResumo.appendRow([ex.TextCellValue('Total de Pontos'), ex.IntCellValue(_estatisticas!['kpis']['pontos'])]);
    sheetResumo.appendRow([ex.TextCellValue('Crescimento vs. Mês Passado (%)'), ex.TextCellValue(_estatisticas!['kpis']['crescimentoPontos'].toString())]);
    sheetResumo.appendRow([ex.TextCellValue('Catálogo Concluído (%)'), ex.IntCellValue(_estatisticas!['kpis']['percentagemBadges'])]);

    // Folha 2: Pontos Mensais
    ex.Sheet sheetPontos = excel['Pontos Mensais'];
    sheetPontos.appendRow([
      ex.TextCellValue('Mês'), 
      ex.TextCellValue('Pontos Adquiridos')
    ]);
    
    final linha = _estatisticas!['graficoLinha'];
    final labels = linha['labels'] as List<dynamic>;
    final data = linha['data'] as List<dynamic>;
    
    for (int i = 0; i < labels.length; i++) {
      sheetPontos.appendRow([
        ex.TextCellValue(labels[i].toString()),
        ex.IntCellValue((data[i] as num).toInt())
      ]);
    }

    // Folha 3: Badges Mensais
    ex.Sheet sheetBadges = excel['Badges Mensais'];
    sheetBadges.appendRow([
      ex.TextCellValue('Mês'),
      ex.TextCellValue('Badges Normais'),
      ex.TextCellValue('Badges Especiais')
    ]);
    final barras = _estatisticas!['graficoBarras'];
    final labelsBarras = barras['labels'] as List<dynamic>;
    final normais = barras['normais'] as List<dynamic>;
    final especiais = barras['especiais'] as List<dynamic>;
    for (int i = 0; i < labelsBarras.length; i++) {
      sheetBadges.appendRow([
        ex.TextCellValue(labelsBarras[i].toString()),
        ex.IntCellValue((normais[i] as num).toInt()),
        ex.IntCellValue((especiais[i] as num).toInt())
      ]);
    }

    // Folha 4: Ranking completo
    ex.Sheet sheetRanking = excel['Ranking Completo'];
    sheetRanking.appendRow([
      ex.TextCellValue('Posição'),
      ex.TextCellValue('Nome'),
      ex.TextCellValue('Service Line'),
      ex.TextCellValue('Área'),
      ex.TextCellValue('Pontos'),
      ex.TextCellValue('Badges')
    ]);
    for (final r in _rankingCompleto) {
      sheetRanking.appendRow([
        ex.IntCellValue((r['pos'] as num).toInt()),
        ex.TextCellValue(r['nome']?.toString() ?? ''),
        ex.TextCellValue(r['serviceLine']?.toString() ?? ''),
        ex.TextCellValue(r['area']?.toString() ?? ''),
        ex.IntCellValue((r['pontos'] as num?)?.toInt() ?? 0),
        ex.IntCellValue((r['badges'] as num?)?.toInt() ?? 0),
      ]);
    }

    excel.setDefaultSheet('Resumo');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Estatisticas_$_nomeCompleto.xlsx');
      
      var fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Gerado com Sucesso! A abrir...')));
        await OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LayoutConsultor(corpo: Center(child: CircularProgressIndicator()));

    final kpis = _estatisticas!['kpis'];
    final rankingLimitado = _verTudo ? _rankingCompleto : _rankingCompleto.take(5).toList();

    return LayoutConsultor(
      corpo: Container(
        color: const Color(0xFFF4F5F9),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Estatísticas Detalhadas e Ranking", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C323F))),
              const SizedBox(height: 5),
              const Text("Acompanhe o seu desempenho e classificação na Softinsa.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // KPIS
              Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildKpiCard("A Sua Posição", "${kpis['ranking']}º lugar", "de ${kpis['totalConsultores']} consultores da Empresa", Icons.leaderboard, Colors.amber)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildKpiCard("Total de Pontos", "${kpis['pontos']}", "Acumulados", Icons.stars, const Color(0xFF4C51F7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildKpiCard("Catálogo Global", "${kpis['percentagemBadges']}%", "Concluído", Icons.book, Colors.green)),
                        const SizedBox(width: 15),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // GRAFICOS ROW
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmall = constraints.maxWidth < 600;
                  return isSmall 
                    ? Column(
                        children: [
                          _buildLineChart(),
                          const SizedBox(height: 20),
                          _buildBarChart()
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildLineChart()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildBarChart()),
                        ],
                      );
                }
              ),

              const SizedBox(height: 30),

              // RANKING
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(child: Text("Classificação Global", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        TextButton(
                          onPressed: () => setState(() => _verTudo = !_verTudo), 
                          child: Text(_verTudo ? "Ver Apenas Top 5" : "Ver Todo o Ranking")
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rankingLimitado.length,
                      itemBuilder: (context, index) {
                        final r = rankingLimitado[index];
                        bool isMe = r['isMe'] == true;
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            leading: _buildRankBadge(r['pos']),
                            title: RichText(
                              text: TextSpan(
                                text: r['nome'] ?? 'Consultor',
                                style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: Colors.black87, fontSize: 14),
                                children: isMe ? const [TextSpan(text: " (Eu)", style: TextStyle(color: Color(0xFF4C51F7), fontWeight: FontWeight.bold))] : []
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${r['serviceLine'] ?? ''}", style: const TextStyle(fontSize: 12, color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
                                Text("${r['area'] ?? ''}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${r['pontos']} pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C51F7), fontSize: 14)),
                                Text("${r['badges']} badges", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      }
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // BOTÕES EXPORTAÇÃO
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  OutlinedButton.icon(
                    onPressed: _exportarPDF,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    label: const Text("Exportar para PDF", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _exportarExcel,
                    icon: const Icon(Icons.table_chart, color: Colors.white),
                    label: const Text("Exportar para Excel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int pos) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade700;
    if (pos == 1) { bg = Colors.amber; fg = Colors.white; }
    else if (pos == 2) { bg = Colors.blueGrey.shade300; fg = Colors.white; }
    else if (pos == 3) { bg = Colors.brown.shade300; fg = Colors.white; }
    
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: Text("$posº", style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12))),
    );
  }

  Widget _buildLineChart() {
    final linha = _estatisticas!['graficoLinha'];
    final labels = linha['labels'] as List<dynamic>;
    final data = linha['data'] as List<dynamic>;

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i] as num).toDouble()));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Evolução Mensal de Pontos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text("Últimos 6 meses", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem(
                        spot.y.toString(),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) return const SizedBox.shrink();
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) return const SizedBox.shrink();
                        int idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(labels[idx], style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                        return const Text('');
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF4C51F7),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4C51F7).withOpacity(0.1),
                    )
                  )
                ]
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final barras = _estatisticas!['graficoBarras'];
    final labels = barras['labels'] as List<dynamic>;
    final normais = barras['normais'] as List<dynamic>;
    final especiais = barras['especiais'] as List<dynamic>;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Evolução do Número de Badges", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text("Nos últimos 4 meses", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toString(),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) return const SizedBox.shrink();
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) return const SizedBox.shrink();
                        int idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(labels[idx], style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                        return const Text('');
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(labels.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (normais[i] as num).toDouble(),
                        color: const Color(0xFF4C51F7),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: (especiais[i] as num).toDouble(),
                        color: Colors.amber,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, color: const Color(0xFF4C51F7)),
              const SizedBox(width: 5),
              const Text("Normais", style: TextStyle(fontSize: 11)),
              const SizedBox(width: 15),
              Container(width: 10, height: 10, color: Colors.amber),
              const SizedBox(width: 5),
              const Text("Especiais", style: TextStyle(fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 160),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
      ),
    );
  }
}
