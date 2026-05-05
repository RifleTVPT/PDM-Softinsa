import 'package:sqflite/sqflite.dart';
import '../database/bd_local_ajudante.dart';
import 'api_servico.dart';

class Sincronizador {
  final ApiServico _api = ApiServico();
  final BDLocalAjudante _bdLocal = BDLocalAjudante();

  // SINCRONIZAR DADOS INICIAIS (API para BD LOCAL)
  // Pega na resposta única (Mega JSON) e distribui pelas várias tabelas
  Future<void> sincronizarDadosIniciais() async {
    try {
      // 1. Vai buscar os dados recentes à API num único pedido
      Map<String, dynamic>? dadosRemotos = await _api.fetchDadosSincronizacao();

      // Se houver internet e a API devolver dados válidos
      if (dadosRemotos != null) {
        final db = await _bdLocal.database;

        // 2. INICIAR UMA TRANSAÇÃO
        // Garante que ou todas as tabelas são atualizadas com sucesso,ou, se houver um erro a meio, nada é guardado (Rollback)
        await db.transaction((txn) async {
          // Sincronizar Tabela SERVICE_LINE
          if (dadosRemotos['service_lines'] != null) {
            for (var sl in dadosRemotos['service_lines']) {
              await txn.insert(
                  'SERVICE_LINE', sl, // Os dados já vêm em formato Map do JSON
                  conflictAlgorithm: ConflictAlgorithm
                      .replace // Substitui/Atualiza se já existir o ID
                  );
            }
          }

          // Sincronizar Tabela BADGE
          if (dadosRemotos['badges'] != null) {
            for (var badge in dadosRemotos['badges']) {
              await txn.insert('BADGE', badge,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }

          // Sincronizar Tabela REQUISITO
          if (dadosRemotos['requisitos'] != null) {
            for (var req in dadosRemotos['requisitos']) {
              await txn.insert('REQUISITO', req,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }

          // O mesmo processo pode ser repetido para MARCO_CONQUISTA, OBJETIVO_TIMELINE, etc.
          // dependendo das listas que a API enviar no Mega JSON inicial
        });

        print("Sincronização Global (Mega JSON) concluída com sucesso!");
      }
    } catch (e) {
      print("Erro na sincronização global: $e");
    }
  }

  // ENVIAR PEDIDOS PENDENTES (BD LOCAL para API)
  // Usado para quando a app esteve offline e a net volta (ou ao iniciar a app)
  Future<void> enviarPedidosPendentes() async {
    try {
      final db = await _bdLocal.database;

      // Procura na BD Local apenas os pedidos com estado 'Pendente' (criados offline)
      List<Map<String, dynamic>> pendentes = await db
          .query('PEDIDO', where: 'ESTADO_PEDIDO = ?', whereArgs: ['Pendente']);

      // Percorre todos os pedidos que não foram enviados
      for (var item in pendentes) {
        // Tenta enviar para a API
        bool sucesso = await _api.enviarPedido(item);

        if (sucesso) {
          // Se a API aceitar, atualiza na BD local o estado para 'Em Análise' ou 'Enviado'
          await db.update(
            'PEDIDO',
            {'ESTADO_PEDIDO': 'Em Análise'},
            where: 'ID_PEDIDO = ?',
            whereArgs: [item['ID_PEDIDO']],
          );
          print(
              "Pedido offline ${item['ID_PEDIDO']} sincronizado com a API com sucesso.");
        }
      }
    } catch (e) {
      print("Erro ao processar o envio de pedidos pendentes: $e");
    }
  }
}
