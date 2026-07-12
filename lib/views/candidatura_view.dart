import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import '../components/imagem_badge_mobile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/conectividade_servico.dart';
import '../services/api_servico.dart';
import '../services/file_validator.dart';
import '../services/sincronizador.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

class CandidaturaView extends StatefulWidget {
  final int? idBadge;
  final int? passoInicial;
  const CandidaturaView({super.key, this.idBadge, this.passoInicial});

  @override
  State<CandidaturaView> createState() => _CandidaturaViewState();
}

class _CandidaturaViewState extends State<CandidaturaView> {
  int _passoAtual = 1;
  bool _estaACarregar = false;
  int? _idPedidoSubmetido;

  // --- Filtros ---
  String _servicoEscolhido = "Todas as Service Lines";
  String _areaEscolhida = "Todas as Áreas";
  List<String> _todasAreas = ["Todas as Áreas"];
  List<String> _todosNiveis = [];
  List<String> _niveisSelecionados = [];

  void _atualizarAreasPorSL(String sl) {
    _servicoEscolhido = sl;
    _areaEscolhida = "Todas as Áreas";
    if (sl == "Todas as Service Lines") {
      _todasAreas = [
        "Todas as Áreas",
        ..._listaBadgesCatalogo.map((e) => e['area'].toString()).toSet()
      ];
    } else {
      _todasAreas = [
        "Todas as Áreas",
        ..._listaBadgesCatalogo
            .where((e) => e['sl'] == sl)
            .map((e) => e['area'].toString())
            .toSet()
      ];
    }
    _atualizarNiveis();
  }

  void _atualizarNiveis() {
    var badges = _listaBadgesCatalogo;
    if (_servicoEscolhido != "Todas as Service Lines") {
      badges = badges.where((e) => e['sl'] == _servicoEscolhido).toList();
    }
    if (_areaEscolhida != "Todas as Áreas") {
      badges = badges.where((e) => e['area'] == _areaEscolhida).toList();
    }
    _todosNiveis = badges.map((e) => e['nivel'].toString()).toSet().toList();
    _todosNiveis.sort();
    _niveisSelecionados.removeWhere((n) => !_todosNiveis.contains(n));
  }

  Map<String, dynamic>? _badgeSelecionado;
  List<PlatformFile> _ficheirosAnexados = [];
  bool _termosAceites = false;

  Future<void> _carregarRascunhoFicheiros(int idBadge) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = 'rascunho_candidatura_$idBadge';
    final dados = prefs.getStringList(chave);
    List<PlatformFile> carregados = [];
    if (dados != null) {
      for (var stringf in dados) {
        final mapa = jsonDecode(stringf);
        carregados.add(PlatformFile(
          name: mapa['name'],
          path: mapa['path'],
          size: mapa['size'],
          bytes: null,
        ));
      }
    }

    final idUtilizador = prefs.getInt('idUtilizador') ?? -1;
    final db = await BDLocalAjudante().database;
    final pedidoRascunho = await db.rawQuery('''
      SELECT ID_PEDIDO
      FROM PEDIDO
      WHERE ID_UTILIZADOR = ?
        AND ID_BADGE = ?
        AND ESTADO_PEDIDO IN ('Rascunho', 'Pendente de Correção')
      ORDER BY DATA_ULTIMA_ATUALIZACAO DESC, ID_PEDIDO DESC
      LIMIT 1
    ''', [idUtilizador, idBadge]);

    if (pedidoRascunho.isNotEmpty) {
      final evidencias = await db.query(
        'EVIDENCIA',
        where: 'ID_PEDIDO = ?',
        whereArgs: [pedidoRascunho.first['ID_PEDIDO']],
      );
      final nomesJaCarregados = carregados.map((f) => f.name).toSet();
      for (final ev in evidencias) {
        final nome = ev['NOME_FICHEIRO']?.toString() ?? 'ficheiro';
        if (nomesJaCarregados.contains(nome)) continue;
        carregados.add(PlatformFile(
          name: nome,
          path: ev['URL_FICHEIRO']?.toString(),
          size: 0,
          bytes: null,
        ));
      }
    }

    if (carregados.isNotEmpty) {
      setState(() {
        _ficheirosAnexados = carregados;
      });
      _verificarRequisitosConcluidos();
    }
  }

  Future<void> _guardarRascunhoFicheiros() async {
    if (_badgeSelecionado == null) return;
    final prefs = await SharedPreferences.getInstance();
    final chave = 'rascunho_candidatura_${_badgeSelecionado!['id']}';
    List<String> paraGuardar = _ficheirosAnexados
        .map((f) => jsonEncode({
              'name': f.name,
              'path': f.path,
              'size': f.size,
            }))
        .toList();
    await prefs.setStringList(chave, paraGuardar);
  }

  Future<void> _escolherFicheiros() async {
    FilePickerResult? resultado = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: FileValidator.allowedExtensions,
    );

    if (resultado != null) {
      setState(() {
        _ficheirosAnexados.addAll(resultado.files);
      });
      _guardarRascunhoFicheiros();
      _verificarRequisitosConcluidos();
    }
  }

  void _verificarRequisitosConcluidos() {
    if (_badgeSelecionado == null) return;
    setState(() {
      for (var req in _badgeSelecionado!['requisitos']) {
        req['concluido'] = false;
        req['ficheiros'] = <PlatformFile>[]; // clear mapped files
      }

      for (var ficheiro in _ficheirosAnexados) {
        String? reqMapeado =
            FileValidator.extrairRequisitoDoNome(ficheiro.name);
        if (reqMapeado != null) {
          // Procurar o requisito com este ID e mapear
          for (var req in _badgeSelecionado!['requisitos']) {
            final idReq = req['id']?.toString() ?? '';
            final tituloReq = req['titulo']?.toString() ?? '';
            if (FileValidator.textoContemCodigoRequisito(idReq, reqMapeado) ||
                FileValidator.textoContemCodigoRequisito(
                    tituloReq, reqMapeado)) {
              req['concluido'] = true;
              (req['ficheiros'] as List).add(ficheiro);
            }
          }
        }
      }
    });
  }

  void _removerFicheiroAnexado(PlatformFile f) {
    setState(() {
      _ficheirosAnexados.remove(f);
      _verificarRequisitosConcluidos();
      _guardarRascunhoFicheiros();
    });
  }

  Future<void> _mostrarTermosRGPD() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res =
          await http.get(Uri.parse('${ApiServico.baseUrl}/configuracoes/rgpd'));
      if (mounted) Navigator.pop(context); // fechar loading

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        final termos =
            data['RGPD_TERMOS'] ?? 'Termos e condições não definidos.';
        final politicas =
            data['RGPD_POLITICAS'] ?? 'Políticas de privacidade não definidas.';

        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text("Termos e Políticas"),
              content: SingleChildScrollView(
                child: Text(
                    "--- TERMOS E CONDIÇÕES ---\n\n$termos\n\n\n--- POLÍTICAS RGPD ---\n\n$politicas"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Fechar"),
                )
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao carregar políticas.')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // fechar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Sem ligação. Não foi possível carregar as políticas.')));
      }
    }
  }

  Future<void> _selecionarBadge(int idBadge) async {
    setState(() => _estaACarregar = true);
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? -1;
    final dados =
        await BDLocalAjudante().obterBadgeDetalhe(idBadge, idUtilizador);
    if (!mounted) return;

    if (dados != null) {
      // Mapear requisitos para serem mutáveis e compatíveis com a UI (concluido)
      List<Map<String, dynamic>> requisitosMutaveis = [];
      if (dados['requisitos'] != null) {
        for (var req in dados['requisitos']) {
          requisitosMutaveis.add({
            'id': req['id'],
            'titulo': req['titulo']?.toString() ?? req['id'].toString(),
            'desc': req['desc']?.toString() ?? '',
            'ordem': req['ordem'],
            'concluido':
                false, // Novo pedido, nenhum requisito está concluído ainda
            'ficheiros': <PlatformFile>[],
          });
        }
      }
      dados['requisitos'] = requisitosMutaveis;

      setState(() {
        _badgeSelecionado = dados;
        _ficheirosAnexados = []; // Reset aos ficheiros ao escolher outro badge
        _estaACarregar = false;
        _passoAtual = widget.passoInicial ??
            2; // Dashboard pode abrir direto nas evidências
      });

      _carregarRascunhoFicheiros(idBadge);
    } else {
      setState(() => _estaACarregar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar detalhes do badge.')),
      );
    }
  }

  void _alternarNivel(String nivel) {
    setState(() {
      _niveisSelecionados.contains(nivel)
          ? _niveisSelecionados.remove(nivel)
          : _niveisSelecionados.add(nivel);
    });
  }

  String _mimePorNome(String nome) {
    final ext = nome.split('.').last.toLowerCase();
    const mimes = {
      'pdf': 'application/pdf',
      'txt': 'text/plain; charset=utf-8',
      'csv': 'text/csv; charset=utf-8',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };
    return mimes[ext] ?? 'application/octet-stream';
  }

  String _textoNivel(Map<String, dynamic> badge) {
    final letra = badge['nivel']?.toString() ?? '';
    final nome = badge['nomeNivel']?.toString() ?? 'Nível $letra';
    if (nome.contains('(')) return nome;
    return "$nome ($letra)";
  }

  String _tituloRequisito(Map<String, dynamic> requisito) {
    final titulo = requisito['titulo']?.toString().trim() ?? '';
    if (titulo.isNotEmpty &&
        !RegExp(r'^Requisito\s+\d+$', caseSensitive: false).hasMatch(titulo)) {
      return titulo;
    }

    final letraNivel = _badgeSelecionado?['nivel']?.toString().trim();
    final ordem = requisito['ordem'];
    final ordemNum =
        ordem is num ? ordem.toInt() : int.tryParse(ordem?.toString() ?? '');
    if (letraNivel != null && letraNivel.isNotEmpty && ordemNum != null) {
      return 'Requisito ${letraNivel.toUpperCase()}$ordemNum';
    }

    return titulo.isNotEmpty ? titulo : 'Requisito';
  }

  void _avancar() async {
    setState(() => _estaACarregar = true);

    try {
      // Se estamos no passo final (antes da confirmação)
      if (_passoAtual == 3) {
        final prefs = await SharedPreferences.getInstance();
        final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

        // Construir o payload
        Map<String, dynamic> pedidoPayload = {
          'ID_UTILIZADOR': idUtilizador,
          'ID_BADGE': _badgeSelecionado!['id'] ??
              1, // Fallback caso o mock não tenha ID
          'ESTADO_PEDIDO': 'Rascunho',
          'DATA_SUBMISSAO_PEDIDO': DateTime.now().toIso8601String(),
          'DATA_ULTIMA_ATUALIZACAO': DateTime.now().toIso8601String(),
          'COMENTARIO_CONSULTOR': 'Submetido via App Mobile',
          'IS_SINCRONIZADO': 0,
        };

        // Guardar localmente primeiro (Offline-first approach)
        final bd = BDLocalAjudante();
        final dbAntes = await bd.database;
        final pedidosAtivos = await dbAntes.rawQuery('''
        SELECT ID_PEDIDO, ESTADO_PEDIDO
        FROM PEDIDO
        WHERE ID_UTILIZADOR = ?
          AND ID_BADGE = ?
          AND ESTADO_PEDIDO IN ('Pendente', 'Em Análise', 'Em Análise TM', 'Em Análise SLL', 'Pendente de Correção')
        ORDER BY DATA_ULTIMA_ATUALIZACAO DESC, ID_PEDIDO DESC
        LIMIT 1
      ''', [idUtilizador, pedidoPayload['ID_BADGE']]);
        if (pedidosAtivos.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Já existe uma candidatura ativa para este badge (${pedidosAtivos.first['ESTADO_PEDIDO']}). Acompanhe-a no histórico.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _estaACarregar = false);
          return;
        }

        await dbAntes.rawDelete('''
        DELETE FROM EVIDENCIA
        WHERE ID_PEDIDO IN (
          SELECT ID_PEDIDO FROM PEDIDO
          WHERE ID_UTILIZADOR = ? AND ID_BADGE = ? AND IS_SINCRONIZADO = 0
        )
      ''', [idUtilizador, pedidoPayload['ID_BADGE']]);
        await dbAntes.delete(
          'PEDIDO',
          where: 'ID_UTILIZADOR = ? AND ID_BADGE = ? AND IS_SINCRONIZADO = 0',
          whereArgs: [idUtilizador, pedidoPayload['ID_BADGE']],
        );
        int novoIdPedido = await bd.inserirPedidoOffline(pedidoPayload);
        pedidoPayload['ID_PEDIDO'] = novoIdPedido; // ID temporário local

        // Adicionar evidências usando os ficheiros reais anexados
        List<Map<String, dynamic>> evidencias = [];

        // Mapear titulo do requisito para ID_REQUISITO
        List<dynamic> requisitosDoBadge =
            _badgeSelecionado!['requisitos'] ?? [];

        for (PlatformFile file in _ficheirosAnexados) {
          if (file.path == null) continue;

          String? reqMapeadoStr =
              FileValidator.extrairRequisitoDoNome(file.name);
          int? idRequisitoEncontrado;

          if (reqMapeadoStr != null) {
            for (var req in requisitosDoBadge) {
              String titulo = req['titulo']?.toString() ?? '';
              String idReq = req['id']?.toString() ?? '';
              if (FileValidator.textoContemCodigoRequisito(
                      titulo, reqMapeadoStr) ||
                  FileValidator.textoContemCodigoRequisito(
                      idReq, reqMapeadoStr)) {
                idRequisitoEncontrado = int.tryParse(req['id'].toString());
                break;
              }
            }
          }

          String? base64String;
          final pathFicheiro = file.path!;
          if (!pathFicheiro.startsWith('http://') &&
              !pathFicheiro.startsWith('https://')) {
            File f = File(pathFicheiro);
            List<int> fileBytes = await f.readAsBytes();
            base64String = base64Encode(fileBytes);
          }

          final Map<String, dynamic> evidenciaObj = {
            'ID_PEDIDO': novoIdPedido,
            'NOME_FICHEIRO': file.name,
            'ID_REQUISITO': idRequisitoEncontrado,
            'REQUISITO_MAPEADO':
                idRequisitoEncontrado, // Pode ser null se não mapeado, o backend trata
            'URL_FICHEIRO': file.path,
            'MIME_TYPE': _mimePorNome(file.name),
            if (base64String != null) 'base64': base64String
          };

          // Guardar sem a string gigante de base64 no SQLite (guardamos só path local)
          final evidenciaBDLocal = Map<String, dynamic>.from(evidenciaObj);
          evidenciaBDLocal.remove('base64');
          await bd.inserirEvidenciaOffline(evidenciaBDLocal);

          // Na lista de payload para a API vai com o base64
          evidencias.add(evidenciaObj);
        }

        // Tentar enviar para a API se houver net (usando _apiServico, não Provider diretamente para não complicar a injeção aqui sem rever arvore)
        bool temNet = await ConectividadeServico().temInternet();

        if (temNet) {
          pedidoPayload['evidencias'] = evidencias;
          final resultadoEnvio =
              await ApiServico().enviarPedidoResposta(pedidoPayload);
          bool sucesso = resultadoEnvio['success'] == true;
          if (sucesso) {
            // Marca como sincronizado localmente
            final db = await bd.database;
            _idPedidoSubmetido =
                (resultadoEnvio['idPedido'] as num?)?.toInt() ?? novoIdPedido;
            await db.delete('EVIDENCIA',
                where: 'ID_PEDIDO = ?', whereArgs: [novoIdPedido]);
            await db.delete('PEDIDO',
                where: 'ID_PEDIDO = ?', whereArgs: [novoIdPedido]);
            await Sincronizador().sincronizarDadosIniciais();
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Não foi possível submeter agora. O rascunho foi mantido.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _estaACarregar = false);
            return;
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sem ligação. O pedido ficou como rascunho e será submetido automaticamente quando voltar a conexão.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _estaACarregar = false);
          return;
        }

        // Remover rascunho após submissão bem sucedida ou guardado localmente
        final chave = 'rascunho_candidatura_${_badgeSelecionado!['id']}';
        await prefs.remove(chave);
      } else {
        await Future.delayed(
            const Duration(milliseconds: 600)); // Simula tempo de rede no mock
      }

      setState(() {
        _estaACarregar = false;
        _passoAtual++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _estaACarregar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao submeter candidatura: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recuar() {
    setState(() {
      if (_passoAtual > 1) _passoAtual--;
    });
  }

  // --- Lógica Dinâmica ---
  bool _isLoading = true;
  List<Map<String, dynamic>> _listaBadgesCatalogo = [];
  Map<String, dynamic>? _ultimoPedido;

  @override
  void initState() {
    super.initState();
    _carregarBadgesCatalogo();
    if (widget.idBadge != null) {
      _selecionarBadge(widget.idBadge!);
      if (widget.passoInicial != null) {
        _passoAtual = widget.passoInicial!;
      }
    }
  }

  Future<void> _carregarBadgesCatalogo() async {
    final bd = BDLocalAjudante();
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador');
    if (idUtilizador == null) return;
    if (await ConectividadeServico().temInternet()) {
      await Sincronizador().sincronizarDadosIniciais();
    }
    final dados = await bd.obterCatalogo(idUtilizador);
    final ultimo = await bd.obterUltimoPedidoCandidatura(idUtilizador);

    if (!mounted) return;
    setState(() {
      _listaBadgesCatalogo = dados['todos'];
      _ultimoPedido = ultimo;
      _atualizarAreasPorSL("Todas as Service Lines");
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _obterBadgesFiltrados() {
    return _listaBadgesCatalogo.where((badge) {
      bool slMatch = _servicoEscolhido == "Todas as Service Lines" ||
          badge["sl"] == _servicoEscolhido;
      bool areaMatch =
          _areaEscolhida == "Todas as Áreas" || badge["area"] == _areaEscolhida;
      bool nivelMatch = _niveisSelecionados.isEmpty ||
          _niveisSelecionados.contains(badge["nivel"]);
      return slMatch && areaMatch && nivelMatch;
    }).toList();
  }

  Color _obterCorStatus(String status) {
    if (status == "Aprovado" || status == "Aceite") return Colors.green;
    if (status == "Rejeitado" || status == "Recusado") return Colors.red;
    return Colors.orange; // Em Análise / Pendente
  }

  @override
  Widget build(BuildContext context) {
    if (_passoAtual >= 2) {
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
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _recuar,
          ),
        ),
        body: _estaACarregar
            ? const Center(child: CircularProgressIndicator())
            : _construirInterface(),
      );
    }

    return LayoutConsultor(
      indexMenuInferior: 2,
      corpo: _estaACarregar
          ? const Center(child: CircularProgressIndicator())
          : _construirInterface(),
    );
  }

  Widget _construirInterface() {
    switch (_passoAtual) {
      case 1:
        return _passo1Consulta();
      case 2:
        return _passo2DetalheBadge();
      case 3:
        return _passo3MultiUpload();
      case 4:
        return _passo4Confirmacao();
      default:
        return _passo1Consulta();
    }
  }

  // PASSO 1: CONSULTA DE BADGES
  Widget _passo1Consulta() {
    List<Map<String, dynamic>> badgesVisiveis = _obterBadgesFiltrados();

    return Stack(
      children: [
        // Fundo fixo dividido para o overscroll (topo azul, fundo cinza)
        Column(
          children: [
            Expanded(child: Container(color: const Color(0xFF34659D))),
            Expanded(child: Container(color: const Color(0xFFF4F5F9))),
          ],
        ),
        // Conteúdo Scrollável original
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF34659D),
                padding: const EdgeInsets.only(top: 30, bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_ultimoPedido != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("O SEU ÚLTIMO PEDIDO",
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 1.1)),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF4F5F9),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: ClipOval(
                                      child: ImagemBadgeMobile(
                                        urlImagem: _ultimoPedido?['URL_IMAGEM']
                                            ?.toString(),
                                        tamanho: 40,
                                        padding: const EdgeInsets.all(3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_ultimoPedido!['NOME_BADGE'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text(
                                            "${_ultimoPedido!['SERVICE_LINE']} / ${_ultimoPedido!['NOME_AREA']} - Nível ${_ultimoPedido!['NOME_NIVEL']}",
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text("${_ultimoPedido!['PONTOS_BADGE']}",
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF34659D))),
                                      const Text("PTS",
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey)),
                                    ],
                                  )
                                ],
                              ),
                              const Divider(height: 30),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: _obterCorStatus(
                                                _ultimoPedido!['ESTADO_PEDIDO'])
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(_ultimoPedido!['ESTADO_PEDIDO'],
                                        style: TextStyle(
                                            color: _obterCorStatus(
                                                _ultimoPedido![
                                                    'ESTADO_PEDIDO']),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                  ),
                                  TextButton(
                                      onPressed: () => context
                                              .push('/pedido_status', extra: {
                                            'idPedido':
                                                _ultimoPedido!['ID_PEDIDO']
                                          }),
                                      child: const Text("Ver Detalhes",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline))),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFF4F5F9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Text("Candidatura a Novos Badges",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                    ),

                    // FILTROS
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("1. Selecione a Service Line",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _servicoEscolhido,
                                isExpanded: true,
                                items: [
                                  "Todas as Service Lines",
                                  ..._listaBadgesCatalogo
                                      .map((e) => e['sl'].toString())
                                      .toSet()
                                ]
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _atualizarAreasPorSL(v!)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("2. Selecione a Área",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _areaEscolhida,
                                isExpanded: true,
                                items: _todasAreas
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _areaEscolhida = v!;
                                    _atualizarNiveis();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("3. Filtre por Níveis de Competência",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black54)),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _todosNiveis.map((n) {
                                bool sel = _niveisSelecionados.contains(n);
                                return GestureDetector(
                                  onTap: () => _alternarNivel(n),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 15),
                                    width: 52,
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF34659D)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF34659D),
                                          width: 1.5),
                                      boxShadow: sel
                                          ? [
                                              BoxShadow(
                                                  color: Colors.blue
                                                      .withOpacity(0.2),
                                                  blurRadius: 8)
                                            ]
                                          : null,
                                    ),
                                    child: Text(n,
                                        style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : const Color(0xFF34659D),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LISTA DE RESULTADOS DINÂMICA
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 10),
                      child: Text(
                          "Resultados Encontrados: ${badgesVisiveis.length}",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                    if (badgesVisiveis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Center(
                            child: Text(
                                "Nenhum badge encontrado para estes filtros.",
                                style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: badgesVisiveis.length,
                        itemBuilder: (context, index) {
                          var badge = badgesVisiveis[index];
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 20, left: 20, right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                if (badge['obtido'] == true) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Badge já obtido'),
                                        content: const Text(
                                            'Já possui este badge. Deseja ver os detalhes deste badge ou voltar à página de candidaturas?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Voltar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              context.push('/badge_detalhe',
                                                  extra: {
                                                    'idBadge': badge['id']
                                                  });
                                            },
                                            child: const Text('Ver Detalhes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  _selecionarBadge(badge['id']);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF4F5F9),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: ClipOval(
                                            child: ImagemBadgeMobile(
                                              urlImagem: badge['urlImagem']
                                                  ?.toString(),
                                              tamanho: 58,
                                              padding: const EdgeInsets.all(2),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                badge['titulo'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Service Line ${badge['sl']}",
                                                style: const TextStyle(
                                                  color: Color(0xFF4C51F7),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Área de ${badge['area']}",
                                                style: const TextStyle(
                                                  color: Color(0xFF555555),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _textoNivel(badge),
                                                style: const TextStyle(
                                                  color: Color(0xFF555555),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              "${badge['pontos']}",
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF34659D),
                                              ),
                                            ),
                                            const Text(
                                              "PTS",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.task_alt,
                                                color: Colors.grey, size: 16),
                                            const SizedBox(width: 5),
                                            Text(
                                              "${badge['numeroRequisitos']} Requisitos",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: badge['obtido'] == true
                                                ? Colors.grey.withOpacity(0.2)
                                                : const Color(0xFF0980E9)
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                              badge['obtido'] == true
                                                  ? "Badge já obtido"
                                                  : "Candidatar",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: badge['obtido'] == true
                                                      ? Colors.grey.shade600
                                                      : const Color(
                                                          0xFF0980E9))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PASSO 2: DETALHES DO BADGE PARA CANDIDATURA
  Widget _passo2DetalheBadge() {
    int reqFeitos = _badgeSelecionado!['requisitos']
        .where((r) => r['concluido'] == true)
        .length;
    int totalReq = _badgeSelecionado!['requisitosTotal'];

    bool obtido = _badgeSelecionado!['obtido'] ?? false;
    String? estadoPedido = _badgeSelecionado!['estadoPedido'];

    bool botaoAtivo = true;
    String textoBotao = "Candidatar ao Badge";

    if (obtido) {
      botaoAtivo = false;
      textoBotao = "Badge já Possuído";
    } else if (estadoPedido == 'Em Análise' || estadoPedido == 'Pendente') {
      botaoAtivo = false;
      textoBotao = "Pedido em Análise";
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF34659D), width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5)
              ],
            ),
            child: ClipOval(
              child: ImagemBadgeMobile(
                urlImagem: _badgeSelecionado!['urlImagem']?.toString(),
                tamanho: 118,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            _badgeSelecionado!['titulo'],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            _badgeSelecionado!['sl']?.toString() ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0980E9)),
          ),
          const SizedBox(height: 4),
          Text(
            _badgeSelecionado!['area']?.toString() ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
          const SizedBox(height: 2),
          Text(
            _textoNivel(_badgeSelecionado!),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
          const SizedBox(height: 15),
          Text(
            _badgeSelecionado!['descricao'],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Color(0xFF34659D), size: 24),
                const SizedBox(width: 8),
                Text(
                  "+ ${_badgeSelecionado!['pontos']} Pontos",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34659D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
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
                const Text("Requisitos:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(height: 30),
                ..._badgeSelecionado!['requisitos']
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.circle,
                                  color: Color(0xFF0980E9),
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['titulo']?.toString() ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87)),
                                    Text(r['desc'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: botaoAtivo ? _avancar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    botaoAtivo ? const Color(0xFF0980E9) : Colors.grey,
                elevation: botaoAtivo ? 4 : 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                textoBotao,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // PASSO 3: MULTI UPLOAD
  Widget _passo3MultiUpload() {
    bool todosRequisitosConcluidos = true;
    for (var r in _badgeSelecionado!['requisitos']) {
      if (r['concluido'] == false) {
        todosRequisitosConcluidos = false;
        break;
      }
    }

    // Calcular ficheiros não mapeados
    List<PlatformFile> ficheirosNaoMapeados = [];
    for (var f in _ficheirosAnexados) {
      bool mapeado = false;
      for (var req in _badgeSelecionado!['requisitos']) {
        if ((req['ficheiros'] as List).contains(f)) {
          mapeado = true;
          break;
        }
      }
      if (!mapeado) ficheirosNaoMapeados.add(f);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Carregue as suas evidências",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 15),
          Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF0980E9).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Color(0xFF0980E9), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                      child: RichText(
                          text: const TextSpan(
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF34659D),
                                  height: 1.4),
                              children: [
                        TextSpan(
                            text: "Regra de Associação Automática: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                            text:
                                "Para que o sistema valide corretamente as suas evidências, certifique-se que o nome do ficheiro inclui o título do requisito que está a submeter (ex: se o requisito for \"A1\", o ficheiro deve conter \"A1\" no nome). Pode submeter vários ficheiros para o mesmo requisito."),
                      ])))
                ],
              )),
          const SizedBox(height: 25),

          // DRAG AND DROP AREA
          GestureDetector(
            onTap: _escolherFicheiros,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFC),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: const Color(0xFFE9EEF2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02), blurRadius: 10)
                  ]),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF5A75A6), size: 45),
                  SizedBox(height: 15),
                  Text("Arraste e Largue aqui os seus ficheiros",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF34659D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 5),
                  Text(
                      "Suporta múltiplos ficheiros em simultâneo (PDF, PNG, JPG...)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 35),

          // GESTAO FICHEIROS NAO MAPEADOS
          const Text("Gestão de Ficheiros Submetidos",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 15),

          if (_ficheirosAnexados.isEmpty)
            const Text("Ainda não foram adicionados ficheiros.",
                style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            ...ficheirosNaoMapeados
                .map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4)
                          ]),
                      child: Row(
                        children: [
                          const Icon(Icons.description,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3))),
                                child: const Text("Não Mapeado",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              )
                            ],
                          )),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _removerFicheiroAnexado(f),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                    ))
                .toList(),

          const SizedBox(height: 35),

          // VALIDAÇÃO POR REQUISITOS
          const Text("Validação por Requisitos",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 15),

          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _badgeSelecionado!['requisitos'].map<Widget>((r) {
                  bool ok = r['concluido'];
                  List<PlatformFile> anexos =
                      r['ficheiros'] as List<PlatformFile>;

                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: ok
                              ? Colors.green.withOpacity(0.5)
                              : Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment,
                                color: ok
                                    ? Colors.green
                                    : Colors.red.withOpacity(0.5),
                                size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tituloRequisito(
                                        Map<String, dynamic>.from(r)),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(ok ? "Mapeado" : "Pendente...",
                                      style: TextStyle(
                                          color: ok ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                            )
                          ],
                        ),
                        if (anexos.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          ...anexos
                              .map((anexo) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.file_present,
                                          size: 14, color: Colors.blueGrey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                          child: Text(anexo.name,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blueGrey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis)),
                                      InkWell(
                                        onTap: () =>
                                            _removerFicheiroAnexado(anexo),
                                        child: const Icon(Icons.close,
                                            size: 14, color: Colors.red),
                                      )
                                    ],
                                  )))
                              .toList()
                        ]
                      ],
                    ),
                  );
                }).toList(),
              )),

          const SizedBox(height: 35),

          // TERMOS E CONDICOES
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _termosAceites,
                  onChanged: (val) {
                    setState(() {
                      _termosAceites = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: RichText(
                      text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          children: [
                    const TextSpan(text: "Li e aceito os "),
                    TextSpan(
                      text: "Termos e Condições e a Política RGPD",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _mostrarTermosRGPD,
                    ),
                    const TextSpan(text: "."),
                  ])))
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (todosRequisitosConcluidos && _termosAceites)
                  ? _avancar
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (todosRequisitosConcluidos && _termosAceites)
                    ? Colors.green
                    : Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Submeter Candidatura",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          if (!todosRequisitosConcluidos)
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Center(
                child: Text(
                  "Associe pelo menos 1 ficheiro a cada requisito para continuar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          if (todosRequisitosConcluidos && !_termosAceites)
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Center(
                child: Text(
                  "Deverá aceitar os termos e condições para continuar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // PASSO 4: CONFIRMAÇÃO DE SUCESSO
  Widget _passo4Confirmacao() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/check_blue.png',
                height: 120,
                errorBuilder: (c, e, s) => const Icon(Icons.check_circle,
                    size: 120, color: Colors.green),
              ),
              const SizedBox(height: 30),
              const Text(
                "Candidatura Submetida!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 15),
              const Text(
                "O seu pedido de badge foi submetido com sucesso e os ficheiros foram anexados. Irá receber uma notificação assim que o seu Service Line Leader avaliar a candidatura.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => context.push('/pedido_status',
                      extra: {'idPedido': _idPedidoSubmetido ?? 1}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34659D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: const Text("Ver Detalhes do Pedido",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _passoAtual = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF34659D),
                    side:
                        const BorderSide(color: Color(0xFF34659D), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text("Voltar às Candidaturas",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
