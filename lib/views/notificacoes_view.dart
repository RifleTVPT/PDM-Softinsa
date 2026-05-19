import 'package:flutter/material.dart';
import '../models/notificacao_model.dart';

class NotificacoesView extends StatefulWidget {
  const NotificacoesView({super.key});

  @override
  State<NotificacoesView> createState() => _NotificacoesViewState();
}

class _NotificacoesViewState extends State<NotificacoesView> {
  static const azulSoftinsa = Color(0xFF1A468D);

  // A lista deixou de ser 'final' dentro do build para poder ser alterada no estado
  late List<NotificacaoModel> listaNotificacoes;

  @override
  void initState() {
    super.initState();
    // Inicializamos a lista com os teus dados mockados
    listaNotificacoes = [
      NotificacaoModel(
        idNotificacao: 1,
        tituloNotificacao: "Novo badge disponível!",
        dataEnvioNotificacao: "26/11/2025",
        mensagemNotificacao:
            "Foi criado um novo badge para a Hybrid Cloud Service Line, com a área de aprendizagem de LowCode (Outsystems)",
        estadoLido: 0,
      ),
      NotificacaoModel(
        idNotificacao: 2,
        tituloNotificacao: "Manutenção Programada!",
        dataEnvioNotificacao: "20/11/2025",
        mensagemNotificacao:
            "Informa-se que a aplicação passará por manutenção no dia 21/11 das 00:00 até às 04:00. Agradece-se a compreensão.",
        estadoLido: 0,
      ),
      NotificacaoModel(
        idNotificacao: 3,
        tituloNotificacao: "Pedido de Badge aceite!",
        dataEnvioNotificacao: "19/11/2025",
        mensagemNotificacao:
            "Boas notícias! O seu pedido de obtenção do Badge LowCode (Outsystems) - Nível A da Service Line Hybrid Cloud foi aceite !",
        estadoLido: 0,
      ),
    ];
  }

  // Função para marcar UMA notificação específica como lida
  void _marcarComoLida(int index) {
    setState(() {
      // Cria uma cópia do modelo com o estadoLido atualizado para 1
      final notifAtual = listaNotificacoes[index];
      listaNotificacoes[index] = NotificacaoModel(
        idNotificacao: notifAtual.idNotificacao,
        tituloNotificacao: notifAtual.tituloNotificacao,
        dataEnvioNotificacao: notifAtual.dataEnvioNotificacao,
        mensagemNotificacao: notifAtual.mensagemNotificacao,
        estadoLido: 1, // Atualiza o estado
      );
    });
  }

  // Função para marcar TODAS as notificações como lidas
  void _marcarTodasComoLidas() {
    setState(() {
      for (int i = 0; i < listaNotificacoes.length; i++) {
        final notifAtual = listaNotificacoes[i];
        if (notifAtual.estadoLido == 0) {
          listaNotificacoes[i] = NotificacaoModel(
            idNotificacao: notifAtual.idNotificacao,
            tituloNotificacao: notifAtual.tituloNotificacao,
            dataEnvioNotificacao: notifAtual.dataEnvioNotificacao,
            mensagemNotificacao: notifAtual.mensagemNotificacao,
            estadoLido: 1,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: azulSoftinsa,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notificações e Avisos",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: listaNotificacoes.length,
              itemBuilder: (context, index) {
                final item = listaNotificacoes[index];
                return _buildNotificacaoCard(item, index);
              },
            ),
          ),
          TextButton(
            // Chamamos a função ao clicar
            onPressed: _marcarTodasComoLidas,
            child: const Text(
              "Marcar todas como lidas",
              style: TextStyle(
                color: azulSoftinsa,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Passamos o 'index' para saber qual notificação clicar
  Widget _buildNotificacaoCard(NotificacaoModel notif, int index) {
    final bool estaLida = notif.estadoLido == 1;

    final Color corFundoCard = estaLida
        ? const Color(0xFFEAECEF)
        : Colors.white;
    final Color corTextoPrincipal = estaLida
        ? Colors.grey.shade600
        : Colors.black87;
    final Color corTextoSecundario = estaLida
        ? Colors.grey.shade500
        : Colors.grey;
    final Color corIconeLateral = estaLida
        ? Colors.grey
        : const Color(0xFF1A468D);

    // Envolver o card num InkWell torna-o clicável
    return InkWell(
      onTap: () {
        if (!estaLida) {
          _marcarComoLida(index); // Marca como lida apenas se não estiver
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: corFundoCard,
          borderRadius: BorderRadius.circular(12),
          border: estaLida ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: corIconeLateral),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 5,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: corIconeLateral.withOpacity(0.1),
                          child: Icon(
                            estaLida
                                ? Icons.drafts_outlined
                                : Icons.mark_email_unread_outlined,
                            color: corIconeLateral,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.tituloNotificacao,
                                style: TextStyle(
                                  fontWeight: estaLida
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: corTextoPrincipal,
                                ),
                              ),
                              Text(
                                notif.dataEnvioNotificacao,
                                style: TextStyle(
                                  color: corTextoSecundario,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif.mensagemNotificacao,
                                style: TextStyle(
                                  color: corTextoSecundario,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
