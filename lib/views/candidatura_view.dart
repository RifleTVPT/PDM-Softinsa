import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

class CandidaturaView extends StatefulWidget {
  const CandidaturaView({super.key});

  @override
  State<CandidaturaView> createState() => _CandidaturaViewState();
}

class _CandidaturaViewState extends State<CandidaturaView> {
  int _passoAtual = 1;
  bool _estaACarregar = false;

  // Filtros do Passo 1
  String _servicoEscolhido = "Todas as Service Lines";
  final List<String> _niveisSelecionados = [];
  final List<String> _todosNiveis = ['A', 'B', 'C', 'D', 'E'];

  // Simulação de dados para as Interfaces 2 e 3
  final Map<String, dynamic> _badgeSelecionado = {
    "titulo": "LowCode (outsystems) - nível A",
    "descricao":
        "A equipa de OutSystems da Softinsa recorre ao desenvolvimento visual de alta produtividade para implementar e gerir aplicações em qualquer dispositivo, assegurando a fiabilidade, a escalabilidade, o desempenho e a segurança e integração das mesmas.",
    "pontos": 150,
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
        "concluido": false
      },
      {
        "id": "A3",
        "desc": "Integração num Projeto de desenvolvimento",
        "concluido": false
      },
    ]
  };

  void _alternarNivel(String nivel) {
    setState(() {
      _niveisSelecionados.contains(nivel)
          ? _niveisSelecionados.remove(nivel)
          : _niveisSelecionados.add(nivel);
    });
  }

  void _avancar() async {
    setState(() => _estaACarregar = true);
    await Future.delayed(
        const Duration(milliseconds: 600)); // Simula tempo de rede
    setState(() {
      _estaACarregar = false;
      _passoAtual++;
    });
  }

  void _recuar() {
    setState(() {
      if (_passoAtual > 1) _passoAtual--;
    });
  }

  // Lógica simples para simular a atualização dos badges (Passo 1)
  List<Map<String, String>> _obterBadgesFiltrados() {
    // Base mock data
    List<Map<String, String>> todos = [
      {"titulo": "Badge Especialidade 1", "sl": "Hybrid Cloud", "nivel": "A"},
      {"titulo": "Badge Especialidade 2", "sl": "DevOps", "nivel": "B"},
      {"titulo": "Badge Especialidade 3", "sl": "Hybrid Cloud", "nivel": "C"},
      {"titulo": "Badge Especialidade 4", "sl": "Data & AI", "nivel": "A"},
      {"titulo": "Badge Especialidade 5", "sl": "Hybrid Cloud", "nivel": "B"},
    ];

    return todos.where((badge) {
      bool slMatch = _servicoEscolhido == "Todas as Service Lines" ||
          badge["sl"] == _servicoEscolhido;
      bool nivelMatch = _niveisSelecionados.isEmpty ||
          _niveisSelecionados.contains(badge["nivel"]);
      return slMatch && nivelMatch;
    }).toList();
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
    List<Map<String, String>> badgesVisiveis = _obterBadgesFiltrados();

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
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF34659D),
                  Color(0xFF34659D),
                  Color(0xFFF4F5F9),
                  Color(0xFFF4F5F9)
                ],
                stops: [0.0, 0.15, 0.15, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // CARD O SEU ÚLTIMO PEDIDO
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
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.workspace_premium,
                                  color: Color(0xFF34659D), size: 30),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Hybrid Cloud",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text("LowCode - Nível B",
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const Column(
                              children: [
                                Text("150",
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF34659D))),
                                Text("PTS",
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text("Em Análise",
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            TextButton(
                                onPressed: () => context.push('/badge_detalhe'),
                                child: const Text("Ver Detalhes",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline))),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

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
                              "Hybrid Cloud",
                              "DevOps",
                              "Data & AI"
                            ]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _servicoEscolhido = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("2. Filtre por Níveis de Competência",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black54)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _todosNiveis.map((n) {
                          bool sel = _niveisSelecionados.contains(n);
                          return GestureDetector(
                            onTap: () => _alternarNivel(n),
                            child: Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF34659D)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF34659D), width: 1.5),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: Colors.blue.withOpacity(0.2),
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
                    ],
                  ),
                ),

                // LISTA DE RESULTADOS DINÂMICA
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10)
                            ]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE9EEF2),
                              child: Icon(Icons.auto_awesome,
                                  color: Color(0xFF34659D))),
                          title: Text(badge['titulo']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Service Line: ${badge['sl']} | Nível ${badge['nivel']}"),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF34659D), size: 20),
                          onTap: _avancar,
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // PASSO 2: DETALHES DO BADGE PARA CANDIDATURA
  Widget _passo2DetalheBadge() {
    int reqFeitos = _badgeSelecionado['requisitos']
        .where((r) => r['concluido'] == true)
        .length;
    int totalReq = _badgeSelecionado['requisitosTotal'];

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
            child: const Icon(Icons.shield, size: 80, color: Color(0xFF34659D)),
          ),
          const SizedBox(height: 25),
          Text(
            _badgeSelecionado['titulo'],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 15),
          Text(
            _badgeSelecionado['descricao'],
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
                  "+ ${_badgeSelecionado['pontos']} Pontos",
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Requisitos Atuais:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: reqFeitos > 0
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$reqFeitos de $totalReq",
                        style: TextStyle(
                          color: reqFeitos > 0
                              ? const Color(0xFF0980E9)
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                ..._badgeSelecionado['requisitos']
                    .map((r) => Padding(
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
              onPressed: _avancar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0980E9),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "Candidatar ao Badge",
                style: TextStyle(
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Anexar Evidências",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 10),
          const Text(
              "O validador irá mapear automaticamente os ficheiros que contenham IDs como A1 ou B2 no nome.",
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 30),
          ..._badgeSelecionado['requisitos'].map((r) {
            String? fileName = r['concluido']
                ? "certificado_${r['id'].toLowerCase()}.pdf"
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
                border: Border.all(
                    color: r['concluido']
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.2),
                    width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    fileName != null
                        ? Icons.description
                        : Icons.warning_amber_rounded,
                    color: fileName != null
                        ? const Color(0xFF34659D)
                        : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['id'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          fileName ?? "Ficheiro não detetado",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                fileName != null ? Colors.black87 : Colors.red,
                            fontWeight: fileName != null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (fileName != null)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 24),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('A abrir explorador de ficheiros...')));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF34659D).withOpacity(0.5), width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF34659D), size: 40),
                  SizedBox(height: 10),
                  Text("Carregar Novos Ficheiros",
                      style: TextStyle(
                          color: Color(0xFF34659D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 5),
                  Text("Formatos suportados: PDF, JPG, PNG",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _avancar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Submeter Candidatura",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
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
                  onPressed: () => context.push('/pedido_status'),
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
