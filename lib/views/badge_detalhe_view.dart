import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/conectividade_servico.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_servico.dart';
import '../components/imagem_badge_mobile.dart';

// Enum para definir de onde viemos (estado do badge)
enum ModoDetalheBadge { catalogo, obtidoNormal, obtidoPremium }

class BadgeDetalheView extends StatefulWidget {
  final int idBadge;
  final String? from;

  const BadgeDetalheView({super.key, required this.idBadge, this.from});

  @override
  State<BadgeDetalheView> createState() => _BadgeDetalheViewState();
}

class _BadgeDetalheViewState extends State<BadgeDetalheView> {
  ModoDetalheBadge _modoAtual = ModoDetalheBadge.catalogo;
  bool _isLoading = true;
  Map<String, dynamic>? _badgeData;
  int _idUtilizador = 1;

  @override
  void initState() {
    super.initState();
    _carregarBadge();
  }

  Future<void> _carregarBadge() async {
    final bd = BDLocalAjudante();
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final detalhe = await bd.obterBadgeDetalhe(widget.idBadge, idUtilizador);

    if (!mounted) return;
    setState(() {
      _idUtilizador = idUtilizador;
      _badgeData = detalhe;
      if (detalhe != null) {
        if (widget.from == 'catalogo') {
          _modoAtual = ModoDetalheBadge.catalogo;
        } else if (detalhe['obtido'] == true) {
          _modoAtual = detalhe['isPremium'] == true
              ? ModoDetalheBadge.obtidoPremium
              : ModoDetalheBadge.obtidoNormal;
        } else {
          _modoAtual = ModoDetalheBadge.catalogo;
        }
      }
      _isLoading = false;
    });
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

  String _textoNivel(Map<String, dynamic> badge) {
    final letra = badge['nivel']?.toString() ?? '';
    final nome = badge['nomeNivel']?.toString() ?? 'Nível $letra';
    if (nome.contains('(')) return nome;
    return "$nome ($letra)";
  }

  String _textoValidadeCatalogo() {
    final meses = _badgeData!['validadeMeses'];
    if (_badgeData!['isPremium'] == true || meses == null || meses == 0) {
      return "Sem expiração";
    }
    return "Expiração: $meses meses após obtenção";
  }

  void _partilharLinkedIn() async {
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Precisa de internet para partilhar.'),
            backgroundColor: Colors.red));
      return;
    }

    if (_badgeData == null || _badgeData!['linkUnico'] == null) return;

    final urlPublica =
        "https://softinsa-plataforma.onrender.com/verificacao/${_badgeData!['linkUnico']}";
    final urlPartilha =
        "https://softinsa-api-riya.onrender.com/partilha/linkedin/badge/${_badgeData!['linkUnico']}";

    final texto =
        'Acabei de conquistar o badge "${_badgeData!['titulo']}" na Plataforma de Badges Softinsa!\n\n'
        '• Service Line: ${_badgeData!['serviceLine'] ?? 'Geral'}\n'
        '• Área: ${_badgeData!['area'] ?? 'Geral'}\n'
        '• Nível: ${_badgeData!['nivel'] ?? 'Geral'}\n'
        '• Atribuído a: ${_formatarData(_badgeData!['dataObtencao'])}\n'
        '• Validade: ${_badgeData!['dataExpiracao'] == null ? 'Sem validade (Vitalício)' : 'Até ${_formatarData(_badgeData!['dataExpiracao'])}'}';

    final textoParaCopiar =
        '$texto\n\nDescubra mais aqui: $urlPublica\n#Softinsa #Badges #Certificação';

    await Clipboard.setData(ClipboardData(text: textoParaCopiar));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Texto copiado! A abrir LinkedIn para partilha... Cole o texto na sua publicação.'),
          backgroundColor: Color(0xFF0077b5),
        ),
      );
    }

    final urlPartilhaComCache =
        '$urlPartilha?v=${DateTime.now().millisecondsSinceEpoch}';
    final linkedinUrl = Uri.parse(
        "https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(urlPartilhaComCache)}");
    await launchUrl(linkedinUrl, mode: LaunchMode.externalApplication);
  }

  void _downloadCertificado() async {
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Precisa de internet para transferir.'),
            backgroundColor: Colors.red));
      return;
    }

    if (_badgeData == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A iniciar download do Certificado Oficial...'),
          backgroundColor: Colors.green,
        ),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwtToken');
      final urlCertificado = Uri.parse(
          "${ApiServico.baseUrl}/meus-badges/consultor/$_idUtilizador/badge/${widget.idBadge}/certificado");
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
      final nomeSeguro = (_badgeData!['titulo']?.toString() ?? 'badge')
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final file = File('${dir.path}/Certificado_$nomeSeguro.pdf');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao descarregar certificado: $e')),
      );
    }
  }

  Widget _buildIconBadgeFallback() {
    return Icon(
      _modoAtual == ModoDetalheBadge.obtidoPremium
          ? Icons.workspace_premium
          : Icons.shield,
      size: 80,
      color: _modoAtual == ModoDetalheBadge.obtidoPremium
          ? Colors.amber.shade700
          : const Color(0xFF34659D),
    );
  }

  void _abrirLinkPublico() async {
    if (_badgeData == null || _badgeData!['linkUnico'] == null) return;
    final url = Uri.parse(
        "https://softinsa-plataforma.onrender.com/verificacao/${_badgeData!['linkUnico']}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link.')));
    }
  }

  void _renovarBadge() async {
    if (_badgeData == null) return;

    int diasRestantes = 0;
    if (_badgeData!['dataExpiracao'] != null) {
      DateTime dataExp = DateTime.parse(_badgeData!['dataExpiracao']);
      diasRestantes = (dataExp.difference(DateTime.now()).inMilliseconds /
              Duration.millisecondsPerDay)
          .ceil();
    }

    final bool confirmar = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Renovar Badge'),
            content: const Text(
                'Deseja iniciar o processo de renovação? O Badge deixará de estar ativo no seu perfil até ser novamente aprovado (se tiver 0 dias).'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Renovar',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    bool temNet = await ConectividadeServico().temInternet();

    // Se estiver online, forçar o apagamento imediato na cloud (API)
    if (temNet && diasRestantes <= 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwtToken') ?? '';
        final res = await http.post(
            Uri.parse('${ApiServico.baseUrl}/pedidos/consultor/renovar'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode(
                {'idUtilizador': _idUtilizador, 'idBadge': widget.idBadge}));

        if (res.statusCode != 200 && res.statusCode != 201) {
          final erro = jsonDecode(res.body)['message'] ?? 'Erro ao renovar.';
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Erro da API: $erro'),
                backgroundColor: Colors.red));
          return; // Cancelar fluxo pois a API falhou
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Falha na comunicação com o servidor. A manter offline.'),
              backgroundColor: Colors.orange));
        // Se a internet estiver instável e falhar, prossegue com o fluxo offline (apaga apenas local)
      }
    }

    final dbHelper = BDLocalAjudante();
    final db = await dbHelper.database;

    final resultConsultor = await db.rawQuery(
        'SELECT ID_CONSULTOR FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [_idUtilizador]);
    if (resultConsultor.isEmpty) return;
    int idConsultor = resultConsultor.first['ID_CONSULTOR'] as int;

    if (diasRestantes <= 0) {
      // Remover badge localmente (vai para o catálogo) pois expirou totalmente
      await db.rawDelete(
          'DELETE FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ? AND ID_BADGE = ?',
          [idConsultor, widget.idBadge]);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pronto a renovar! Anexe as novas evidências para prosseguir.'),
          backgroundColor: Colors.green,
        ),
      );
      // Redireciona para o ecrã de candidatura igual à Web!
      context.push('/candidatura', extra: {'idBadge': widget.idBadge});
    }
  }

  void _partilharEmail() async {
    if (_badgeData == null) return;

    final urlPublica =
        "https://softinsa-plataforma.onrender.com/verificacao/${_badgeData!['linkUnico'] ?? ''}";
    final imagemBadge = _badgeData!['urlImagem']?.toString() ??
        '${ApiServico.baseUrl}/uploads/default-trophy.png';
    final assinaturaBase = '''
Conquistei o badge "${_badgeData!['titulo']}" da Softinsa!

Verifique o meu badge oficial aqui:
$urlPublica

Imagem do badge: $imagemBadge
''';

    await Clipboard.setData(ClipboardData(text: assinaturaBase));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Assinatura copiada para a área de transferência! Pode colar diretamente no seu email (Outlook/Gmail).'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_badgeData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Badge não encontrado.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9), // Fundo Cinza claro global
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // MENSAGEM DE PARABÉNS (Só aparece se já foi obtido e NAO veio do catalogo global)
                  if (_modoAtual != ModoDetalheBadge.catalogo) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 15),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34659D), Color(0xFF0980E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ]),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.amber, size: 50),
                          const SizedBox(height: 10),
                          const Text(
                            "Parabéns, obteve este Badge!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 30),
                  ],

                  // ÍCONE DO BADGE CENTRAL
                  GestureDetector(
                    onTap: () {
                      if (_badgeData!['obtido'] == true &&
                          _badgeData!['linkUnico'] != null) {
                        _abrirLinkPublico();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _modoAtual == ModoDetalheBadge.obtidoPremium
                            ? Colors.amber.withOpacity(0.1)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _modoAtual == ModoDetalheBadge.obtidoPremium
                              ? Colors.amber
                              : const Color(0xFF34659D),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 5)
                        ],
                      ),
                      child: ClipOval(
                        child: ImagemBadgeMobile(
                          urlImagem: _badgeData!['urlImagem']?.toString(),
                          tamanho: 128,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // TÍTULO E SERVICE LINE
                  Text(
                    _badgeData!['titulo'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _badgeData!['sl']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF34659D),
                        fontWeight: FontWeight.bold,
                        height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Área: ${_badgeData!['area']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _textoNivel(_badgeData!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // PONTUAÇÃO (Pill) E EXPIRAÇÃO (SE CATÁLOGO)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars,
                            color: Color(0xFF34659D), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "+ ${_badgeData!['pontos']} Pontos",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34659D)),
                        ),
                      ],
                    ),
                  ),
                  if (_modoAtual == ModoDetalheBadge.catalogo) ...[
                    const SizedBox(height: 15),
                    Text(
                      _textoValidadeCatalogo(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textoValidadeCatalogo() == "Sem expiração"
                              ? Colors.green
                              : Colors.orange),
                    ),
                  ] else ...[
                    const SizedBox(height: 15),
                    Text(
                      "Conquistado a ${_formatarData(_badgeData!['dataObtencao'])}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 5),
                    if (_modoAtual == ModoDetalheBadge.obtidoNormal)
                      Text(
                        _badgeData!['dataExpiracao'] != null
                            ? "Expira a ${_formatarData(_badgeData!['dataExpiracao'])}"
                            : (_badgeData!['validadeMeses'] == null ||
                                    _badgeData!['validadeMeses'] == 0
                                ? "Sem expiração"
                                : "Válido por ${_badgeData!['validadeMeses']} meses"),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      )
                    else
                      const Text(
                        "Premium (Sem expiração)",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34659D)),
                      ),
                  ],
                  const SizedBox(height: 35),

                  // ==========================================
                  // CONTEÚDO DINÂMICO CONSOANTE O MODO
                  // ==========================================

                  if (_modoAtual == ModoDetalheBadge.catalogo)
                    _construirRequisitosCatalogo()
                  else
                    _construirAcoesBadgeObtido(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET 1: Requisitos (Modo Catálogo)
  Widget _construirRequisitosCatalogo() {
    int reqFeitos =
        _badgeData!['requisitos'].where((r) => r['concluido'] == true).length;
    int totalReq = _badgeData!['requisitosTotal'];

    return Column(
      children: [
        Text(
          _badgeData!['descricao'],
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Requisitos Necessários:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 30),
              ..._badgeData!['requisitos'].map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          r['concluido']
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: r['concluido']
                              ? const Color(0xFF0980E9)
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['titulo'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: r['concluido']
                                          ? Colors.black87
                                          : Colors.grey)),
                              const SizedBox(height: 4),
                              Text(r['desc'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: r['concluido']
                                          ? Colors.black54
                                          : Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _badgeData!['obtido'] == true
                ? null
                : () => context
                    .push('/candidatura', extra: {'idBadge': widget.idBadge}),
            style: ElevatedButton.styleFrom(
              backgroundColor: _badgeData!['obtido'] == true
                  ? Colors.grey.shade400
                  : const Color(0xFF0980E9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
                _badgeData!['obtido'] == true
                    ? "Badge Já Obtido"
                    : "Candidatar a este Badge",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // WIDGET 2: Botões de Ação (Modo Obtido Normal / Premium)
  Widget _construirAcoesBadgeObtido() {
    // Verificar se expira em menos de 30 dias para mostrar o botão Renovar
    bool precisaRenovar = false;
    if (_modoAtual == ModoDetalheBadge.obtidoNormal &&
        _badgeData!['dataExpiracao'] != null) {
      try {
        DateTime dataExp = DateTime.parse(_badgeData!['dataExpiracao']);
        final diasRestantes =
            (dataExp.difference(DateTime.now()).inMilliseconds /
                    Duration.millisecondsPerDay)
                .ceil();
        if (diasRestantes <= 30) {
          precisaRenovar = true;
        }
      } catch (e) {
        // Ignora erros de parse e oculta o botão
      }
    }

    final String urlPublica =
        "https://softinsa-plataforma.onrender.com/badge/${_badgeData!['linkUnico'] ?? ''}";

    return Column(
      children: [
        if (precisaRenovar) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _renovarBadge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.autorenew, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Renovar (+30 dias)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
        ],

        // BOTÃO LINKEDIN
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _partilharLinkedIn,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF0077b5), // Cor oficial do LinkedIn
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.share, color: Colors.white),
                SizedBox(width: 10),
                Text("Partilhar no LinkedIn",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÃO DOWNLOAD CERTIFICADO PDF
        SizedBox(
          width: double.infinity,
          height: 65,
          child: ElevatedButton(
            onPressed: _downloadCertificado,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Color(0xFF34659D), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.picture_as_pdf, color: Color(0xFF34659D)),
                SizedBox(width: 10),
                Text("Fazer Download do\nCertificado",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF34659D),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÃO PARTILHAR EMAIL
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _partilharEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Color(0xFF34659D), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.email, color: Color(0xFF34659D)),
                SizedBox(width: 10),
                Text("Partilhar por Email",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF34659D),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 35),

        // Link Público do Badge
        const Text("Link de Verificação Público:",
            style: TextStyle(
                fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _abrirLinkPublico,
          child: Text(
            urlPublica,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0980E9),
                decoration: TextDecoration.underline),
          ),
        )
      ],
    );
  }
}
