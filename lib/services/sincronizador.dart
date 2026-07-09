import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/bd_local_ajudante.dart';
import 'api_servico.dart';
import 'conectividade_servico.dart';

class Sincronizador {
  final ApiServico _api = ApiServico();
  final BDLocalAjudante _bdLocal = BDLocalAjudante();

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
    // 1. Verifica se tem Internet antes de gastar recursos
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) {
      print("Sem Internet. O Sincronizador não vai atuar. Usando BD Local.");
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
            local['ESTADO_CONTA_UTILIZADOR'] = local['ESTADO_CONTA_UTILIZADOR'] ?? 'Ativo';
            await txn.insert('UTILIZADOR', local,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }

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
          
          // Todos os pedidos vindos da API estão sincronizados.
          await txn.rawUpdate('UPDATE PEDIDO SET IS_SINCRONIZADO = 1');

          await _guardarLista(txn, 'EVIDENCIA', dadosRemotos['evidencias'], [
            'ID_EVIDENCIA',
            'ID_PEDIDO',
            'ID_REQUISITO',
            'NOME_FICHEIRO',
            'REQUISITO_MAPEADO',
            'URL_FICHEIRO'
          ]);
          // Garante a existência das colunas mesmo em dispositivos que falharam a migração
          final colunasMarco = await txn.rawQuery('PRAGMA table_info(MARCO_CONQUISTA)');
          if (!colunasMarco.any((c) => c['name'] == 'TIPO_MARCO')) {
            await txn.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN TIPO_MARCO TEXT');
            await txn.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_1 INTEGER');
            await txn.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_2 INTEGER');
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
            'PARAMETRO_2'
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

        print("Sincronização Global (Mega JSON) concluída com sucesso!");
      }
    } catch (e, stack) {
      print("Erro na sincronização global: $e");
      print(stack);
    }
  }

  // ENVIAR OBJETIVOS PENDENTES (BD LOCAL para API)
  Future<void> enviarObjetivosPendentes() async {
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) return;

    try {
      final pendentes = await _bdLocal.obterFilaSincronizacaoObjetivos();
      if (pendentes.isEmpty) return;

      List<Map<String, dynamic>> acoes = [];
      List<int> idsProcessados = [];

      for (var item in pendentes) {
        acoes.add({
          'TIPO_ACAO': item['TIPO_ACAO'],
          'DADOS': jsonDecode(item['DADOS_JSON']),
        });
        idsProcessados.add(item['ID_FILA'] as int);
      }

      final sucesso = await _api.sincronizarObjetivos(acoes);
      if (sucesso) {
        await _bdLocal.limparFilaSincronizacaoObjetivos(idsProcessados);
        print('Objetivos pendentes sincronizados com sucesso.');
      }
    } catch (e) {
      print('Erro ao sincronizar objetivos pendentes: $e');
    }
  }

  // ENVIAR PEDIDOS PENDENTES (BD LOCAL para API)
  // Usado para quando a app esteve offline e a net volta (ou ao iniciar a app)
  Future<void> enviarPedidosPendentes() async {
    bool temNet = await ConectividadeServico().temInternet();
    if (!temNet) return;

    try {
      final db = await _bdLocal.database;

      // Procura na BD Local apenas os pedidos com IS_SINCRONIZADO = 0 (criados offline)
      List<Map<String, dynamic>> pendentes = await db.query(
          'PEDIDO', 
          where: 'IS_SINCRONIZADO = ?', 
          whereArgs: [0]
      );

      for (var item in pendentes) {
        // Obter evidências locais deste pedido offline
        List<Map<String, dynamic>> evidencias = await db.query(
            'EVIDENCIA',
            where: 'ID_PEDIDO = ?',
            whereArgs: [item['ID_PEDIDO']]
        );

        Map<String, dynamic> pedidoPayload = Map<String, dynamic>.from(item);
        pedidoPayload['evidencias'] = evidencias;

        // Tenta enviar para a API (A API deve suportar envio de pedido + evidencias no payload)
        bool sucesso = await _api.enviarPedido(pedidoPayload);

        if (sucesso) {
          // Se a API aceitar, atualiza na BD local o estado de sincronização
          await db.update(
            'PEDIDO',
            {'IS_SINCRONIZADO': 1, 'ESTADO_PEDIDO': 'Em Análise'},
            where: 'ID_PEDIDO = ?',
            whereArgs: [item['ID_PEDIDO']],
          );
          print("Pedido offline \${item['ID_PEDIDO']} sincronizado com a API com sucesso.");
        }
      }
    } catch (e) {
      print("Erro ao processar o envio de pedidos pendentes: \$e");
    }
  }
}
