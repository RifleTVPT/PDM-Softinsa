import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_servico.dart';

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

    final result = await db.rawQuery('SELECT * FROM MARCO_CONQUISTA WHERE ID_MARCO = ?', [widget.idMarco]);
    if (result.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final marcoData = Map<String, dynamic>.from(result.first);

    if (widget.isObtido) {
      final consultorData = await db.rawQuery('SELECT DATA_CONQUISTA FROM MARCO_CONSULTOR WHERE ID_MARCO = ?', [widget.idMarco]);
      if (consultorData.isNotEmpty) {
        _dataObtencao = consultorData.first['DATA_CONQUISTA'] as String?;
      }
    } else {
      String tipoMarco = marcoData['TIPO_MARCO'] ?? '';
      int param1 = marcoData['PARAMETRO_1'] ?? 1;
      int param2 = marcoData['PARAMETRO_2'] ?? 0;

      _maxProgress = param1;

      if (tipoMarco == 'TOTAL_BADGES') {
        final res = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR_BADGE');
        _progress = res.first['c'] as int;
        _progressoLabel = '$_progress / $_maxProgress Badges';
      } else if (tipoMarco == 'TOTAL_PONTOS') {
        final res = await db.rawQuery('SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?', [_idUtilizador]);
        _progress = res.isNotEmpty ? res.first['PONTUACAO_TOTAL'] as int : 0;
        _progressoLabel = '$_progress / $_maxProgress Pontos';
      } else if (tipoMarco == 'BADGES_DIAS') {
        final limitDate = DateTime.now().subtract(Duration(days: param2)).toIso8601String();
        final res = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE DATA_ATRIBUICAO_BADGE >= ?', [limitDate]);
        _progress = res.first['c'] as int;
        _progressoLabel = '$_progress / $_maxProgress Badges nos últimos $param2 dias';
      } else if (tipoMarco == 'MELHOR_ANO' || tipoMarco == 'MELHOR_MESES') {
        final totalRes = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR');
        int totalConsultores = totalRes.first['c'] as int;
        
        final resP = await db.rawQuery('SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?', [_idUtilizador]);
        int p = resP.isNotEmpty ? resP.first['PONTUACAO_TOTAL'] as int : 0;
        
        final abaixoRes = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR WHERE PONTUACAO_TOTAL < ?', [p]);
        int consultoresAbaixo = abaixoRes.first['c'] as int;
        
        double progValor = totalConsultores > 1 ? (consultoresAbaixo / (totalConsultores - 1)) * 100 : 100;
        _maxProgress = 100;
        _progress = progValor.round();
        _progressoLabel = 'À frente de $_progress% dos consultores';
      } else {
        // Fallback for custom text
        _maxProgress = param1 > 0 ? param1 : 1;
        _progress = 0;
        _progressoLabel = 'Progresso dependente do Administrador';
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

  void _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.'), backgroundColor: Colors.red));
    }
  }

  void _copiarLinkPublico() {
    final urlPublica = 'https://softinsa-plataforma.onrender.com/verificacao-especial/$_idUtilizador/${widget.idMarco}';
    Clipboard.setData(ClipboardData(text: urlPublica)).then((_) {
      setState(() => _linkCopiado = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _linkCopiado = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado para a área de transferência!'), backgroundColor: Colors.green));
    });
  }

  void _partilharLinkedIn() {
    final urlPartilha = '${ApiServico.baseUrl}/partilha/linkedin/premium/$_idUtilizador/${widget.idMarco}';
    _abrirUrl(urlPartilha);
  }

  void _gerarCertificado() {
    final urlCert = '${ApiServico.baseUrl}/conquistas/$_idUtilizador/${widget.idMarco}/certificado';
    _abrirUrl(urlCert); // O browser transfere o PDF
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LayoutConsultor(corpo: Center(child: CircularProgressIndicator()));
    if (_marco == null) return const LayoutConsultor(corpo: Center(child: Text("Erro ao carregar detalhes da Conquista.")));

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
                    Text("Voltar à Galeria de Honra", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD 1: CABEÇALHO (ÍCONE E PONTOS)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: widget.isObtido ? Colors.white : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isObtido ? const Color(0xFFF9F1DC) : const Color(0xFFE9ECEF),
                        border: Border.all(color: widget.isObtido ? const Color(0xFFD4AF37) : const Color(0xFFADB5BD), width: 6),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Icon(
                        widget.isObtido ? Icons.workspace_premium : Icons.lock, 
                        size: 60, 
                        color: widget.isObtido ? Colors.amber.shade700 : Colors.grey
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_marco!['TITULO_MARCO'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isObtido ? Colors.amber : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isObtido ? "CONQUISTA ESPECIAL" : "POR DESBLOQUEAR",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("+${_marco!['PONTOS_EXTRA']}", style: const TextStyle(color: Color(0xFF4C51F7), fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text("PONTOS BÓNUS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Descrição da Conquista", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    Text(_marco!['DESCRICAO_MARCO'] ?? 'Sem descrição.', style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15)),
                    
                    const SizedBox(height: 25),
                    const Text("Como obter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    Text(_marco!['REGRA_ATRIBUICAO'] ?? 'Complete os requisitos específicos.', style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15)),
                    
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
                            const Icon(Icons.check_circle, color: Colors.green, size: 40),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Conquistado com Sucesso!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text("Adicionado ao seu perfil em ${_formatarData(_dataObtencao)}.", style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
                                const Text("Progresso Estimado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_progressoLabel, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4C51F7)))),
                              ],
                            ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _maxProgress > 0 ? _progress / _maxProgress : 0,
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
                                Icon(Icons.info_outline, color: Colors.grey, size: 24),
                                SizedBox(width: 15),
                                Expanded(child: Text("Continue a progredir na plataforma para desbloquear esta recompensa.", style: TextStyle(color: Colors.grey, fontSize: 13))),
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
                  label: Text(_linkCopiado ? "Link Copiado!" : "Copiar Link Público"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _linkCopiado ? Colors.green : Colors.white,
                    foregroundColor: _linkCopiado ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: _linkCopiado ? Colors.green : Colors.grey.shade300),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
