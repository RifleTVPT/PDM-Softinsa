import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ObjetivoView extends StatefulWidget {
  const ObjetivoView({super.key});

  @override
  State<ObjetivoView> createState() => _ObjetivoViewState();
}

class _ObjetivoViewState extends State<ObjetivoView> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _tipoEscolhido = 'Progressão de Nível (A-E)';
  DateTime _dataLimite = DateTime.now().add(const Duration(days: 30));
  bool _receberNotificacoes = true;

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dataLimite) {
      setState(() => _dataLimite = picked);
    }
  }

  void _salvarObjetivo() {
    // Aqui farias a chamada à API ou BD Local futuramente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Objetivo Criado e Ativado!"),
          backgroundColor: Colors.green),
    );
    context.pop(); // Volta para a Timeline
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text("Novo Objetivo",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF34659D),
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Título do Objetivo",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _caixaTexto(_tituloCtrl, "Ex: Obter Nível B em Outsystems"),
            const SizedBox(height: 25),
            const Text("Tipo de Objetivo",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _dropdownTipo(),
            const SizedBox(height: 25),
            const Text("Data Limite para Conclusão",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _seletorData(context),
            const SizedBox(height: 25),
            const Text("Descrição e Plano de Ação",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _caixaTexto(_descCtrl, "Pretendo estudar 2 horas por dia...",
                maxLines: 4),
            const SizedBox(height: 30),
            SwitchListTile(
              title: const Text("Receber notificações e lembretes",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              value: _receberNotificacoes,
              activeColor: const Color(0xFF34659D),
              onChanged: (v) => setState(() => _receberNotificacoes = v),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _salvarObjetivo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0980E9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Ativar Objetivo e Adicionar",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caixaTexto(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  Widget _dropdownTipo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tipoEscolhido,
          isExpanded: true,
          items: [
            'Progressão de Nível (A-E)',
            'Certificação Premium',
            'Competência Técnica'
          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _tipoEscolhido = v!),
        ),
      ),
    );
  }

  Widget _seletorData(BuildContext context) {
    return GestureDetector(
      onTap: () => _selecionarData(context),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${_dataLimite.day}/${_dataLimite.month}/${_dataLimite.year}",
                style: const TextStyle(fontSize: 16)),
            const Icon(Icons.calendar_month, color: Color(0xFF34659D)),
          ],
        ),
      ),
    );
  }
}
