import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_servico.dart';
import '../components/imagem_badge_mobile.dart';

class ConquistasDetalheView extends StatefulWidget {
  final int idMarco;
  final bool isObtido;

  const ConquistasDetalheView({
    super.key,
    required this.idMarco,
    required this.isObtido,
  });

  @override
  State<ConquistasDetalheView> createState() => _ConquistasDetalheViewState();
}

class _ConquistasDetalheViewState extends State<ConquistasDetalheView> {
  Map<String, dynamic>? _marco;
  String? _dataObtencao;
  int _progress = 0;
  int _maxProgress = 1;
  String _progressoLabel = 'Em curso';
  String? _prazoLabel;
  bool _isLoading = true;
  int _idUtilizador = 0;
  bool _linkCopiado = false;

  @override
  void initState() {
    super.initState();
    _carregarDetalhe();
  }

  Future<void> _carregarDetalhe() async {
    final prefs = await SharedPreferences.getInstance();
    _idUtilizador = prefs.getInt('idUtilizador') ?? 0;

    final bd = BDLocalAjudante();
    final db = await bd.database;

    final result = await db.rawQuery(
        'SELECT * FROM MARCO_CONQUISTA WHERE ID_MARCO = ?', [widget.idMarco]);
    if (result.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final marcoData = Map<String, dynamic>.from(result.first);

    if (widget.isObtido) {
      final consultorData = await db.rawQuery(
          'SELECT DATA_CONQUISTA FROM MARCO_CONSULTOR WHERE ID_MARCO = ?',
          [widget.idMarco]);
      if (consultorData.isNotEmpty) {
        _dataObtencao = consultorData.first['DATA_CONQUISTA'] as String?;
      }
    } else {
      String tipoMarco = marcoData['TIPO_MARCO'] ?? '';
      int param1 = marcoData['PARAMETRO_1'] ?? 1;
      int param2 = marcoData['PARAMETRO_2'] ?? 0;
      final consultorRes = await db.rawQuery(
          'SELECT ID_CONSULTOR FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
          [_idUtilizador]);
      final idConsultor = consultorRes.isNotEmpty
          ? consultorRes.first['ID_CONSULTOR'] as int
          : null;

      DateTime dataCriacao() {
        return DateTime.tryParse(
                marcoData['DATA_CRIACAO_MARCO']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      DateTime fimJanela() {
        if (tipoMarco == 'MELHOR_ANO') return DateTime(param1 + 1, 1, 1);
        final inicio = dataCriacao();
        if (tipoMarco == 'MELHOR_MESES') {
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
        if (dias == 1) return 'Falta 1 dia';
        return 'Faltam $dias dias';
      }

      _maxProgress = param1;

      if (tipoMarco == 'TOTAL_BADGES') {
        final res = await db.rawQuery(
            'SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ?',
            [idConsultor]);
        _progress = res.first['c'] as int;
        _progressoLabel = '$_progress / $_maxProgress Badges';
      } else if (tipoMarco == 'TOTAL_PONTOS') {
        final res = await db.rawQuery(
            'SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
            [_idUtilizador]);
        _progress = res.isNotEmpty ? res.first['PONTUACAO_TOTAL'] as int : 0;
        _progressoLabel = '$_progress / $_maxProgress Pontos';
      } else if (tipoMarco == 'BADGES_DIAS') {
        final inicio = dataCriacao();
        final fim = fimJanela();
        if (DateTime.now().isAfter(fim)) {
          _progress = 0;
          _progressoLabel = 'Já não é possível obter';
          _prazoLabel = null;
        } else {
          final res = await db.rawQuery(
              'SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ? AND DATA_ATRIBUICAO_BADGE >= ? AND DATA_ATRIBUICAO_BADGE < ?',
              [idConsultor, inicio.toIso8601String(), fim.toIso8601String()]);
          _progress = res.first['c'] as int;
          _progressoLabel = '$_progress / $_maxProgress Badges';
          _prazoLabel = labelPrazo(fim);
        }
      } else if (tipoMarco == 'MELHOR_ANO' || tipoMarco == 'MELHOR_MESES') {
        final fim = fimJanela();
        if (DateTime.now().isAfter(fim)) {
          _maxProgress = 100;
          _progress = 0;
          _progressoLabel = 'Já não é possível obter';
          _prazoLabel = null;
        } else {
          final totalRes =
              await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR');
          int totalConsultores = totalRes.first['c'] as int;

          final inicio = tipoMarco == 'MELHOR_ANO'
              ? DateTime(param1, 1, 1)
              : dataCriacao();
          final pontosAtual =
              await _pontosPeriodo(db, _idUtilizador, inicio, DateTime.now());
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
          _maxProgress = 100;
          _progress = progValor.round();
          _progressoLabel = 'À frente de $_progress% dos consultores';
          _prazoLabel = labelPrazo(fim);
        }
      } else {
        // Fallback for custom text
        _maxProgress = param1 > 0 ? param1 : 1;
        _progress = 0;
        _progressoLabel = 'Progresso dependente do Administrador';
        _prazoLabel = null;
      }

      if (_progress > _maxProgress) _progress = _maxProgress;
    }

    if (!mounted) return;
    setState(() {
      _marco = marcoData;
      _isLoading = false;
    });
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

  String _textoComoObter() {
    final tipo = _marco?['TIPO_MARCO']?.toString().toUpperCase() ?? '';
    final p1 = _marco?['PARAMETRO_1'] ?? 0;
    final p2 = _marco?['PARAMETRO_2'] ?? 0;
    switch (tipo) {
      case 'TOTAL_BADGES':
        return 'Obtenha pelo menos $p1 badges na plataforma.';
      case 'TOTAL_PONTOS':
        return 'Alcance pelo menos $p1 pontos acumulados.';
      case 'BADGES_DIAS':
        return 'Obtenha $p1 badges num período de $p2 dias.';
      case 'MELHOR_ANO':
        return 'Fique entre os melhores consultores do ano na plataforma.';
      case 'MELHOR_MESES':
        return 'Mantenha desempenho de destaque durante o período definido.';
      default:
        return _marco?['REGRA_ATRIBUICAO']?.toString() ??
            'Complete os requisitos definidos para esta conquista.';
    }
  }

  void _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    final aberto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!aberto) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível abrir o link.'),
            backgroundColor: Colors.red));
    }
  }

  void _copiarLinkPublico() {
    final urlPublica =
        'https://softinsa-plataforma.onrender.com/verificacao-especial/$_idUtilizador/${widget.idMarco}';
    Clipboard.setData(ClipboardData(text: urlPublica)).then((_) {
      setState(() => _linkCopiado = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _linkCopiado = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link copiado para a área de transferência!'),
          backgroundColor: Colors.green));
    });
  }

  void _abrirPaginaPublica() {
    if (!widget.isObtido) return;
    final urlPublica =
        'https://softinsa-plataforma.onrender.com/verificacao-especial/$_idUtilizador/${widget.idMarco}';
    _abrirUrl(urlPublica);
  }

  void _partilharLinkedIn() {
    final urlPartilha =
        '${ApiServico.baseUrl}/partilha/linkedin/premium/$_idUtilizador/${widget.idMarco}';
    final urlPartilhaComCache =
        '$urlPartilha?v=${DateTime.now().millisecondsSinceEpoch}';
    final linkedinUrl =
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(urlPartilhaComCache)}';
    _abrirUrl(linkedinUrl);
  }

  void _gerarCertificado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');
      final urlCertificado = Uri.parse(
          '${ApiServico.baseUrl}/conquistas/$_idUtilizador/${widget.idMarco}/certificado');

      final response = await http.get(
        urlCertificado,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(utf8.decode(response.bodyBytes));
      }

      final dir = await getApplicationDocumentsDirectory();
      final nomeSeguro = (_marco?['TITULO_MARCO']?.toString() ?? 'premium')
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final file = File('${dir.path}/Certificado_Premium_$nomeSeguro.pdf');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao descarregar certificado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const LayoutConsultor(
          corpo: Center(child: CircularProgressIndicator()));
    if (_marco == null)
      return const LayoutConsultor(
          corpo:
              Center(child: Text("Erro ao carregar detalhes da Conquista.")));

    return LayoutConsultor(
      corpo: Container(
        color: const Color(0xFFF4F5F9),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.grey, size: 20),
                    SizedBox(width: 5),
                    Text("Voltar à Galeria de Honra",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD 1: CABEÇALHO (ÍCONE E PONTOS)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color:
                      widget.isObtido ? Colors.white : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: widget.isObtido ? _abrirPaginaPublica : null,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isObtido
                              ? const Color(0xFFF9F1DC)
                              : const Color(0xFFE9ECEF),
                          border: Border.all(
                              color: widget.isObtido
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFADB5BD),
                              width: 6),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10)
                          ],
                        ),
                        child: ClipOval(
                          child: ImagemBadgeMobile(
                            urlImagem: _marco!['URL_IMAGEM_MARCO']?.toString(),
                            tamanho: 120,
                            cinzento: !widget.isObtido,
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_marco!['TITULO_MARCO'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isObtido ? Colors.amber : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _labelTipo(_marco!['TIPO_MARCO']?.toString()),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("+${_marco!['PONTOS_EXTRA']}",
                        style: const TextStyle(
                            color: Color(0xFF4C51F7),
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const Text("PONTOS BÓNUS",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CARD 2: REGRAS E PROGRESSO
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Descrição da Conquista",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    Text(_marco!['DESCRICAO_MARCO'] ?? 'Sem descrição.',
                        style: const TextStyle(
                            color: Colors.black87, height: 1.5, fontSize: 15)),
                    const SizedBox(height: 25),
                    const Text("Como obter",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    Text(_textoComoObter(),
                        style: const TextStyle(
                            color: Colors.black87, height: 1.5, fontSize: 15)),
                    const SizedBox(height: 25),
                    if (widget.isObtido)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 40),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Conquistado com Sucesso!",
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text(
                                      "Adicionado ao seu perfil em ${_formatarData(_dataObtencao)}.",
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Progresso Estimado",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(_progressoLabel,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _progressoLabel ==
                                                  'Já não é possível obter'
                                              ? Colors.red
                                              : const Color(0xFF4C51F7)))),
                            ],
                          ),
                          if (_prazoLabel != null &&
                              _progressoLabel != 'Já não é possível obter') ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 5),
                                Text(_prazoLabel!,
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (_progressoLabel != 'Já não é possível obter')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _maxProgress > 0
                                    ? _progress / _maxProgress
                                    : 0,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade200,
                                color: const Color(0xFF4C51F7),
                              ),
                            ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey, size: 24),
                                SizedBox(width: 15),
                                Expanded(
                                    child: Text(
                                        "Continue a progredir na plataforma para desbloquear esta recompensa.",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // CARD 3: ACÕES (APENAS SE OBTIDO)
              if (widget.isObtido) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _copiarLinkPublico,
                  icon: Icon(_linkCopiado ? Icons.check : Icons.link),
                  label: Text(
                      _linkCopiado ? "Link Copiado!" : "Copiar Link Público"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _linkCopiado ? Colors.green : Colors.white,
                    foregroundColor:
                        _linkCopiado ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                          color: _linkCopiado
                              ? Colors.green
                              : Colors.grey.shade300),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _partilharLinkedIn,
                  icon: const Icon(Icons.share),
                  label: const Text("Partilhar no LinkedIn"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _gerarCertificado,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Descarregar Certificado"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C51F7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
