import 'package:flutter/material.dart';
import '../components/layout_consultor.dart';
import '../database/bd_local_ajudante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sincronizador.dart';

class TimelineObjetivosView extends StatefulWidget {
  const TimelineObjetivosView({super.key});

  @override
  State<TimelineObjetivosView> createState() => _TimelineObjetivosViewState();
}

class _TimelineObjetivosViewState extends State<TimelineObjetivosView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _objetivos = [];
  int _idUtilizador = -1;

  // Campos Novo Objetivo
  String _novoTitulo = '';
  String _novaData = '';
  String _novoTipo = 'Progressão de Nível (A-E)';
  String _novaDescricao = '';

  final List<String> _tiposObjetivo = [
    'Progressão de Nível (A-E)',
    'Acúmulo de Pontos',
    'Aquisição de Competência',
    'Outro'
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    _idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final bd = BDLocalAjudante();
    final objetivos = await bd.obterObjetivos(_idUtilizador);

    if (!mounted) return;
    setState(() {
      _objetivos = objetivos;
      _isLoading = false;
    });
  }

  Future<void> _handleCriarObjetivo() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final bd = BDLocalAjudante();
    final parts = _novaData.split('/');
    final dataFormatada = parts.length == 3 ? "${parts[2]}-${parts[1]}-${parts[0]}" : _novaData;

    final Map<String, dynamic> objMap = {
      'ID_UTILIZADOR': _idUtilizador,
      'TITULO': _novoTitulo,
      'DESCRICAO': _novaDescricao,
      'DATA_OBJETIVO': dataFormatada,
      'STATUS': 'Em Progresso',
      'ORIGEM': 'Criado por mim',
      'TIPO_OBJETIVO': _novoTipo,
    };
    
    final idCriado = await bd.adicionarObjetivo(objMap);
    
    // Fila Sincronização
    objMap['ID_OBJETIVO_LOCAL'] = idCriado; // Helper ID
    await bd.adicionarFilaSincronizacaoObjetivo('CRIAR', objMap);
    
    // Tentar enviar logo para API
    Sincronizador().enviarObjetivosPendentes();

    if (!mounted) return;
    Navigator.of(context).pop(); // Fechar Modal
    _carregarDados(); // Atualizar Grelha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Objetivo criado com sucesso!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _marcarComoConcluido(int idObjetivo) async {
    final bd = BDLocalAjudante();
    await bd.concluirObjetivo(idObjetivo);
    
    // Fila Sincronização
    await bd.adicionarFilaSincronizacaoObjetivo('CONCLUIR', {'ID_OBJETIVO': idObjetivo, 'ID_UTILIZADOR': _idUtilizador});
    
    // Tentar enviar logo para API
    Sincronizador().enviarObjetivosPendentes();

    _carregarDados();
  }

  void _abrirModalCriacao() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        String modalTitulo = '';
        String modalData = '';
        String modalTipo = 'Progressão de Nível (A-E)';
        String modalDesc = '';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Definir Nova Meta de Evolução", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nome do Objetivo (*)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Ex: Tornar-me Especialista Azure",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                    onSaved: (val) => _novoTitulo = val ?? '',
                  ),
                  const SizedBox(height: 15),
                  
                  const Text("Data Meta para Conclusão (*)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "dd/mm/aaaa",
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        modalData = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                        // We use a small hack here just to update the text field visually if needed, but since it's an alert dialog, better to manage via stateful builder
                      }
                    },
                    validator: (value) {
                      // Workaround to make sure a date was picked
                      if (modalData.isEmpty) return 'Escolha uma data';
                      return null;
                    },
                    onSaved: (val) => _novaData = modalData,
                    controller: TextEditingController(text: modalData),
                  ),
                  const SizedBox(height: 15),

                  const Text("Tipo de Objetivo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: modalTipo,
                    items: _tiposObjetivo.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => modalTipo = v!,
                    onSaved: (val) => _novoTipo = val ?? modalTipo,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text("Descrição e Plano de Ação", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  TextFormField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Pretendo estudar 2 horas por dia...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onSaved: (val) => _novaDescricao = val ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _novaData = modalData; 
                _handleCriarObjetivo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C51F7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Ativar Objetivo", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  DateTime _parseData(String data) {
    try {
      if (data.contains('T')) return DateTime.parse(data);
      if (data.contains('/')) {
        final parts = data.split('/');
        if (parts.length == 3) return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else if (data.contains('-')) {
        final parts = data.split('-');
        if (parts.length == 3) return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2].split(' ')[0]));
      }
    } catch (_) {}
    return DateTime.now(); // Fallback
  }

  String _formatarDataBonita(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final DateTime d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return raw.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LayoutConsultor(corpo: Center(child: CircularProgressIndicator()));

    final ativos = _objetivos.where((o) => o['STATUS'] != 'Concluído').toList();
    final concluidos = _objetivos.where((o) => o['STATUS'] == 'Concluído').toList();
    final total = _objetivos.length;
    final progresso = total > 0 ? (concluidos.length / total) : 0.0;

    return LayoutConsultor(
      corpo: Container(
        color: const Color(0xFFF4F5F9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Text("Gestão de Objetivos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C323F)))),
              const SizedBox(height: 5),
              const Center(child: Text("Acompanhe a sua evolução", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),

              // KPI Header Cards Responsivo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: const Text("🎯", style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 5),
                        Text("Total: $total", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                    Column(
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF4C51F7), size: 14),
                        const SizedBox(height: 10),
                        Text("Ativos: ${ativos.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C51F7), fontSize: 13)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                    Column(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 14),
                        const SizedBox(height: 10),
                        Text("Concluídos: ${concluidos.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // TIMELINE - SEÇÕES VERTICAIS
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF4C51F7), size: 14),
                  const SizedBox(width: 8),
                  Text("Em Execução", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                ],
              ),
              const SizedBox(height: 15),
              ativos.isEmpty 
                ? Padding(padding: const EdgeInsets.only(bottom: 20, left: 10), child: Text("Nenhum objetivo ativo no momento.", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)))
                : Column(
                    children: ativos.map((o) => _buildObjetivoCard(o, true)).toList(),
                  ),
                  
              const SizedBox(height: 25),
              
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 14),
                  const SizedBox(width: 8),
                  Text("Concluídos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                ],
              ),
              const SizedBox(height: 15),
              concluidos.isEmpty 
                ? Padding(padding: const EdgeInsets.only(bottom: 20, left: 10), child: Text("Ainda não concluiu objetivos.", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)))
                : Column(
                    children: concluidos.map((o) => _buildObjetivoCard(o, false)).toList(),
                  ),

              const SizedBox(height: 30),

              // Barra de Progresso
              LinearProgressIndicator(
                value: progresso,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF4C51F7),
                minHeight: 12,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 15),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
                  child: Text("Marcos Alcançados: ${concluidos.length}/$total (${(progresso*100).toStringAsFixed(0)}%)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _abrirModalCriacao,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Adicionar Novo Objetivo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C51F7),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjetivoCard(Map<String, dynamic> obj, bool isAtivo) {
    bool emAtraso = false;
    String dataConcStr = obj['DATA_CONCLUSAO']?.toString() ?? '';
    String dataObjStr = obj['DATA_OBJETIVO']?.toString() ?? '';

    if (!isAtivo && dataConcStr.isNotEmpty && dataObjStr.isNotEmpty) {
       DateTime dataConclusao = _parseData(dataConcStr);
       DateTime dataObjetivo = _parseData(dataObjStr);
       if (dataConclusao.isAfter(dataObjetivo)) {
           emAtraso = true;
       }
    }

    Color corEstado = isAtivo ? const Color(0xFF4C51F7) : (emAtraso ? Colors.red : Colors.green);
    String textoEstado = emAtraso ? "Concluído com Atraso" : obj['STATUS'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isAtivo ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100)
      ),
      child: Stack(
        children: [
          // Faixa lateral de cor
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: corEstado,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15))
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(obj['ORIGEM'] ?? 'Criado por mim', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  obj['TITULO'] ?? 'Objetivo', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: isAtivo ? Colors.black87 : Colors.grey.shade600,
                    decoration: isAtivo ? null : TextDecoration.lineThrough
                  )
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("Status: ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Icon(Icons.circle, size: 10, color: corEstado),
                    const SizedBox(width: 5),
                    Text(textoEstado, style: TextStyle(fontSize: 13, color: corEstado, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                if (isAtivo)
                  Text("Data Meta: \n${_formatarDataBonita(obj['DATA_OBJETIVO'])}", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold))
                else
                  Text("Concluído a: \n${_formatarDataBonita(obj['DATA_CONCLUSAO'])}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  
                if (isAtivo) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _marcarComoConcluido(obj['ID_OBJETIVO']),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: const Text("Marcar como concluído", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corEstado,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
