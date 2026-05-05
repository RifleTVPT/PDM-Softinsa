import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistoView extends StatefulWidget {
  const RegistoView({super.key});

  @override
  State<RegistoView> createState() => _RegistoViewState();
}

class _RegistoViewState extends State<RegistoView> {
  int _etapaAtual = 1;

  final TextEditingController _nomeInput = TextEditingController();
  final TextEditingController _emailInput = TextEditingController();
  final TextEditingController _senhaInput = TextEditingController();
  final TextEditingController _confirmarSenhaInput = TextEditingController();

  String? _servicoEscolhido;
  String? _areaEscolhida;
  bool _aceitouTermos = false;
  String _mensagemErro = "";

  @override
  void dispose() {
    _nomeInput.dispose();
    _emailInput.dispose();
    _senhaInput.dispose();
    _confirmarSenhaInput.dispose();
    super.dispose();
  }

  final Color _azulSoftinsa = const Color(0xFF34659D);
  final Color _azulBotao = const Color(0xFF0980E9);
  final Color _fundoEspecieBranco = const Color(0xFFE9EEF2);

  bool _emailEhValido(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validação da Password (Letras, Números, Maiúscula e Especial)
  bool _senhaEhForte(String senha) {
    bool temLetra = senha.contains(RegExp(r'[a-z]'));
    bool temMaiuscula = senha.contains(RegExp(r'[A-Z]'));
    bool temNumero = senha.contains(RegExp(r'[0-9]'));
    bool temEspecial = senha.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return senha.length >= 8 &&
        temLetra &&
        temMaiuscula &&
        temNumero &&
        temEspecial;
  }

  void _validarEAvancar() {
    setState(() {
      _mensagemErro = "";
      if (_etapaAtual == 1) {
        if (_nomeInput.text.isEmpty ||
            _emailInput.text.isEmpty ||
            _senhaInput.text.isEmpty ||
            _confirmarSenhaInput.text.isEmpty) {
          _mensagemErro = "Por favor, preencha todos os dados.";
          return;
        }
        if (!_emailEhValido(_emailInput.text)) {
          _mensagemErro = "Introduza um email profissional válido.";
          return;
        }
        if (!_senhaEhForte(_senhaInput.text)) {
          _mensagemErro =
              "A password deve ter 8 caracteres, maiúsculas, números e um caracter especial.";
          return;
        }
        if (_senhaInput.text != _confirmarSenhaInput.text) {
          _mensagemErro = "As passwords não coincidem!";
          return;
        }
        _etapaAtual = 2;
      } else if (_etapaAtual == 2) {
        if (_servicoEscolhido == null ||
            _areaEscolhida == null ||
            !_aceitouTermos) {
          _mensagemErro = "Selecione as áreas e aceite os termos.";
          return;
        }
        _etapaAtual = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Altura do azul para o 3/3 ajustada (Imagem da carta)
    double _alturaAzul =
        MediaQuery.of(context).size.height * (_etapaAtual == 3 ? 0.35 : 0.25);

    return Scaffold(
      backgroundColor: _fundoEspecieBranco,
      body: Stack(
        children: [
          // 1. Fundo Azul
          Container(
            height: _alturaAzul,
            width: double.infinity,
            color: _azulSoftinsa,
          ),

          // 2. Conteúdo Principal
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () {
                          if (_etapaAtual > 1) {
                            setState(() => _etapaAtual--);
                          } else {
                            context.pop();
                          }
                        },
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

                _construirTitulosEtapa(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: _construirInterfaceCorreta(),
                  ),
                ),

                // Botão Fixo
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: _botaoAcao(
                    _etapaAtual == 1
                        ? "Continuar"
                        : _etapaAtual == 2
                            ? "Finalizar Registo"
                            : "Voltar à Página de Login",
                    _etapaAtual == 3 ? () => context.go('/') : _validarEAvancar,
                  ),
                ),
              ],
            ),
          ),

          // 3. Imagem da Carta (3/3) - Subimos um pouco (top: _alturaAzul - 100) para não bater no texto
          if (_etapaAtual == 3)
            Positioned(
              top: _alturaAzul - 100,
              left: 0,
              right: 0,
              child: Image.asset('assets/images/email_icon.png',
                  height: 160,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.email, size: 120, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _construirTitulosEtapa() {
    String t = _etapaAtual == 1
        ? "Criar Nova Conta"
        : _etapaAtual == 2
            ? "Escolha as suas áreas de interesse"
            : "Confirme o seu Registo";
    return Column(
      children: [
        const SizedBox(height: 5),
        Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500)),
        Text("($_etapaAtual de 3)",
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _construirInterfaceCorreta() {
    if (_etapaAtual == 1) return _passo1();
    if (_etapaAtual == 2) return _passo2();
    return _passo3();
  }

  Widget _passo1() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _caixaTexto(_nomeInput, "Nome"),
        const SizedBox(height: 20),
        _caixaTexto(_emailInput, "Email Profissional",
            teclado: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _caixaTexto(_senhaInput, "Password", oculta: true),
        const SizedBox(height: 20),
        _caixaTexto(_confirmarSenhaInput, "Confirmar Password", oculta: true),
        if (_mensagemErro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(_mensagemErro,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _passo2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text("Service Line",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _dropdown(["Hybrid Cloud", "Data & AI", "Mainframe"], _servicoEscolhido,
            (v) => setState(() => _servicoEscolhido = v)),
        const SizedBox(height: 30),
        const Text("Área de Interesse",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _dropdown(["Lowcode (outsystems)", "DevOps", "Java"], _areaEscolhida,
            (v) => setState(() => _areaEscolhida = v)),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => setState(() => _aceitouTermos = !_aceitouTermos),
          child: Row(
            children: [
              Icon(
                  _aceitouTermos
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: _azulSoftinsa,
                  size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text.rich(
                  TextSpan(text: "Eu aceito os ", children: [
                    TextSpan(
                        text: "Termos e Condições",
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline)),
                    TextSpan(text: " desta App"),
                  ]),
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        if (_mensagemErro.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_mensagemErro,
                  style: const TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _passo3() {
    return Column(
      children: [
        const SizedBox(
            height:
                160), // Aumentamos este espaço para o texto "descer" e não bater na carta
        const Text("Quase Tudo Pronto!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        const Text("Enviámos um Email de confirmação\ndo seu Registo!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4)),
        const SizedBox(height: 20),
        const Text(
            "Por favor consulte a sua caixa de Email para confirmar o Registo e começar a utilizar a nova conta",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4)),
      ],
    );
  }

  Widget _caixaTexto(TextEditingController ctrl, String dica,
      {bool oculta = false, TextInputType teclado = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: TextField(
        controller: ctrl,
        obscureText: oculta,
        keyboardType: teclado,
        decoration: InputDecoration(
            hintText: dica,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(18)),
      ),
    );
  }

  Widget _dropdown(List<String> itens, String? valor, Function(String?) mudar) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: DropdownButton<String>(
        value: valor,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
        items: itens
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: mudar,
      ),
    );
  }

  Widget _botaoAcao(String texto, VoidCallback acao) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: acao,
        style: ElevatedButton.styleFrom(
            backgroundColor: _azulBotao,
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: Text(texto,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
