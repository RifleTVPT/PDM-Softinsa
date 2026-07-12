import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';
import 'api_servico.dart';
import 'conectividade_servico.dart';

class Sincronizador {
  final ApiServico _api = ApiServico();
  final BDLocalAjudante _bdLocal = BDLocalAjudante();
  static bool _syncGlobalEmCurso = false;
  static bool _syncObjetivosEmCurso = false;
  static bool _syncPedidosEmCurso = false;

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

  Map<String, dynamic> _campos(
    Map<dynamic, dynamic> origem,
    List<String> permitidos,
  ) {
    final mapLower = <String, dynamic>{};
    origem.forEach((key, value) {
      if (key is String) mapLower[key.toLowerCase()] = value;
    });

    final resultado = <String, dynamic>{};
    for (final campo in permitidos) {
      final k = campo.toLowerCase();
      if (!mapLower.containsKey(k)) continue;
      final valor = mapLower[k];
      resultado[campo] = valor is bool ? (valor ? 1 : 0) : valor;
    }
    return resultado;
  }

  Future<void> _guardarLista(
    Transaction txn,
    String tabela,
    dynamic lista,
    List<String> campos,
  ) async {
    if (lista is! List) return;
    for (final item in lista) {
      if (item is! Map) continue;
      await txn.insert(
        tabela,
        _campos(item, campos),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // SINCRONIZAR DADOS INICIAIS (API para BD LOCAL)
  // Pega na resposta única (Mega JSON) e distribui pelas várias tabelas
  Future<void> sincronizarDadosIniciais() async {
    if (_syncGlobalEmCurso) return;
    _syncGlobalEmCurso = true;
    // 1. Verifica se tem Internet antes de gastar recursos
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      print("Sem Internet. O Sincronizador não vai atuar. Usando BD Local.");
      _syncGlobalEmCurso = false;
      return;
    }

    // 1.5 Enviar edições offline que ficaram em espera
    await enviarObjetivosPendentes();
    await enviarPedidosPendentes();

    try {
      // 2. Vai buscar os dados recentes à API num único pedido
      Map<String, dynamic>? dadosRemotos = await _api.fetchDadosSincronizacao();

      // Se houver internet e a API devolver dados válidos
      if (dadosRemotos != null) {
        final db = await _bdLocal.database;

        // 2. INICIAR UMA TRANSAÇÃO
        // Garante que ou todas as tabelas são atualizadas com sucesso,ou, se houver um erro a meio, nada é guardado (Rollback)
        await db.transaction((txn) async {
          final utilizador = dadosRemotos['utilizador'];
          if (utilizador is Map) {
            final local = _campos(utilizador, [
              'ID_UTILIZADOR',
              'ID_ADMIN',
              'ID_OBJETIVO',
              'NOME_COMPLETO_UTILIZADOR',
              'EMAIL_UTILIZADOR',
              'ESTADO_CONTA_UTILIZADOR',
              'DATA_REGISTO_UTILIZADOR',
              'PERFIL_UTILIZADOR',
              'IS_PRIMEIRO_ACESSO'
            ]);
            // Nunca é guardada a password real na cache local.
            local['PASSWORD_UTILIZADOR'] = '';
            local['IS_PRIMEIRO_ACESSO'] = local['IS_PRIMEIRO_ACESSO'] ?? 0;
            local['ESTADO_CONTA_UTILIZADOR'] =
                local['ESTADO_CONTA_UTILIZADOR'] ?? 'Ativo';
            await txn.insert('UTILIZADOR', local,
                conflictAlgorithm: ConflictAlgorithm.replace);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'nomeCompleto',
              utilizador['NOME_COMPLETO_UTILIZADOR']?.toString() ??
                  prefs.getString('nomeCompleto') ??
                  'Consultor Softinsa',
            );
            await prefs.setString(
              'email',
              utilizador['EMAIL_UTILIZADOR']?.toString() ??
                  prefs.getString('email') ??
                  'consultor@softinsa.pt',
            );
            final avatarRemoto = utilizador['URL_FOTO']?.toString() ?? '';
            await prefs.setString(
              'avatarUrl',
              avatarRemoto == 'null' ? '' : avatarRemoto,
            );
          }

          await _limparEspelhoRemoto(txn);

          await _guardarLista(
              txn, 'SERVICE_LINE', dadosRemotos['service_lines'], [
            'ID_SERVICE_LINE',
            'ID_ADMIN',
            'ID_SLL',
            'NOME_SERVICE_LINE',
            'DESCRICAO_SERVICE_LINE',
            'ESTADO_ATIVO_SERVICE_LINE'
          ]);
          await _guardarLista(txn, 'AREA', dadosRemotos['areas'], [
            'ID_AREA',
            'ID_UTILIZADOR',
            'ID_SERVICE_LINE',
            'NOME_AREA',
            'DESCRICAO_AREA'
          ]);
          await _guardarLista(txn, 'NIVEL', dadosRemotos['niveis'], [
            'ID_NIVEL',
            'ID_AREA',
            'NOME_NIVEL',
            'ORDEM_HIERARQUICA',
            'DESCRICAO_NIVEL'
          ]);

          if (dadosRemotos['consultores'] is List) {
            await _guardarLista(txn, 'CONSULTOR', dadosRemotos['consultores'], [
              'ID_CONSULTOR',
              'ID_UTILIZADOR',
              'DATA_ENTRADA_EMPRESA',
              'PONTUACAO_TOTAL',
              'ID_AREA'
            ]);
          } else {
            final consultor = dadosRemotos['consultor'];
            if (consultor is Map) {
              await txn.insert(
                  'CONSULTOR',
                  _campos(consultor, [
                    'ID_CONSULTOR',
                    'ID_UTILIZADOR',
                    'DATA_ENTRADA_EMPRESA',
                    'PONTUACAO_TOTAL',
                    'ID_AREA'
                  ]),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }

          await _guardarLista(txn, 'BADGE', dadosRemotos['badges'], [
            'ID_BADGE',
            'ID_CATEGORIA',
            'ID_NIVEL',
            'ID_ADMIN',
            'NOME_BADGE',
            'DESCRICAO_BADGE',
            'CATEGORIA_BADGE',
            'PONTOS_BADGE',
            'URL_IMAGEM',
            'TEMPO_EXPIRACAO_BADGE',
            'IS_PREMIUM',
            'VALIDADE_MESES',
            'VALIDADE_EXPIRACAO'
          ]);
          await _guardarLista(txn, 'REQUISITO', dadosRemotos['requisitos'], [
            'ID_REQUISITO',
            'ID_BADGE',
            'ID_REQUISITO_PADRAO',
            'TITULO_REQUISITO',
            'DESCRICAO_REQUISITO',
            'TIPO_REQUISITO',
            'ORDEM_REQUISITO'
          ]);
          await _guardarLista(
              txn, 'CONSULTOR_BADGE', dadosRemotos['consultor_badges'], [
            'ID_CONSULTOR',
            'ID_BADGE',
            'DATA_ATRIBUICAO_BADGE',
            'DATA_EXPIRACAO',
            'LINK_UNICO_BADGE',
            'STATUS_GALERIA_PUBLICA'
          ]);
          final idsPedidosRemotos = <Object?>[];
          if (dadosRemotos['pedidos'] is List) {
            for (final pedidoRemoto in dadosRemotos['pedidos']) {
              if (pedidoRemoto is Map && pedidoRemoto['ID_PEDIDO'] != null) {
                idsPedidosRemotos.add(pedidoRemoto['ID_PEDIDO']);
              }
            }
          }

          await _guardarLista(txn, 'PEDIDO', dadosRemotos['pedidos'], [
            'ID_PEDIDO',
            'ID_UTILIZADOR',
            'ID_TM',
            'ID_SLL',
            'ID_BADGE',
            'DATA_SUBMISSAO_PEDIDO',
            'ESTADO_PEDIDO',
            'COMENTARIO_CONSULTOR',
            'DATA_ULTIMA_ATUALIZACAO'
          ]);

          // Só os pedidos vindos da API ficam sincronizados. Rascunhos locais
          // que falharam no envio continuam pendentes para nova tentativa.
          if (idsPedidosRemotos.isNotEmpty) {
            final placeholders =
                List.filled(idsPedidosRemotos.length, '?').join(',');
            await txn.rawUpdate(
              'UPDATE PEDIDO SET IS_SINCRONIZADO = 1 WHERE ID_PEDIDO IN ($placeholders)',
              idsPedidosRemotos,
            );
          }

          await txn.rawDelete('''
            DELETE FROM EVIDENCIA
            WHERE ID_PEDIDO IN (
              SELECT P_REMOTO.ID_PEDIDO
              FROM PEDIDO P_REMOTO
              WHERE P_REMOTO.IS_SINCRONIZADO = 1
                AND P_REMOTO.ESTADO_PEDIDO IN ('Rascunho', 'Pendente de Correção')
                AND EXISTS (
                  SELECT 1
                  FROM PEDIDO P_LOCAL
                  WHERE P_LOCAL.IS_SINCRONIZADO = 0
                    AND P_LOCAL.ID_UTILIZADOR = P_REMOTO.ID_UTILIZADOR
                    AND P_LOCAL.ID_BADGE = P_REMOTO.ID_BADGE
                )
            )
          ''');
          await txn.rawDelete('''
            DELETE FROM PEDIDO
            WHERE IS_SINCRONIZADO = 1
              AND ESTADO_PEDIDO IN ('Rascunho', 'Pendente de Correção')
              AND EXISTS (
                SELECT 1
                FROM PEDIDO P_LOCAL
                WHERE P_LOCAL.IS_SINCRONIZADO = 0
                  AND P_LOCAL.ID_UTILIZADOR = PEDIDO.ID_UTILIZADOR
                  AND P_LOCAL.ID_BADGE = PEDIDO.ID_BADGE
              )
          ''');

          await txn.rawDelete('''
            DELETE FROM EVIDENCIA
            WHERE ID_PEDIDO IN (
              SELECT P_LOCAL.ID_PEDIDO
              FROM PEDIDO P_LOCAL
              WHERE P_LOCAL.IS_SINCRONIZADO = 0
                AND EXISTS (
                  SELECT 1
                  FROM PEDIDO P_REMOTO
                  WHERE P_REMOTO.IS_SINCRONIZADO = 1
                    AND P_REMOTO.ID_UTILIZADOR = P_LOCAL.ID_UTILIZADOR
                    AND P_REMOTO.ID_BADGE = P_LOCAL.ID_BADGE
                    AND P_REMOTO.ESTADO_PEDIDO IN ('Pendente', 'Em Análise TM', 'Em Análise SLL', 'Aceite', 'Recusado', 'Eliminado')
                )
            )
          ''');
          await txn.rawDelete('''
            DELETE FROM PEDIDO
            WHERE IS_SINCRONIZADO = 0
              AND EXISTS (
                SELECT 1
                FROM PEDIDO P_REMOTO
                WHERE P_REMOTO.IS_SINCRONIZADO = 1
                  AND P_REMOTO.ID_UTILIZADOR = PEDIDO.ID_UTILIZADOR
                  AND P_REMOTO.ID_BADGE = PEDIDO.ID_BADGE
                  AND P_REMOTO.ESTADO_PEDIDO IN ('Pendente', 'Em Análise TM', 'Em Análise SLL', 'Aceite', 'Recusado', 'Eliminado')
              )
          ''');

          await _guardarLista(txn, 'EVIDENCIA', dadosRemotos['evidencias'], [
            'ID_EVIDENCIA',
            'ID_PEDIDO',
            'ID_REQUISITO',
            'NOME_FICHEIRO',
            'REQUISITO_MAPEADO',
            'URL_FICHEIRO'
          ]);
          // Garante a existência das colunas mesmo em dispositivos que falharam a migração
          final colunasMarco =
              await txn.rawQuery('PRAGMA table_info(MARCO_CONQUISTA)');
          if (!colunasMarco.any((c) => c['name'] == 'TIPO_MARCO')) {
            await txn.execute(
                'ALTER TABLE MARCO_CONQUISTA ADD COLUMN TIPO_MARCO TEXT');
            await txn.execute(
                'ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_1 INTEGER');
            await txn.execute(
                'ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_2 INTEGER');
          }
          if (!colunasMarco.any((c) => c['name'] == 'DATA_CRIACAO_MARCO')) {
            await txn.execute(
                'ALTER TABLE MARCO_CONQUISTA ADD COLUMN DATA_CRIACAO_MARCO TEXT');
          }

          await _guardarLista(txn, 'MARCO_CONQUISTA', dadosRemotos['marcos'], [
            'ID_MARCO',
            'TITULO_MARCO',
            'DESCRICAO_MARCO',
            'PONTOS_EXTRA',
            'REGRA_ATRIBUICAO',
            'URL_IMAGEM_MARCO',
            'TIPO_MARCO',
            'PARAMETRO_1',
            'PARAMETRO_2',
            'DATA_CRIACAO_MARCO'
          ]);
          await _guardarLista(
              txn,
              'MARCO_CONSULTOR',
              dadosRemotos['marcos_consultor'],
              ['ID_CONSULTOR', 'ID_MARCO', 'DATA_CONQUISTA']);
          await _guardarLista(
              txn, 'OBJETIVO_TIMELINE', dadosRemotos['objetivos'], [
            'ID_OBJETIVO',
            'ID_UTILIZADOR',
            'TITULO',
            'DESCRICAO',
            'DATA_OBJETIVO',
            'STATUS',
            'DATA_CONCLUSAO',
            'ORIGEM',
            'TIPO_OBJETIVO'
          ]);
          await _guardarLista(
              txn, 'NOTIFICACAO', dadosRemotos['notificacoes'], [
            'ID_NOTIFICACAO',
            'TITULO_NOTIFICACAO',
            'MENSAGEM_NOTIFICACAO',
            'DATA_ENVIO_NOTIFICACAO',
            'TIPO_NOTIFICACAO',
            'ESTADO_LIDO'
          ]);
          await _guardarLista(
              txn, 'HISTORICO_PONTUACAO', dadosRemotos['historico_pontos'], [
            'ID_HISTORICO_PONTOS',
            'ID_UTILIZADOR',
            'DATA_ATRIBUICAO',
            'PONTOS_OBTIDOS',
            'ORIGEM_PONTOS'
          ]);
        });

        await _limparRascunhosLocaisResolvidos(dadosRemotos['pedidos']);
        print("Sincronização Global (Mega JSON) concluída com sucesso!");
      }
    } catch (e, stack) {
      print("Erro na sincronização global: $e");
      print(stack);
    } finally {
      _syncGlobalEmCurso = false;
    }
  }

  Future<void> _limparEspelhoRemoto(Transaction txn) async {
    await txn.delete('HISTORICO_PONTUACAO');
    await txn.delete('MARCO_CONSULTOR');
    await txn.delete('CONSULTOR_BADGE');
    await txn.rawDelete(
      'DELETE FROM EVIDENCIA WHERE ID_PEDIDO IN (SELECT ID_PEDIDO FROM PEDIDO WHERE IS_SINCRONIZADO = 1)',
    );
    await txn.delete('PEDIDO', where: 'IS_SINCRONIZADO = ?', whereArgs: [1]);
    await txn.delete('REQUISITO');
    await txn.delete('BADGE');
    await txn.delete('MARCO_CONQUISTA');
    await txn.delete('NOTIFICACAO');
    await txn.delete('NIVEL');
    await txn.delete('AREA');
    await txn.delete('SERVICE_LINE');
  }

  Future<void> _limparRascunhosLocaisResolvidos(dynamic pedidosRemotos) async {
    if (pedidosRemotos is! List) return;
    final prefs = await SharedPreferences.getInstance();
    const estadosResolvidos = {
      'Pendente',
      'Em Análise TM',
      'Em Análise SLL',
      'Aceite',
      'Recusado',
      'Eliminado',
    };

    final badgesResolvidos = <String>{};
    for (final pedido in pedidosRemotos) {
      if (pedido is! Map) continue;
      final idBadge = pedido['ID_BADGE']?.toString();
      final estado = pedido['ESTADO_PEDIDO']?.toString();
      if (idBadge != null &&
          estado != null &&
          estadosResolvidos.contains(estado)) {
        badgesResolvidos.add(idBadge);
      }
    }

    for (final idBadge in badgesResolvidos) {
      await prefs.remove('rascunho_candidatura_$idBadge');
    }
  }

  // ENVIAR OBJETIVOS PENDENTES (BD LOCAL para API)
  Future<void> enviarObjetivosPendentes() async {
    if (_syncObjetivosEmCurso) return;
    _syncObjetivosEmCurso = true;
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      _syncObjetivosEmCurso = false;
      return;
    }

    try {
      final pendentes = await _bdLocal.obterFilaSincronizacaoObjetivos();
      if (pendentes.isEmpty) return;

      List<Map<String, dynamic>> acoes = [];
      List<int> idsProcessados = [];
      List<Map<String, dynamic>> objetivosCriados = [];

      for (var item in pendentes) {
        final dados = jsonDecode(item['DADOS_JSON']);
        acoes.add({
          'TIPO_ACAO': item['TIPO_ACAO'],
          'DADOS': dados,
        });
        if (item['TIPO_ACAO'] == 'CRIAR' && dados is Map<String, dynamic>) {
          objetivosCriados.add(dados);
        }
        idsProcessados.add(item['ID_FILA'] as int);
      }

      final sucesso = await _api.sincronizarObjetivos(acoes);
      if (sucesso) {
        final db = await _bdLocal.database;
        for (final objetivo in objetivosCriados) {
          await db.delete(
            'OBJETIVO_TIMELINE',
            where:
                '(ID_OBJETIVO = ?) OR (ID_UTILIZADOR = ? AND TITULO = ? AND DATA_OBJETIVO = ? AND TIPO_OBJETIVO = ?)',
            whereArgs: [
              objetivo['ID_OBJETIVO_LOCAL'],
              objetivo['ID_UTILIZADOR'],
              objetivo['TITULO'],
              objetivo['DATA_OBJETIVO'],
              objetivo['TIPO_OBJETIVO'],
            ],
          );
        }
        await _bdLocal.limparFilaSincronizacaoObjetivos(idsProcessados);
        await sincronizarDadosIniciais();
        print('Objetivos pendentes sincronizados com sucesso.');
      }
    } catch (e) {
      print('Erro ao sincronizar objetivos pendentes: $e');
    } finally {
      _syncObjetivosEmCurso = false;
    }
  }

  // ENVIAR PEDIDOS PENDENTES (BD LOCAL para API)
  // Usado para quando a app esteve offline e a net volta (ou ao iniciar a app)
  Future<void> enviarPedidosPendentes() async {
    if (_syncPedidosEmCurso) return;
    _syncPedidosEmCurso = true;
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      _syncPedidosEmCurso = false;
      return;
    }

    try {
      final db = await _bdLocal.database;

      // Procura na BD Local apenas os pedidos com IS_SINCRONIZADO = 0 (criados offline)
      List<Map<String, dynamic>> pendentes = await db
          .query('PEDIDO', where: 'IS_SINCRONIZADO = ?', whereArgs: [0]);

      for (var item in pendentes) {
        // Obter evidências locais deste pedido offline
        List<Map<String, dynamic>> evidencias = await db.query('EVIDENCIA',
            where: 'ID_PEDIDO = ?', whereArgs: [item['ID_PEDIDO']]);

        Map<String, dynamic> pedidoPayload = Map<String, dynamic>.from(item);
        final evidenciasPayload = <Map<String, dynamic>>[];
        for (final ev in evidencias) {
          final evidencia = Map<String, dynamic>.from(ev);
          final caminho = evidencia['URL_FICHEIRO']?.toString();
          if (caminho != null && caminho.isNotEmpty) {
            final ficheiro = File(caminho);
            if (await ficheiro.exists()) {
              evidencia['base64'] = base64Encode(await ficheiro.readAsBytes());
            }
          }
          evidencia['MIME_TYPE'] =
              _mimePorNome(evidencia['NOME_FICHEIRO']?.toString() ?? '');
          evidenciasPayload.add(evidencia);
        }
        pedidoPayload['evidencias'] = evidenciasPayload;

        // Tenta enviar para a API (A API deve suportar envio de pedido + evidencias no payload)
        bool sucesso = await _api.enviarPedido(pedidoPayload);

        if (sucesso) {
          await db.delete(
            'EVIDENCIA',
            where: 'ID_PEDIDO = ?',
            whereArgs: [item['ID_PEDIDO']],
          );
          await db.delete(
            'PEDIDO',
            where: 'ID_PEDIDO = ?',
            whereArgs: [item['ID_PEDIDO']],
          );
          print(
              "Pedido offline \${item['ID_PEDIDO']} sincronizado com a API com sucesso.");
        }
      }
      await sincronizarDadosIniciais();
    } catch (e) {
      print("Erro ao processar o envio de pedidos pendentes: \$e");
    } finally {
      _syncPedidosEmCurso = false;
    }
  }
}
