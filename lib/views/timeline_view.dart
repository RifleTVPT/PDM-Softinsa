import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import 'package:go_router/go_router.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  List<Map<String, dynamic>> _objetivos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTimeline();
  }

  Future<void> _carregarTimeline() async {
    final dados = await BDLocalAjudante().obterTimeline();
    
    if (!mounted) return;
    setState(() {
      _objetivos = dados;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutConsultor(
      corpo: Stack(
        children: [
          Container(color: const Color(0xFFF4F5F9)),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER AZUL ESTILO SOFTINSA
                Container(
                  width: double.infinity,
                  color: const Color(0xFF34659D),
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        "Os Meus Objetivos",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Acompanhe as suas metas e o plano de evolução técnica.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      // BOTÃO PARA CRIAR NOVO (Navega para objetivo_view.dart)
                      ElevatedButton.icon(
                        onPressed: () => context.push('/objetivo'),
                        icon: const Icon(Icons.add_task),
                        label: const Text("Criar Novo Objetivo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF34659D),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),

                // LISTAGEM DE OBJETIVOS
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_objetivos.length} Objetivos na Linha Temporal",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _objetivos.length,
                            itemBuilder: (context, index) {
                              final obj = _objetivos[index];
                              final mapObj = {
                                "titulo": obj['TITULO'],
                                "data": obj['DATA_OBJETIVO'],
                                "tipo": "Objetivo",
                                "status": obj['STATUS'],
                                "origem": obj['ORIGEM']
                              };
                              return _construirCardObjetivo(mapObj);
                            },
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardObjetivo(Map<String, dynamic> obj) {
    bool isConcluido = obj['status'] == "Concluído";
    bool isLeader = obj['origem'] != "Eu";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral de cor de status
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: isConcluido ? Colors.green : const Color(0xFF34659D),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(obj['titulo'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (isLeader)
                          const Icon(Icons.verified_user,
                              color: Colors.blue, size: 18),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(obj['tipo'],
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 12)),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text("Meta: ${obj['data']}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConcluido
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            obj['status'],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    isConcluido ? Colors.green : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
