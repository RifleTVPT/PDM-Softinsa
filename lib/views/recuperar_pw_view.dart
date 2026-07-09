import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_servico.dart';

class RecuperarPwView extends StatefulWidget {
  const RecuperarPwView({super.key});

  @override
  State<RecuperarPwView> createState() => _RecuperarPwViewState();
}

class _RecuperarPwViewState extends State<RecuperarPwView> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _mensagem = "";
  bool _sucesso = false;

  final Color _azulSoftinsa = const Color(0xFF34659D);
  final Color _azulBotao = const Color(0xFF0980E9);
  final Color _fundoBranco = const Color(0xFFE9EEF2);

  void _recuperarPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _mensagem = "Por favor, introduza o seu email.";
        _sucesso = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = "";
    });

    final res = await ApiServico().recuperarPassword(email);

    setState(() {
      _isLoading = false;
      if (res.containsKey('error') || (res['success'] == false && !res.containsKey('message'))) {
        _sucesso = false;
        _mensagem = res['error'] ?? res['message'] ?? "Erro ao recuperar password.";
      } else {
        _sucesso = true;
        _mensagem = res['message'] ?? "Email de recuperação enviado com sucesso.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoBranco,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            color: _azulSoftinsa,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Text('SOFTINSA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Recuperar Password",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 60),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Introduza o seu email profissional. Enviaremos as instruções para definir uma nova password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email Profissional",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                          ),
                        ),
                        if (_mensagem.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            _mensagem,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _sucesso ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _recuperarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _azulBotao,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Recuperar Password",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
