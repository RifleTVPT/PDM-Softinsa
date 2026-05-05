import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_servico.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controladores para apanhar o texto das caixas
  final TextEditingController _caixaEmail = TextEditingController();
  final TextEditingController _caixaSenha = TextEditingController();

  // Variável para mostrar se a app está a carregar
  bool _estaACarregar = false;

  @override
  void dispose() {
    // Limpar os controladores quando sair do ecrã
    _caixaEmail.dispose();
    _caixaSenha.dispose();
    super.dispose();
  }

  void _fazerLogin() async {
    // Começa a carregar
    setState(() => _estaACarregar = true);

    // Espera um pouco para simular a internet
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _estaACarregar = false);

    // Vai para o Dashboard usando as rotas
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    // Calcula o tamanho para a divisão das cores
    double _alturaMetade = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fundo com as duas cores da Softinsa
          Column(
            children: [
              // Parte de cima azul
              Container(
                height: _alturaMetade,
                color: const Color(0xFF34659D),
              ),
              // Parte de baixo cinzenta
              Expanded(
                child: Container(
                  color: const Color(0xFFE9EEF2),
                ),
              ),
            ],
          ),

          // 2. Coisas que aparecem no ecrã
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Logo que está na pasta assets
                  Center(
                    child: Image.asset(
                      'assets/images/logo_softinsa.png',
                      height: 80,
                      // Se o ficheiro não existir, mostra um ícone
                      errorBuilder: (context, erro, rasto) => const Icon(
                        Icons.business,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 3. Caixas de texto
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _caixaEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _caixaSenha,
                          obscureText: true, // Para não verem a password
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. Botões de ação
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        // Botão de Login Azul
                        SizedBox(
                          width: 220,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _estaACarregar ? null : _fazerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0980E9),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _estaACarregar
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Login',
                                    style: TextStyle(fontSize: 18)),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Botão de Registo Branco
                        SizedBox(
                          width: 220,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => context.push('/registo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0980E9),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Registe-se',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Link para quando o utilizador se esquece
                        TextButton(
                          onPressed: () => context.push('/recuperar'),
                          child: const Text(
                            'Esqueceu a Password?',
                            style: TextStyle(
                              color: Color(0xFF0980E9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
