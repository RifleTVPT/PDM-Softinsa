import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PedidoStatusView extends StatefulWidget {
  const PedidoStatusView({super.key});

  @override
  State<PedidoStatusView> createState() => _PedidoStatusViewState();
}

class _PedidoStatusViewState extends State<PedidoStatusView> {
  // SIMULAÇÃO DE DADOS DINÂMICOS
  // Estes dados viriam do 'state' ou de uma API através do ID do pedido
  final Map<String, dynamic> _dadosPedido = {
    "titulo": "LowCode (outsystems) - nível A",
    "status": "Aprovado", // Opções: "Aprovado", "Rejeitado", "Em Decisão"
    "dataAtualizacao": "04/12/2025",
    "historico": [
      {
        "passo": "Consultor enviou o pedido para análise",
        "data": "01/12/2025",
        "status": "concluido"
      },
      {
        "passo": "Talent Manager visualizou o pedido",
        "data": "02/12/2025",
        "status": "concluido"
      },
      {
        "passo": "Talent Manager enviou o pedido ao SLL",
        "data": "03/12/2025",
        "status": "concluido"
      },
      // Se estivesse em decisão, o próximo passo teria status "pendente"
    ],
    "ficheiros": [
      {
        "nome": "Requisito A1: Certificado de Formação",
        "ficheiro": "cert_a1.pdf"
      },
      {
        "nome": "Requisito A2: Projeto Prático",
        "ficheiro": "print_projeto_216.pdf"
      },
    ]
  };

  @override
  Widget build(BuildContext context) {
    // Determinar cores e ícones com base no status
    Color corPrincipal;
    IconData iconeStatus;

    switch (_dadosPedido['status']) {
      case "Aprovado":
        corPrincipal = Colors.green;
        iconeStatus = Icons.check_circle;
        break;
      case "Rejeitado":
        corPrincipal = Colors.red;
        iconeStatus = Icons.cancel;
        break;
      default:
        corPrincipal = Colors.orange;
        iconeStatus = Icons.pending_actions;
    }

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
                    _dadosPedido['status'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Atualizado a ${_dadosPedido['dataAtualizacao']}",
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
                  const Text(
                    "Histórico de Validação",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 20),

                  // LISTA DINÂMICA DA LINHA DO TEMPO
                  ...(_dadosPedido['historico'] as List)
                      .map((h) => _construirPassoTimeline(
                          h['passo'],
                          h['data'],
                          h['status'] == "concluido",
                          _dadosPedido['historico'].indexOf(h) ==
                              _dadosPedido['historico'].length - 1))
                      .toList(),

                  const SizedBox(height: 30),
                  const Text(
                    "Evidências Submetidas",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 15),

                  // LISTA DE FICHEIROS
                  ...(_dadosPedido['ficheiros'] as List)
                      .map((f) =>
                          _construirCardFicheiro(f['nome'], f['ficheiro']))
                      .toList(),

                  const SizedBox(height: 30),

                  // BOTÃO DE DETALHES DO BADGE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.push('/badge_detalhe'),
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
  Widget _construirPassoTimeline(
      String descricao, String data, bool concluido, bool ultimo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              concluido ? Icons.check_circle : Icons.radio_button_unchecked,
              color: concluido ? Colors.green : Colors.grey,
              size: 24,
            ),
            if (!ultimo)
              Container(
                width: 2,
                height: 40,
                color: concluido ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "- $data: $descricao",
                style: TextStyle(
                  color: concluido ? Colors.black87 : Colors.grey,
                  fontSize: 14,
                  fontWeight: concluido ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET PARA OS CARDS DE FICHEIRO
  Widget _construirCardFicheiro(String titulo, String nomeFicheiro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined,
              color: Colors.grey, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(nomeFicheiro,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline)),
              ],
            ),
          ),
          const Icon(Icons.check, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
