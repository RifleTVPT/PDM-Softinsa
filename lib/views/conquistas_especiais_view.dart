import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';
import 'package:go_router/go_router.dart';
import '../components/imagem_badge_mobile.dart';

class ConquistasEspeciaisView extends StatefulWidget {
  const ConquistasEspeciaisView({super.key});

  @override
  State<ConquistasEspeciaisView> createState() =>
      _ConquistasEspeciaisViewState();
}

class _ConquistasEspeciaisViewState extends State<ConquistasEspeciaisView> {
  final TextEditingController _pesquisaController = TextEditingController();
  bool _isLoading = true;

  // OBTIDAS (O Consultor já tem)
  List<Map<String, dynamic>> _premiumObtidas = [];

  // DISPONÍVEIS NA PLATAFORMA (Ainda por conquistar)
  List<Map<String, dynamic>> _premiumDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _carregarConquistas();
  }

  Future<int> _pontosPeriodo(
      dynamic db, int idUtilizador, DateTime inicio, DateTime fim) async {
    final res = await db.rawQuery('''
      SELECT COALESCE(SUM(PONTOS_OBTIDOS), 0) as total
      FROM HISTORICO_PONTUACAO
      WHERE ID_UTILIZADOR = ?
        AND DATA_ATRIBUICAO >= ?
        AND DATA_ATRIBUICAO < ?
        AND (ORIGEM_PONTOS IS NULL OR ORIGEM_PONTOS NOT LIKE ?)
    ''', [
      idUtilizador,
      inicio.toIso8601String(),
      fim.toIso8601String(),
      'Badge premium:%'
    ]);
    return (res.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> _carregarConquistas() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final bdHelper = BDLocalAjudante();
    final db = await bdHelper.database;

    final bdDadosObtidos =
        await bdHelper.obterConquistasEspeciais(idUtilizador);
    final bdDadosDisponiveis =
        await bdHelper.obterMarcosDisponiveis(idUtilizador);

    List<Map<String, dynamic>> disponiveisProcessadas = [];
    final consultorRes = await db.rawQuery(
        'SELECT ID_CONSULTOR FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [idUtilizador]);
    final idConsultor = consultorRes.isNotEmpty
        ? consultorRes.first['ID_CONSULTOR'] as int
        : null;

    DateTime dataCriacao(Map<String, dynamic> row) {
      return DateTime.tryParse(row['DATA_CRIACAO_MARCO']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime fimJanela(
        Map<String, dynamic> row, String tipo, int param1, int param2) {
      if (tipo == 'MELHOR_ANO') {
        final ano = param1;
        return DateTime(ano + 1, 1, 1);
      }
      final inicio = dataCriacao(row);
      if (tipo == 'MELHOR_MESES') {
        return inicio.isUtc
            ? DateTime.utc(
                inicio.year,
                inicio.month + param1,
                inicio.day,
                inicio.hour,
                inicio.minute,
                inicio.second,
                inicio.millisecond,
                inicio.microsecond,
              )
            : DateTime(
                inicio.year,
                inicio.month + param1,
                inicio.day,
                inicio.hour,
                inicio.minute,
                inicio.second,
                inicio.millisecond,
                inicio.microsecond,
              );
      }
      return inicio.add(Duration(days: param2));
    }

    String labelPrazo(DateTime fim) {
      final dias = (fim.difference(DateTime.now()).inMilliseconds /
              Duration.millisecondsPerDay)
          .ceil()
          .clamp(0, 99999);
      if (dias == 0) return 'Último dia';
      return 'Faltam $dias ${dias == 1 ? 'dia' : 'dias'}';
    }

    // Calcular o progresso de cada conquista não obtida
    for (var row in bdDadosDisponiveis) {
      String tipoMarco = row['TIPO_MARCO'] ?? '';
      int param1 = row['PARAMETRO_1'] ?? 1;
      int param2 = row['PARAMETRO_2'] ?? 0;

      int progress = 0;
      int maxProgress = param1;
      String progressoLabel = '';
      String? prazoLabel;

      if (tipoMarco == 'TOTAL_BADGES') {
        final res = await db.rawQuery(
            'SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ?',
            [idConsultor]);
        progress = res.first['c'] as int;
        progressoLabel = '$progress / $maxProgress';
      } else if (tipoMarco == 'TOTAL_PONTOS') {
        final res = await db.rawQuery(
            'SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
            [idUtilizador]);
        progress = res.isNotEmpty ? res.first['PONTUACAO_TOTAL'] as int : 0;
        progressoLabel = '$progress / $maxProgress';
      } else if (tipoMarco == 'BADGES_DIAS') {
        final inicio = dataCriacao(row);
        final fim = fimJanela(row, tipoMarco, param1, param2);
        if (DateTime.now().isAfter(fim)) {
          progress = 0;
          progressoLabel = 'Já não é possível obter';
        } else {
          prazoLabel = labelPrazo(fim);
          final res = await db.rawQuery(
              'SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ? AND DATA_ATRIBUICAO_BADGE >= ? AND DATA_ATRIBUICAO_BADGE < ?',
              [idConsultor, inicio.toIso8601String(), fim.toIso8601String()]);
          progress = res.first['c'] as int;
          progressoLabel = '$progress / $maxProgress';
        }
      } else if (tipoMarco == 'MELHOR_ANO' || tipoMarco == 'MELHOR_MESES') {
        final fim = fimJanela(row, tipoMarco, param1, param2);
        if (DateTime.now().isAfter(fim)) {
          maxProgress = 100;
          progress = 0;
          progressoLabel = 'Já não é possível obter';
        } else {
          prazoLabel = labelPrazo(fim);
          final totalRes =
              await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR');
          int totalConsultores = totalRes.first['c'] as int;

          final inicio = tipoMarco == 'MELHOR_ANO'
              ? DateTime(param1, 1, 1)
              : dataCriacao(row);
          final pontosAtual =
              await _pontosPeriodo(db, idUtilizador, inicio, DateTime.now());
          final consultoresRes = await db
              .rawQuery('SELECT ID_CONSULTOR, ID_UTILIZADOR FROM CONSULTOR');
          int consultoresAbaixo = 0;
          for (final c in consultoresRes) {
            if (c['ID_CONSULTOR'] == idConsultor) continue;
            final idOutro = c['ID_UTILIZADOR'] as int?;
            if (idOutro == null) continue;
            final pontosOutro =
                await _pontosPeriodo(db, idOutro, inicio, DateTime.now());
            if (pontosOutro < pontosAtual) consultoresAbaixo++;
          }

          double progValor = totalConsultores > 1
              ? (consultoresAbaixo / (totalConsultores - 1)) * 100
              : 100;
          maxProgress = 100;
          progress = progValor.round();
          progressoLabel = 'À frente de $progress% dos consultores';
        }
      } else {
        maxProgress = param1 > 0 ? param1 : 1;
        progress = 0;
        progressoLabel = 'Pendente';
      }

      if (progress > maxProgress) progress = maxProgress;

      disponiveisProcessadas.add({
        "id": row['ID_MARCO'],
        "titulo": row['TITULO_MARCO'],
        "descricao": row['DESCRICAO_MARCO'],
        "bonus": row['PONTOS_EXTRA'],
        "regra": row['REGRA_ATRIBUICAO'],
        "tipo": row['TIPO_MARCO'],
        "urlImagem": row['URL_IMAGEM_MARCO'],
        "progress": progress,
        "maxProgress": maxProgress,
        "progressoLabel": progressoLabel,
        "prazoLabel": prazoLabel
      });
    }

    if (!mounted) return;
    setState(() {
      _premiumObtidas = bdDadosObtidos
          .map((row) => {
                "id": row['ID_MARCO'],
                "titulo": row['TITULO_MARCO'],
                "descricao": row['DESCRICAO_MARCO'],
                "bonus": row['PONTOS_EXTRA'],
                "regra": row['REGRA_ATRIBUICAO'],
                "tipo": row['TIPO_MARCO'],
                "urlImagem": row['URL_IMAGEM_MARCO'],
                "data_conquista": row['DATA_CONQUISTA'],
              })
          .toList();

      _premiumDisponiveis = disponiveisProcessadas;

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  String _labelTipo(String? tipo) {
    switch ((tipo ?? '').toUpperCase()) {
      case 'TOTAL_BADGES':
        return 'Total Badges';
      case 'TOTAL_PONTOS':
        return 'Total Pontos';
      case 'BADGES_DIAS':
        return 'Badges por Dias';
      case 'MELHOR_ANO':
        return 'Melhor do Ano';
      case 'MELHOR_MESES':
        return 'Melhor dos Meses';
      default:
        return 'Especial';
    }
  }

  List<Map<String, dynamic>> _filtrarLista(List<Map<String, dynamic>> lista) {
    if (_pesquisaController.text.isEmpty) return lista;
    return lista
        .where((b) => b['titulo']
            .toString()
            .toLowerCase()
            .contains(_pesquisaController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final obtidasVisiveis = _filtrarLista(_premiumObtidas);
    final disponiveisVisiveis = _filtrarLista(_premiumDisponiveis);

    return LayoutConsultor(
      corpo: Column(
        children: [
          // HEADER AZUL
          Container(
            width: double.infinity,
            color: const Color(0xFF34659D),
            padding:
                const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 25),
            child: Column(
              children: [
                const Text("Conquistas Especiais",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                const Text("Explore recompensas exclusivas e certificações.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                TextField(
                  controller: _pesquisaController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Pesquisar conquistas...",
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF34659D)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // CORPO COM DUAS SECÇÕES
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECÇÃO 1: OBTIDAS
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      SizedBox(width: 8),
                      Text("As Minhas Conquistas",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (obtidasVisiveis.isEmpty)
                    const Text("Nenhuma conquista obtida.",
                        style: TextStyle(color: Colors.grey))
                  else
                    ...obtidasVisiveis.map((b) => _cardPremium(b, true)),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),

                  // SECÇÃO 2: DISPONÍVEIS
                  const Row(
                    children: [
                      Icon(Icons.explore, color: Color(0xFF34659D)),
                      SizedBox(width: 8),
                      Text("Disponíveis na Plataforma",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (disponiveisVisiveis.isEmpty)
                    const Text("Nenhuma conquista disponível encontrada.",
                        style: TextStyle(color: Colors.grey))
                  else
                    ...disponiveisVisiveis.map((b) => _cardPremium(b, false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card unificado para as Premium (Obtidas e Disponíveis)
  Widget _cardPremium(Map<String, dynamic> badge, bool jaObtida) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: jaObtida
            ? Border.all(color: Colors.amber, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: jaObtida ? Colors.amber.shade50 : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(
                  color: jaObtida ? Colors.amber : const Color(0xFFC0C0C0),
                  width: 3),
            ),
            child: ClipOval(
              child: ImagemBadgeMobile(
                urlImagem: badge['urlImagem']?.toString(),
                tamanho: 80,
                cinzento: !jaObtida,
                padding: const EdgeInsets.all(6),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(badge['titulo'],
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_labelTipo(badge['tipo']?.toString()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF34659D),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(badge['descricao'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 15),
          Text("+${badge['bonus']} Pontos Bónus",
              style: const TextStyle(
                  color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
          if (jaObtida && badge['data_conquista'] != null) ...[
            const SizedBox(height: 10),
            Text("Obtido em: ${_formatarData(badge['data_conquista'])}",
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
          if (!jaObtida) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progresso",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(badge['progressoLabel'] ?? '',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge['progressoLabel'] ==
                                    'Já não é possível obter'
                                ? Colors.red
                                : const Color(0xFF4C51F7)))),
              ],
            ),
            if (badge['prazoLabel'] != null &&
                badge['progressoLabel'] != 'Já não é possível obter') ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(badge['prazoLabel'],
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (badge['progressoLabel'] != 'Já não é possível obter')
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: badge['maxProgress'] > 0
                      ? badge['progress'] / badge['maxProgress']
                      : 0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF4C51F7),
                ),
              ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/conquistas_detalhe',
                  extra: {'idMarco': badge['id'], 'isObtido': jaObtida}),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4C51F7)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Ver Detalhes",
                  style: TextStyle(
                      color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return "N/D";
    try {
      final parts = dataIso.split("T")[0].split("-");
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (e) {
      return dataIso;
    }
  }
}
