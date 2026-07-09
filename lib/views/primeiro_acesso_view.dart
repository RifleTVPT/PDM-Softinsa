import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_servico.dart';
import '../services/sincronizador.dart';

class PrimeiroAcessoView extends StatefulWidget {
  const PrimeiroAcessoView({super.key});

  @override
  State<PrimeiroAcessoView> createState() => _PrimeiroAcessoViewState();
}

class _PrimeiroAcessoViewState extends State<PrimeiroAcessoView> {
  final TextEditingController _novaPwCtrl = TextEditingController();
  final TextEditingController _confirmaPwCtrl = TextEditingController();
  bool _isLoading = false;
  String _erro = '';

  bool _validarPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$');
    return regex.hasMatch(password);
  }

  void _handleMudarPassword() async {
    setState(() => _erro = '');
    
    if (_novaPwCtrl.text.isEmpty || _confirmaPwCtrl.text.isEmpty) {
      setState(() => _erro = "Preencha todos os campos.");
      return;
    }
    if (_novaPwCtrl.text != _confirmaPwCtrl.text) {
      setState(() => _erro = "A nova password e a confirmação não coincidem.");
      return;
    }
    if (!_validarPassword(_novaPwCtrl.text)) {
      setState(() => _erro = "A password deve ter 8+ caracteres, uma maiúscula, uma minúscula, um número e um caractere especial.");
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final int idUtilizador = prefs.getInt('idUtilizador') ?? -1;

    if (idUtilizador == -1) {
      setState(() {
        _erro = "Erro de sessão. Faça login novamente.";
        _isLoading = false;
      });
      return;
    }

    final result = await ApiServico().mudarPassword(idUtilizador, 'PRIMEIRO_ACESSO_OVERRIDE', _novaPwCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password alterada com sucesso! Bem-vindo(a)."), backgroundColor: Colors.green)
      );
      
      // TEMOS de sincronizar os dados depois do primeiro acesso!
      await Sincronizador().sincronizarDadosIniciais();
      
      if (mounted) context.go('/dashboard');
    } else {
      setState(() => _erro = result['message'] ?? "Ocorreu um erro ao alterar a password.");
    }
  }

  void _cancelar() async {
    await ApiServico().terminarSessao();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    double _alturaMetade = MediaQuery.of(context).size.height * 0.4;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: _alturaMetade, color: const Color(0xFF34659D)),
              Expanded(child: Container(color: const Color(0xFFE9EEF2))),
            ],
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/images/logo_softinsa.png',
                      height: 60,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.business, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.shield_outlined, size: 40, color: Colors.amber.shade800),
                        ),
                        const SizedBox(height: 15),
                        const Text("Primeiro Acesso", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C323F))),
                        const SizedBox(height: 10),
                        const Text(
                          "Por motivos de segurança, é obrigatório alterar a sua password gerada automaticamente antes de aceder à plataforma.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        if (_erro.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_erro, style: const TextStyle(color: Colors.red, fontSize: 12))),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _novaPwCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Nova Password',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Mín. 8 caracteres, 1 maiúscula, 1 minúscula, 1 número e 1 especial (@\$!%*?&).", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _confirmaPwCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Password',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleMudarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Atualizar e Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _cancelar,
                          child: const Text('Cancelar e Terminar Sessão', style: TextStyle(color: Colors.grey)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
