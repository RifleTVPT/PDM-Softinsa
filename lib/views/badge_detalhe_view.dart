import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Enum para definir de onde viemos (estado do badge)
enum ModoDetalheBadge { catalogo, obtidoNormal, obtidoPremium }

class BadgeDetalheView extends StatefulWidget {
  // Num cenário real com a API, receberíamos o ID do badge e o Modo via GoRouter
  const BadgeDetalheView({super.key});

  @override
  State<BadgeDetalheView> createState() => _BadgeDetalheViewState();
}

class _BadgeDetalheViewState extends State<BadgeDetalheView> {
  // VARIÁVEL DE TESTE: Altera isto para testares os diferentes ecrãs
  ModoDetalheBadge _modoAtual = ModoDetalheBadge.catalogo;

  // Mock de Dados do Badge
  final Map<String, dynamic> _badgeMock = {
    "titulo": "LowCode (Outsystems) - Nível A",
    "sl": "Hybrid Cloud",
    "descricao":
        "A equipa de OutSystems da Softinsa recorre ao desenvolvimento visual de alta produtividade para implementar e gerir aplicações em qualquer dispositivo.",
    "pontos": 150,
    "dataObtencao": "12/05/2025",
    "linkUnico": "https://softinsa.pt/verify/12345", // Para partilha
    "requisitosTotal": 3,
    "requisitos": [
      {
        "id": "A1",
        "desc": "Conclusão do Curso de Web Developer em Outsystems",
        "concluido": true
      },
      {
        "id": "A2",
        "desc": "Aprovação do Projeto na fase final da academia",
        "concluido": true
      },
      {
        "id": "A3",
        "desc": "Integração num Projeto de desenvolvimento",
        "concluido": false
      },
    ]
  };

  void _partilharLinkedIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A abrir o LinkedIn com o seu link único de badge...'),
        backgroundColor: Color(0xFF0077b5), // Azul LinkedIn
      ),
    );
  }

  void _downloadCertificado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A gerar e a transferir Certificado PDF...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // =========================================================
          // BARRA DE TESTE TEMPORÁRIA (APAGAR DEPOIS DE LIGAR À API)
          // =========================================================
          Container(
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btnTeste("Catálogo", ModoDetalheBadge.catalogo),
                _btnTeste("Obtido", ModoDetalheBadge.obtidoNormal),
                _btnTeste("Premium", ModoDetalheBadge.obtidoPremium),
              ],
            ),
          ),
          // =========================================================

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // MENSAGEM DE PARABÉNS (Só aparece se já foi obtido)
                  if (_modoAtual != ModoDetalheBadge.catalogo) ...[
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 50),
                    const SizedBox(height: 10),
                    const Text(
                      "Parabéns, obteve este Badge!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Conquistado a ${_badgeMock['dataObtencao']}",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // ÍCONE DO BADGE CENTRAL
                  Container(
                    padding: const EdgeInsets.all(25),
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
                    child: Icon(
                      _modoAtual == ModoDetalheBadge.obtidoPremium
                          ? Icons.workspace_premium
                          : Icons.shield,
                      size: 80,
                      color: _modoAtual == ModoDetalheBadge.obtidoPremium
                          ? Colors.amber.shade700
                          : const Color(0xFF34659D),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // TÍTULO E SERVICE LINE
                  Text(
                    _badgeMock['titulo'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Service Line: ${_badgeMock['sl']}",
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // PONTUAÇÃO (Pill)
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
                          "+ ${_badgeMock['pontos']} Pontos",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34659D)),
                        ),
                      ],
                    ),
                  ),
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
        _badgeMock['requisitos'].where((r) => r['concluido'] == true).length;
    int totalReq = _badgeMock['requisitosTotal'];

    return Column(
      children: [
        Text(
          _badgeMock['descricao'],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Requisitos Necessários:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    "$reqFeitos de $totalReq",
                    style: const TextStyle(
                        color: Color(0xFF0980E9), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 30),
              ..._badgeMock['requisitos'].map((r) => Padding(
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
                              Text(r['id'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: r['concluido']
                                          ? Colors.black87
                                          : Colors.grey)),
                              Text(r['desc'],
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
            // Redireciona para o formulário de candidatura
            onPressed: () => context.push('/candidatura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0980E9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Candidatar a este Badge",
                style: TextStyle(
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
    return Column(
      children: [
        // BOTÃO LINKEDIN
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _partilharLinkedIn,
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text("Partilhar no LinkedIn",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF0077b5), // Cor oficial do LinkedIn
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÃO DOWNLOAD CERTIFICADO PDF
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _downloadCertificado,
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF34659D)),
            label: const Text("Fazer Download do Certificado",
                style: TextStyle(
                    color: Color(0xFF34659D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              side: const BorderSide(color: Color(0xFF34659D), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 25),

        // Link Público do Badge
        const Text("Link de Verificação Público:",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        SelectableText(
          _badgeMock['linkUnico'],
          style: const TextStyle(
              fontSize: 13,
              color: Colors.blue,
              decoration: TextDecoration.underline),
        )
      ],
    );
  }

  // Widget auxiliar para os botões de teste no topo
  Widget _btnTeste(String titulo, ModoDetalheBadge modo) {
    return TextButton(
      onPressed: () => setState(() => _modoAtual = modo),
      child: Text(titulo,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _modoAtual == modo ? Colors.red : Colors.black54)),
    );
  }
}
