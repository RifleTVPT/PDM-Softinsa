import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';
import '../services/sincronizador.dart';
import 'package:go_router/go_router.dart';

class ConquistasEspeciaisView extends StatefulWidget {
  const ConquistasEspeciaisView({super.key});

  @override
  State<ConquistasEspeciaisView> createState() => _ConquistasEspeciaisViewState();
}

class _ConquistasEspeciaisViewState extends State<ConquistasEspeciaisView> {
  final TextEditingController _pesquisaController = TextEditingController();
  bool _isLoading = true;

  // OBTIDAS (O Consultor já tem)
  List<Map<String, dynamic>> _premiumObtidas = [];

  // DISPONÍVEIS NA PLATAFORMA (Ainda por conquistar)
  List<Map<String, dynamic>> _premiumDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _carregarConquistas();
  }

  Future<void> _carregarConquistas() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final bdHelper = BDLocalAjudante();
    final db = await bdHelper.database;

    final bdDadosObtidos = await bdHelper.obterConquistasEspeciais(idUtilizador);
    final bdDadosDisponiveis = await bdHelper.obterMarcosDisponiveis(idUtilizador);

    List<Map<String, dynamic>> disponiveisProcessadas = [];

    // Calcular o progresso de cada conquista não obtida
    for (var row in bdDadosDisponiveis) {
      String tipoMarco = row['TIPO_MARCO'] ?? '';
      int param1 = row['PARAMETRO_1'] ?? 1;
      int param2 = row['PARAMETRO_2'] ?? 0;

      int progress = 0;
      int maxProgress = param1;
      String progressoLabel = '';

      if (tipoMarco == 'TOTAL_BADGES') {
        final res = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR_BADGE');
        progress = res.first['c'] as int;
        progressoLabel = '$progress / $maxProgress';
      } else if (tipoMarco == 'TOTAL_PONTOS') {
        final res = await db.rawQuery('SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?', [idUtilizador]);
        progress = res.isNotEmpty ? res.first['PONTUACAO_TOTAL'] as int : 0;
        progressoLabel = '$progress / $maxProgress';
      } else if (tipoMarco == 'BADGES_DIAS') {
        final limitDate = DateTime.now().subtract(Duration(days: param2)).toIso8601String();
        final res = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR_BADGE WHERE DATA_ATRIBUICAO_BADGE >= ?', [limitDate]);
        progress = res.first['c'] as int;
        progressoLabel = '$progress / $maxProgress';
      } else if (tipoMarco == 'MELHOR_ANO' || tipoMarco == 'MELHOR_MESES') {
        final totalRes = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR');
        int totalConsultores = totalRes.first['c'] as int;
        
        final resP = await db.rawQuery('SELECT PONTUACAO_TOTAL FROM CONSULTOR WHERE ID_UTILIZADOR = ?', [idUtilizador]);
        int p = resP.isNotEmpty ? resP.first['PONTUACAO_TOTAL'] as int : 0;
        
        final abaixoRes = await db.rawQuery('SELECT COUNT(*) as c FROM CONSULTOR WHERE PONTUACAO_TOTAL < ?', [p]);
        int consultoresAbaixo = abaixoRes.first['c'] as int;
        
        double progValor = totalConsultores > 1 ? (consultoresAbaixo / (totalConsultores - 1)) * 100 : 100;
        maxProgress = 100;
        progress = progValor.round();
        progressoLabel = 'À frente de $progress% dos consultores';
      } else {
        maxProgress = param1 > 0 ? param1 : 1;
        progress = 0;
        progressoLabel = 'Pendente';
      }

      if (progress > maxProgress) progress = maxProgress;

      disponiveisProcessadas.add({
        "id": row['ID_MARCO'],
        "titulo": row['TITULO_MARCO'],
        "descricao": row['DESCRICAO_MARCO'],
        "bonus": row['PONTOS_EXTRA'],
        "regra": row['REGRA_ATRIBUICAO'],
        "progress": progress,
        "maxProgress": maxProgress,
        "progressoLabel": progressoLabel
      });
    }

    if (!mounted) return;
    setState(() {
      _premiumObtidas = bdDadosObtidos.map((row) => {
        "id": row['ID_MARCO'],
        "titulo": row['TITULO_MARCO'],
        "descricao": row['DESCRICAO_MARCO'],
        "bonus": row['PONTOS_EXTRA'],
        "regra": row['REGRA_ATRIBUICAO'],
        "data_conquista": row['DATA_CONQUISTA'],
      }).toList();

      _premiumDisponiveis = disponiveisProcessadas;

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtrarLista(List<Map<String, dynamic>> lista) {
    if (_pesquisaController.text.isEmpty) return lista;
    return lista
        .where((b) => b['titulo']
            .toString()
            .toLowerCase()
            .contains(_pesquisaController.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final obtidasVisiveis = _filtrarLista(_premiumObtidas);
    final disponiveisVisiveis = _filtrarLista(_premiumDisponiveis);

    return LayoutConsultor(
      corpo: Column(
        children: [
          // HEADER AZUL
          Container(
            width: double.infinity,
            color: const Color(0xFF34659D),
            padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 25),
            child: Column(
              children: [
                const Text("Conquistas Especiais",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                const Text("Explore recompensas exclusivas e certificações.",
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                TextField(
                  controller: _pesquisaController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Pesquisar conquistas...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF34659D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // CORPO COM DUAS SECÇÕES
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECÇÃO 1: OBTIDAS
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber),
                      SizedBox(width: 8),
                      Text("As Minhas Conquistas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (obtidasVisiveis.isEmpty)
                    const Text("Nenhuma conquista obtida.", style: TextStyle(color: Colors.grey))
                  else
                    ...obtidasVisiveis.map((b) => _cardPremium(b, true)),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),

                  // SECÇÃO 2: DISPONÍVEIS
                  const Row(
                    children: [
                      Icon(Icons.explore, color: Color(0xFF34659D)),
                      SizedBox(width: 8),
                      Text("Disponíveis na Plataforma", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (disponiveisVisiveis.isEmpty)
                    const Text("Nenhuma conquista disponível encontrada.", style: TextStyle(color: Colors.grey))
                  else
                    ...disponiveisVisiveis.map((b) => _cardPremium(b, false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card unificado para as Premium (Obtidas e Disponíveis)
  Widget _cardPremium(Map<String, dynamic> badge, bool jaObtida) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: jaObtida ? Border.all(color: Colors.amber, width: 2) : Border.all(color: Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: jaObtida ? Colors.amber.shade50 : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: jaObtida ? Colors.amber : const Color(0xFFC0C0C0), width: 3),
            ),
            child: Icon(jaObtida ? Icons.workspace_premium : Icons.lock, size: 40, color: jaObtida ? Colors.amber.shade700 : Colors.grey),
          ),
          const SizedBox(height: 15),
          Text(badge['titulo'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(badge['descricao'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 15),
          Text("+${badge['bonus']} Pontos Bónus", style: const TextStyle(color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
          if (jaObtida && badge['data_conquista'] != null) ...[
            const SizedBox(height: 10),
            Text("Obtido em: ${_formatarData(badge['data_conquista'])}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
          if (!jaObtida) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progresso", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 10),
                Expanded(child: Text(badge['progressoLabel'] ?? '', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4C51F7)))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: badge['maxProgress'] > 0 ? badge['progress'] / badge['maxProgress'] : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF4C51F7),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/conquistas_detalhe', extra: {'idMarco': badge['id'], 'isObtido': jaObtida}),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4C51F7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Ver Detalhes", style: TextStyle(color: Color(0xFF4C51F7), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return "N/D";
    try {
      final parts = dataIso.split("T")[0].split("-");
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (e) {
      return dataIso;
    }
  }
}
