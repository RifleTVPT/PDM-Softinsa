import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import 'package:url_launcher/url_launcher.dart';

class MeusBadgesDetalheView extends StatefulWidget {
  final int idBadge;
  final int idConsultor;

  const MeusBadgesDetalheView({
    super.key,
    required this.idBadge,
    required this.idConsultor,
  });

  @override
  State<MeusBadgesDetalheView> createState() => _MeusBadgesDetalheViewState();
}

class _MeusBadgesDetalheViewState extends State<MeusBadgesDetalheView> {
  Map<String, dynamic>? _detalhe;
  List<Map<String, dynamic>> _evidencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDetalhe();
  }

  Future<void> _carregarDetalhe() async {
    final bd = BDLocalAjudante();
    
    final res = await bd.database.then((db) => db.rawQuery('SELECT ID_UTILIZADOR FROM CONSULTOR WHERE ID_CONSULTOR = ?', [widget.idConsultor]));
    int idUtilizador = 1;
    if (res.isNotEmpty) {
      idUtilizador = res.first['ID_UTILIZADOR'] as int;
    }
    
    final detalheFinal = await bd.obterBadgeDetalhe(widget.idBadge, idUtilizador);
    final evidenciasFinal = await bd.obterEvidenciasDePedidoAprovado(widget.idBadge, idUtilizador);

    if (!mounted) return;
    setState(() {
      _detalhe = detalheFinal;
      _evidencias = evidenciasFinal;
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

  Widget _widgetExpiracao(Map<String, dynamic> badge) {
    if (badge['validadeMeses'] == null || badge['validadeMeses'] == 0) {
      return const Text("Não expira", style: TextStyle(fontSize: 13, color: Colors.green));
    }
    
    if (badge['dataExpiracao'] != null) {
      try {
        DateTime expiracao = DateTime.parse(badge['dataExpiracao']);
        int dias = expiracao.difference(DateTime.now()).inDays;
        String dataExpF = _formatarData(badge['dataExpiracao']);
        
        if (dias < 0) {
          return Text("Expirado ($dataExpF)", style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold));
        } else if (dias < 30) {
          return Text("Expira em $dias dias ($dataExpF)", style: const TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold));
        } else {
          return Text("Expira em $dias dias ($dataExpF)", style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold));
        }
      } catch (e) {
        return const SizedBox();
      }
    }
    return const SizedBox();
  }

  Future<void> _abrirUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LayoutConsultor(
        corpo: Center(child: CircularProgressIndicator()),
      );
    }

    if (_detalhe == null) {
      return const LayoutConsultor(
        corpo: Center(child: Text("Erro ao carregar detalhes do Badge.")),
      );
    }

    final reqs = _detalhe!['requisitos'] as List<dynamic>;

    return LayoutConsultor(
      corpo: Container(
        color: const Color(0xFFF4F5F9),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header navigation
              GestureDetector(
                onTap: () => context.pop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.grey, size: 20),
                    SizedBox(width: 5),
                    Text("Voltar à Galeria de Badges", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CAIXA PRINCIPAL SUPERIOR (Branca)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Esquerda: Ícone e Info Básica
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF4C51F7), width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.emoji_events, size: 70, color: Colors.amber),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.green, size: 10),
                                SizedBox(width: 5),
                                Text("Status: Ativo", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text("Obtido em: ${_formatarData(_detalhe!['dataObtencao'])}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          _widgetExpiracao(_detalhe!),
                          const SizedBox(height: 20),
                          _buildInfoRow("Service Line:", _detalhe!['sl']),
                          _buildInfoRow("Área:", _detalhe!['area']),
                          _buildInfoRow("Nível:", "${_detalhe!['nivel']} (Nível ${_detalhe!['nivel']})"),
                          _buildInfoRow("Validade:", _detalhe!['validadeMeses'] == null || _detalhe!['validadeMeses'] == 0 ? "Sempre" : "${(_detalhe!['validadeMeses'] / 12).toStringAsFixed(0)} anos"),
                          _buildInfoRow("Pontos:", "${_detalhe!['pontos']} pontos"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Direita: Descrição
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Descrição", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(_detalhe!['descricao'], style: const TextStyle(color: Colors.black87, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // SECÇÃO REQUISITOS
              const Text("Requisitos concluídos para a sua Obtenção", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: reqs.length,
                  itemBuilder: (context, index) {
                    final req = reqs[index];
                    return _buildRequisitoCard(req);
                  },
                ),
              ),

              const SizedBox(height: 30),

              // SECÇÃO DE PARTILHA
              const Text("Partilha e Opções de Badge", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      "Partilhar no LinkedIn", 
                      Icons.work, 
                      Colors.blue.shade800, 
                      Colors.white, 
                      false,
                      () => _abrirUrl("https://www.linkedin.com/")
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      "Link de Verificação", 
                      Icons.link, 
                      const Color(0xFF4C51F7), 
                      Colors.white, 
                      true, // Filled
                      () => _abrirUrl("https://softinsa-plataforma.onrender.com/verificacao/${_detalhe!['linkUnico']}")
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      "Certificado Oficial", 
                      Icons.picture_as_pdf, 
                      Colors.red.shade400, 
                      Colors.white, 
                      false,
                      () => _abrirUrl("https://softinsa-plataforma.onrender.com/verificacao/${_detalhe!['linkUnico']}")
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShareButton(
                      "Assinatura de Email", 
                      Icons.email, 
                      Colors.green.shade600, 
                      Colors.white, 
                      false,
                      () => _abrirUrl("https://softinsa-plataforma.onrender.com/verificacao/${_detalhe!['linkUnico']}")
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildRequisitoCard(Map<String, dynamic> req) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(req['titulo'], style: const TextStyle(color: Color(0xFF4C51F7), fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(req['desc'], style: const TextStyle(color: Colors.black87, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Evidências Submetidas:", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _evidencias.isEmpty 
              ? const Text("Sem ficheiros mapeados.", style: TextStyle(fontSize: 11, color: Colors.grey))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _evidencias.length,
                  itemBuilder: (context, index) {
                    final ev = _evidencias[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 14, color: Color(0xFF4C51F7)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              ev['CAMINHO_EVIDENCIA'].toString().split('/').last, 
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4C51F7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildShareButton(String text, IconData icon, Color corPrincipal, Color corTexto, bool isFilled, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isFilled ? corPrincipal : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isFilled ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isFilled ? corTexto : corPrincipal, size: 24),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: isFilled ? corTexto : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
