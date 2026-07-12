import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import '../services/api_servico.dart';
import '../components/imagem_badge_mobile.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidoStatusView extends StatefulWidget {
  final int idPedido;
  const PedidoStatusView({super.key, required this.idPedido});

  @override
  State<PedidoStatusView> createState() => _PedidoStatusViewState();
}

class _PedidoStatusViewState extends State<PedidoStatusView> {
  bool _isLoading = true;
  Map<String, dynamic>? _dadosPedido;

  @override
  void initState() {
    super.initState();
    _carregarPedido();
  }

  String _formatarNomeRequisito(String? tituloDB, String nivelStr) {
    if (tituloDB == null || tituloDB.isEmpty) return 'Não mapeado';
    if (!tituloDB.toLowerCase().startsWith('requisito ')) return tituloDB;

    String letra = '';
    String n = nivelStr.toLowerCase().trim();
    if (n == 'júnior' || n == 'junior')
      letra = 'A';
    else if (n == 'pleno')
      letra = 'B';
    else if (n == 'sênior' || n == 'senior')
      letra = 'C';
    else if (n == 'especialista')
      letra = 'D';
    else if (n == 'principal') letra = 'E';

    String numStr = tituloDB.substring(10).trim();
    if (numStr.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(numStr)) {
      return tituloDB; // Já está formatado
    }
    return 'Requisito $letra$numStr';
  }

  Widget _infoBadgeCurta(String titulo, String valor,
      {CrossAxisAlignment alinhamento = CrossAxisAlignment.start,
      TextAlign textAlign = TextAlign.start}) {
    return Column(
      crossAxisAlignment: alinhamento,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          valor,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _carregarPedido() async {
    try {
      // 1. Carregar BASE LOCAL primeiro
      final dadosLocal =
          await BDLocalAjudante().obterPedidoDetalhe(widget.idPedido);
      if (!mounted) return;

      if (dadosLocal == null) {
        setState(() => _isLoading = false);
        return;
      }

      String statusInicial = dadosLocal['ESTADO_PEDIDO'] ?? 'Pendente';

      // 2. Histórico offline
      List<Map<String, dynamic>> historicoLocal = [];
      if (statusInicial == 'Rascunho') {
        historicoLocal = [
          {
            "passo": "Rascunho criado",
            "data": _formatarData(dadosLocal['DATA_SUBMISSAO_PEDIDO']),
            "status": "info",
            "subtitulo": "Consultor"
          },
        ];
      } else {
        historicoLocal = [
          {
            "passo": "Pedido submetido",
            "data": _formatarData(dadosLocal['DATA_SUBMISSAO_PEDIDO']),
            "status": "success",
            "subtitulo": "Consultor"
          },
        ];
      }

      // 3. Monta o Dicionário Base
      Map<String, dynamic> pedidoMontado = {
        "titulo": dadosLocal['NOME_BADGE'] ?? 'Badge',
        "status": statusInicial,
        "dataAtualizacao": _formatarData(dadosLocal['DATA_ULTIMA_ATUALIZACAO']),
        "comentario": dadosLocal['COMENTARIO_CONSULTOR'],
        "historico": historicoLocal,
        "ficheiros": (dadosLocal['evidencias'] as List?)?.map((e) {
              String reqNome = _formatarNomeRequisito(
                  e['TITULO_REQUISITO'], dadosLocal['NOME_NIVEL'] ?? '');
              return {
                "nome": e['NOME_FICHEIRO'] ?? 'Documento',
                "ficheiro": e['URL_FICHEIRO'] ?? '',
                "requisito": reqNome
              };
            }).toList() ??
            [],
        "sl": dadosLocal['SERVICE_LINE'] ?? 'N/A',
        "area": dadosLocal['NOME_AREA'] ?? 'N/A',
        "nivel": dadosLocal['NOME_NIVEL'] ?? 'N/A',
        "validade": dadosLocal['VALIDADE_MESES'],
        "pontos": dadosLocal['PONTOS_BADGE'] ?? 0,
        "id_badge": dadosLocal['ID_BADGE'],
        "urlImagem": dadosLocal['URL_IMAGEM'],
      };

      // 4. Buscar API para enriquecer
      if (dadosLocal['IS_SINCRONIZADO'] == 1) {
        try {
          final dadosApi =
              await ApiServico().obterDetalhesPedidoApi(widget.idPedido);
          if (dadosApi != null) {
            if (dadosApi['status'] != null) {
              pedidoMontado['status'] = dadosApi['status'];
            }
            if (dadosApi['ultimoEstado'] != null)
              pedidoMontado['dataAtualizacao'] = dadosApi['ultimoEstado'];

            var timelineApi = dadosApi['timeline'] as List? ?? [];
            if (timelineApi.isNotEmpty) {
              List<Map<String, dynamic>> histFormatado = [
                {
                  "passo": "Pedido submetido",
                  "data": _formatarData(dadosLocal['DATA_SUBMISSAO_PEDIDO']),
                  "status": "success",
                  "subtitulo": "Consultor"
                },
              ];
              for (var h in timelineApi) {
                histFormatado.add({
                  "passo": h['acao'] ?? 'Ação',
                  "data": h['data'] ?? '',
                  "status": h['iconType'] ?? 'info',
                  "subtitulo": h['user'] ?? 'Sistema'
                });
              }
              pedidoMontado['historico'] = histFormatado;
            }

            var evidenciasApi = dadosApi['evidencias'] as List? ?? [];
            if (evidenciasApi.isNotEmpty) {
              pedidoMontado['ficheiros'] = evidenciasApi.map((e) {
                String req = e['req'] ?? 'Não mapeado';

                // Fallback: se a API vier desatualizada ("Não mapeado" ou "Requisito 1"), tentamos obter da base local
                if (req == 'Não mapeado' ||
                    req.toLowerCase().startsWith('requisito ')) {
                  var fichLocal = (dadosLocal['evidencias'] as List?)
                      ?.firstWhere(
                          (f) =>
                              f['URL_FICHEIRO'] == e['url'] ||
                              f['URL_FICHEIRO'] == e['ficheiro'],
                          orElse: () => null);
                  if (fichLocal != null &&
                      fichLocal['TITULO_REQUISITO'] != null) {
                    req = _formatarNomeRequisito(fichLocal['TITULO_REQUISITO'],
                        dadosLocal['NOME_NIVEL'] ?? '');
                  } else if (req.toLowerCase().startsWith('requisito ')) {
                    req = _formatarNomeRequisito(
                        req, dadosLocal['NOME_NIVEL'] ?? '');
                  }
                }

                return {
                  "nome": e['doc'] ?? e['ficheiro'] ?? 'Documento',
                  "ficheiro": e['url'] ?? '',
                  "requisito": req
                };
              }).toList();
            }
          }
        } catch (e) {
          print("API falhou, usando offline puro: $e");
        }
      }

      setState(() {
        _dadosPedido = pedidoMontado;
        _isLoading = false;
      });
    } catch (e) {
      print("Erro global ao carregar detalhes: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatarAcao(String estado) {
    if (estado == 'Aceite' || estado == 'Aprovado') return "Aprovou o pedido";
    if (estado == 'Devolvido' || estado == 'Em Correção')
      return "Devolveu para correção";
    if (estado == 'Recusado' || estado == 'Rejeitado')
      return "Rejeitou o pedido";
    return "Validou e enviou para o SLL";
  }

  String _formatarStatusColor(String estado) {
    if (estado == 'Aceite' || estado == 'Aprovado') return "success";
    if (estado == 'Recusado' || estado == 'Rejeitado') return "danger";
    if (estado == 'Devolvido' || estado == 'Em Correção') return "warning";
    return "success"; // Validação
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return '';
    try {
      DateTime dt = DateTime.parse(dataIso);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dataIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_dadosPedido == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detalhes do Pedido")),
        body: const Center(child: Text("Pedido não encontrado.")),
      );
    }

    // Determinar cores e ícones com base no status
    Color corPrincipal;
    IconData iconeStatus;
    String statusAt = _dadosPedido!['status'] ?? '';

    if (statusAt == 'Aprovado' || statusAt == 'Aceite') {
      corPrincipal = Colors.green;
      iconeStatus = Icons.check_circle;
    } else if (statusAt == 'Rejeitado' || statusAt == 'Recusado') {
      corPrincipal = Colors.red;
      iconeStatus = Icons.cancel;
    } else if (statusAt == 'Devolvido' || statusAt == 'Em Correção') {
      corPrincipal = Colors.amber.shade700;
      iconeStatus = Icons.warning_amber_rounded;
    } else if (statusAt == 'Rascunho') {
      corPrincipal = Colors.grey;
      iconeStatus = Icons.edit_document;
    } else {
      // Em Análise
      corPrincipal = const Color(0xFF0980E9); // Light blue instead of orange
      iconeStatus = Icons.hourglass_top_rounded;
    }

    // Agrupar ficheiros por requisito
    Map<String, List<Map<String, dynamic>>> ficheirosPorRequisito = {};
    for (var f in (_dadosPedido!['ficheiros'] ?? [])) {
      String req = f['requisito'] ?? 'Não mapeado';
      if (!ficheirosPorRequisito.containsKey(req)) {
        ficheirosPorRequisito[req] = [];
      }
      ficheirosPorRequisito[req]!.add(f);
    }

    // Para ordenar: Mostrar "Não mapeado" no final
    var chavesOrdenadas = ficheirosPorRequisito.keys.toList();
    chavesOrdenadas.sort((a, b) {
      if (a == 'Não mapeado') return 1;
      if (b == 'Não mapeado') return -1;
      return a.compareTo(b);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF34659D),
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo_softinsa.png',
          height: 35,
          errorBuilder: (c, e, s) => const Text("SOFTINSA",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ÁREA AZUL SUPERIOR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF34659D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Status Atual:",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  // CÍRCULO DO STATUS
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(iconeStatus, size: 80, color: corPrincipal),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _dadosPedido!['status'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Atualizado a ${_dadosPedido!['dataAtualizacao']}",
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD INFO BADGE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        const Text("Informação do Badge",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipOval(
                                child: ImagemBadgeMobile(
                                  urlImagem:
                                      _dadosPedido!['urlImagem']?.toString(),
                                  tamanho: 48,
                                  padding: const EdgeInsets.all(3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_dadosPedido!['titulo'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(_dadosPedido!['sl'],
                                      style: const TextStyle(
                                          color: Color(0xFF0980E9),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                      "${_dadosPedido!['area']} - Nível ${_dadosPedido!['nivel'] ?? ''}",
                                      style: const TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            Expanded(
                                child: _infoBadgeCurta(
                                    "Nível", _dadosPedido!['nivel'] ?? 'N/A')),
                            Expanded(
                              child: _infoBadgeCurta(
                                "Pontos",
                                "${_dadosPedido!['pontos'] ?? 0} PTS",
                                alinhamento: CrossAxisAlignment.center,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: _infoBadgeCurta(
                                "Validade",
                                _dadosPedido!['validade'] != null
                                    ? "${_dadosPedido!['validade']} meses"
                                    : "Sem validade",
                                alinhamento: CrossAxisAlignment.end,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Histórico de Validação",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 20),

                  // TIMELINE DA VALIDAÇÃO
                  ...((_dadosPedido!['historico'] ?? []) as List)
                      .asMap()
                      .entries
                      .map((entry) {
                    int idx = entry.key;
                    var passo = entry.value;
                    bool isLast =
                        idx == (_dadosPedido!['historico'].length - 1);
                    return _construirPassoTimeline(
                        passo['passo'],
                        passo['data'],
                        passo['status'],
                        passo['subtitulo'],
                        isLast);
                  }).toList(),

                  const SizedBox(height: 30),
                  const Text(
                    "Evidências Submetidas",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 15),

                  // LISTA DE FICHEIROS AGRUPADOS POR REQUISITO
                  ...chavesOrdenadas.map((reqKey) {
                    var ficheirosReq = ficheirosPorRequisito[reqKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reqKey,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34659D)),
                        ),
                        const SizedBox(height: 10),
                        ...ficheirosReq.map((f) =>
                            _construirCardFicheiro(f['nome'], f['ficheiro'])),
                        const SizedBox(height: 15),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 30),

                  // BOTÃO DE DETALHES DO BADGE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.push('/badge_detalhe', extra: {
                        'idBadge': _dadosPedido!['id_badge'],
                        'from': 'catalogo'
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34659D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Ver Detalhes do Badge",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET PARA CADA LINHA DO HISTÓRICO
  Widget _construirPassoTimeline(String descricao, String data,
      String statusType, String subtitulo, bool ultimo) {
    Color corIcone = Colors.green;
    IconData icone = Icons.check_circle;

    if (statusType == "warning" || statusType == "pending") {
      corIcone = Colors.amber.shade700;
      icone = Icons.hourglass_top;
    } else if (statusType == "danger") {
      corIcone = Colors.red;
      icone = Icons.cancel;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              icone,
              color: corIcone,
              size: 24,
            ),
            if (!ultimo)
              Container(
                width: 2,
                height: 64,
                color: corIcone,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descricao,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    data,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(" • ",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const Icon(Icons.person, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      subtitulo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET PARA OS CARDS DE FICHEIRO
  Widget _construirCardFicheiro(String nomeFicheiro, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && uri.hasScheme) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: Colors.grey, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nomeFicheiro,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34659D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.download, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("Ver / Download",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
