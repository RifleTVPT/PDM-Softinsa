import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_servico.dart';
import '../components/layout_consultor.dart';
import '../models/notificacao_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';

class NotificacoesView extends StatefulWidget {
  const NotificacoesView({super.key});

  @override
  State<NotificacoesView> createState() => _NotificacoesViewState();
}

class _NotificacoesViewState extends State<NotificacoesView> {
  List<NotificacaoModel> _notificacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final bdDados = await BDLocalAjudante().obterNotificacoes(idUtilizador);
    
    if (!mounted) return;
    setState(() {
      _notificacoes = bdDados.map((row) => NotificacaoModel(
        idNotificacao: row['ID_NOTIFICACAO'],
        tituloNotificacao: row['TITULO_NOTIFICACAO'],
        mensagemNotificacao: row['MENSAGEM_NOTIFICACAO'],
        dataEnvioNotificacao: row['DATA_ENVIO_NOTIFICACAO'],
        tipoNotificacao: row['TIPO_NOTIFICACAO'] ?? 'aviso',
        estadoLido: row['ESTADO_LIDO'],
      )).toList();
      _isLoading = false;
    });
  }

  void _marcarTodasComoLidas() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;
    
    final db = await BDLocalAjudante().database;
    await db.rawUpdate('UPDATE NOTIFICACAO SET ESTADO_LIDO = 1');
    
    ApiServico().marcarTodasNotificacoesComoLidas(idUtilizador);
    
    setState(() {
      for (var i = 0; i < _notificacoes.length; i++) {
        _notificacoes[i] = NotificacaoModel(
          idNotificacao: _notificacoes[i].idNotificacao,
          tituloNotificacao: _notificacoes[i].tituloNotificacao,
          mensagemNotificacao: _notificacoes[i].mensagemNotificacao,
          dataEnvioNotificacao: _notificacoes[i].dataEnvioNotificacao,
          tipoNotificacao: _notificacoes[i].tipoNotificacao,
          estadoLido: 1,
        );
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Todas as notificações foram marcadas como lidas.")),
    );
  }

  String _formatarData(String dataIso) {
    try {
      if (dataIso.isEmpty) return "";
      DateTime dt = DateTime.parse(dataIso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dataIso;
    }
  }

  void _verDetalhesNotificacao(NotificacaoModel notif) async {
    if (notif.estadoLido == 0) {
      final db = await BDLocalAjudante().database;
      await db.update('NOTIFICACAO', {'ESTADO_LIDO': 1}, where: 'ID_NOTIFICACAO = ?', whereArgs: [notif.idNotificacao]);
      ApiServico().marcarNotificacaoComoLida(notif.idNotificacao ?? 0);
    }

    setState(() {
      int idx = _notificacoes
          .indexWhere((n) => n.idNotificacao == notif.idNotificacao);
      if (idx != -1) {
        _notificacoes[idx] = NotificacaoModel(
          idNotificacao: notif.idNotificacao,
          tituloNotificacao: notif.tituloNotificacao,
          mensagemNotificacao: notif.mensagemNotificacao,
          dataEnvioNotificacao: notif.dataEnvioNotificacao,
          tipoNotificacao: notif.tipoNotificacao,
          estadoLido: 1,
        );
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_obterIcone(notif.tipoNotificacao),
                color: _obterCor(notif.tipoNotificacao)),
            const SizedBox(width: 10),
            const Expanded(
                child: Text("Detalhes da Notificação",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.tituloNotificacao,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(notif.mensagemNotificacao,
                style: const TextStyle(color: Colors.black87, height: 1.4)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(child: Text("Recebido: ${_formatarData(notif.dataEnvioNotificacao)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF34659D))),
          )
        ],
      ),
    );
  }

  Color _obterCor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accepted':
      case 'aprovado':
      case 'aprovada':
        return Colors.green;
      case 'rejected':
      case 'rejeitado':
      case 'recusado':
      case 'warning':
      case 'aviso':
        return Colors.red;
      case 'aviso_global':
      case 'alerta':
      case 'devolvido':
      case 'correcao':
      case 'correção':
      case 'expiracao':
      case 'expiração':
        return Colors.orange;
      case 'badge':
      case 'pedido':
        return const Color(0xFF0980E9);
      case 'system':
      case 'sistema':
        return const Color(0xFF713FAA);
      default:
        return const Color(0xFF34659D);
    }
  }

  IconData _obterIcone(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accepted':
      case 'aprovado':
      case 'aprovada':
        return Icons.check_circle_outline;
      case 'rejected':
      case 'rejeitado':
      case 'recusado':
        return Icons.cancel_outlined;
      case 'warning':
      case 'aviso':
        return Icons.report_gmailerrorred_outlined;
      case 'aviso_global':
      case 'alerta':
        return Icons.warning_amber_rounded;
      case 'devolvido':
      case 'correcao':
      case 'correção':
        return Icons.assignment_return_outlined;
      case 'expiracao':
      case 'expiração':
        return Icons.warning_amber_rounded;
      case 'badge':
        return Icons.workspace_premium_outlined;
      case 'pedido':
        return Icons.assignment_outlined;
      case 'system':
      case 'sistema':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutConsultor(
      corpo: Column(
        children: [
          // HEADER DA PÁGINA COM EXPANDED
          Container(
            width: double.infinity,
            color: const Color(0xFF34659D),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Notificações",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 4),
                      Text("Mantenha-se atualizado sobre os seus pedidos.",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                // NOVA LÓGICA DO ÍCONE COM TEXTO POR BAIXO
                GestureDetector(
                  onTap: _marcarTodasComoLidas,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all, color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text(
                        "Marcar lidas",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          // LISTAGEM REATIVA
          Expanded(
            child: _notificacoes.isEmpty
                ? const Center(
                    child: Text("Não tem nenhuma notificação de momento.",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _notificacoes.length,
                    itemBuilder: (context, index) {
                      final item = _notificacoes[index];
                      bool lido = item.estadoLido == 1;

                      return GestureDetector(
                        onTap: () => _verDetalhesNotificacao(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color:
                                lido ? const Color(0xFFF7F8FA) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black12, width: 1),
                            boxShadow: lido
                                ? []
                                : [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ÍCONE
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _obterCor(item.tipoNotificacao)
                                    .withOpacity(lido ? 0.05 : 0.1),
                                child: Icon(
                                  _obterIcone(item.tipoNotificacao),
                                  color: _obterCor(item.tipoNotificacao)
                                      .withOpacity(lido ? 0.4 : 1.0),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),

                              // TEXTOS (COM EXPANDED PARA EVITAR OVERFLOW)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.tituloNotificacao,
                                      style: TextStyle(
                                        fontWeight: lido
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: lido
                                            ? Colors.black54
                                            : const Color(0xFF1A1A1A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.mensagemNotificacao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: lido
                                              ? Colors.black38
                                              : Colors.black87,
                                          fontSize: 12,
                                          height: 1.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatarData(item.dataEnvioNotificacao),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: lido
                                              ? Colors.grey.shade400
                                              : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),

                              // ÍCONE "NEW"
                              if (!lido)
                                const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(Icons.fiber_new,
                                      color: Color(0xFF0980E9), size: 30),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
