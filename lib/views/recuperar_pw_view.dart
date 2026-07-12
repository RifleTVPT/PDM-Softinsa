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
  final TextEditingController _novaPasswordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String _mensagem = "";
  bool _sucesso = false;
  bool _emailVerificado = false;

  final Color _azulSoftinsa = const Color(0xFF34659D);
  final Color _azulBotao = const Color(0xFF0980E9);
  final Color _fundoBranco = const Color(0xFFE9EEF2);

  bool _senhaEhForte(String senha) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$')
        .hasMatch(senha);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _verificarEmail() async {
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

    final res = await ApiServico().verificarEmailRecuperacao(email);

    setState(() {
      _isLoading = false;
      if (res['success'] != true) {
        _sucesso = false;
        _mensagem = res['error'] ?? res['message'] ?? "Email não encontrado.";
      } else {
        _sucesso = true;
        _emailVerificado = true;
        _mensagem = "Email validado. Defina agora a nova password.";
      }
    });
  }

  void _recuperarPassword() async {
    final email = _emailController.text.trim();
    final novaPassword = _novaPasswordController.text;
    final confirmarPassword = _confirmarPasswordController.text;

    if (novaPassword.isEmpty || confirmarPassword.isEmpty) {
      setState(() {
        _mensagem = "Preencha a nova password e a confirmação.";
        _sucesso = false;
      });
      return;
    }
    if (novaPassword != confirmarPassword) {
      setState(() {
        _mensagem = "As passwords não coincidem.";
        _sucesso = false;
      });
      return;
    }
    if (!_senhaEhForte(novaPassword)) {
      setState(() {
        _mensagem =
            "A password deve ter 8+ caracteres, uma maiúscula, uma minúscula, um número e um caractere especial.";
        _sucesso = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensagem = "";
    });

    final res = await ApiServico()
        .recuperarPassword(email, novaPassword, confirmarPassword);

    setState(() {
      _isLoading = false;
      if (res.containsKey('error') || res['success'] == false) {
        _sucesso = false;
        _mensagem =
            res['error'] ?? res['message'] ?? "Erro ao redefinir password.";
      } else {
        _sucesso = true;
        _mensagem = res['message'] ?? "Password redefinida com sucesso.";
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
            height: 145,
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
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
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
                const SizedBox(height: 12),
                const Text("Recuperar Password",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Introduza o seu email profissional para validar a conta e redefinir a password.",
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
                        if (_emailVerificado) ...[
                          const SizedBox(height: 15),
                          TextField(
                            controller: _novaPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Nova Password",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _confirmarPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Confirmar Password",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                            ),
                          ),
                        ],
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
                            onPressed: _isLoading
                                ? null
                                : (_emailVerificado
                                    ? _recuperarPassword
                                    : _verificarEmail),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _azulBotao,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    _emailVerificado
                                        ? "Redefinir Password"
                                        : "Validar Email",
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
