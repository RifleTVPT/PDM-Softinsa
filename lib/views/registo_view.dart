import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../services/api_servico.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController _motivacaoInput = TextEditingController();

  String? _servicoEscolhido;
  String? _areaEscolhida;
  List<Map<String, dynamic>> _serviceLines = [];
  List<Map<String, dynamic>> _areas = [];
  List<String> _areasDisponiveis = [];
  bool _aceitouTermos = false;
  String _mensagemErro = "";

  @override
  void initState() {
    super.initState();
    _carregarEstrutura();
  }

  @override
  void dispose() {
    _nomeInput.dispose();
    _emailInput.dispose();
    _senhaInput.dispose();
    _confirmarSenhaInput.dispose();
    _motivacaoInput.dispose();
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

  bool _isLoading = false;

  Future<void> _carregarEstrutura() async {
    try {
      final res = await http.get(Uri.parse('${ApiServico.baseUrl}/estrutura'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body)['data'];
      if (!mounted) return;
      setState(() {
        _serviceLines =
            List<Map<String, dynamic>>.from(data['serviceLines'] ?? []);
        _areas = List<Map<String, dynamic>>.from(data['areas'] ?? []);
      });
    } catch (_) {
      // O registo continua utilizável, mas sem opções carregadas até haver ligação.
    }
  }

  void _atualizarAreasPorServiceLine(String? nomeServiceLine) {
    final sl = _serviceLines.firstWhere(
      (item) => item['nome'] == nomeServiceLine,
      orElse: () => {},
    );
    final slId = sl['id'];
    _areasDisponiveis = _areas
        .where((area) => area['slId'] == slId)
        .map((area) => area['nome'].toString())
        .toSet()
        .toList()
      ..sort();
    _areaEscolhida =
        _areasDisponiveis.contains(_areaEscolhida) ? _areaEscolhida : null;
  }

  Future<void> _mostrarTermosRGPD() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res =
          await http.get(Uri.parse('${ApiServico.baseUrl}/configuracoes/rgpd'));
      if (mounted) Navigator.pop(context); // fechar loading

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        final termos =
            data['RGPD_TERMOS'] ?? 'Termos e condições não definidos.';
        final politicas =
            data['RGPD_POLITICAS'] ?? 'Políticas de privacidade não definidas.';

        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text("Termos e Políticas"),
              content: SingleChildScrollView(
                child: Text(
                    "--- TERMOS E CONDIÇÕES ---\n\n$termos\n\n\n--- POLÍTICAS RGPD ---\n\n$politicas"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("Fechar"),
                )
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao carregar políticas.')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // fechar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Sem ligação. Não foi possível carregar as políticas.')));
      }
    }
  }

  void _validarEAvancar() async {
    setState(() {
      _mensagemErro = "";
    });

    if (_etapaAtual == 1) {
      if (_nomeInput.text.isEmpty ||
          _emailInput.text.isEmpty ||
          _senhaInput.text.isEmpty ||
          _confirmarSenhaInput.text.isEmpty) {
        setState(() => _mensagemErro = "Por favor, preencha todos os dados.");
        return;
      }
      if (!_emailEhValido(_emailInput.text)) {
        setState(
            () => _mensagemErro = "Introduza um email profissional válido.");
        return;
      }
      if (!_senhaEhForte(_senhaInput.text)) {
        setState(() => _mensagemErro =
            "A password deve ter 8 caracteres, maiúsculas, números e um caracter especial.");
        return;
      }
      if (_senhaInput.text != _confirmarSenhaInput.text) {
        setState(() => _mensagemErro = "As passwords não coincidem!");
        return;
      }
      setState(() => _etapaAtual = 2);
    } else if (_etapaAtual == 2) {
      if (_servicoEscolhido == null ||
          _areaEscolhida == null ||
          _motivacaoInput.text.trim().isEmpty ||
          !_aceitouTermos) {
        setState(() => _mensagemErro =
            "Selecione as áreas, escreva a motivação e aceite os termos.");
        return;
      }

      setState(() => _isLoading = true);

      // Montar Payload
      Map<String, dynamic> payload = {
        "nome": _nomeInput.text.trim(),
        "email": _emailInput.text.trim(),
        "password": _senhaInput.text,
        "perfil": "Consultor", // Na app mobile é forçosamente Consultor
        "motivacao": _motivacaoInput.text.trim(),
        "slRegisto": _servicoEscolhido,
        "areaRegisto": _areaEscolhida
      };

      // Chamada à API
      final res = await ApiServico().registar(payload);

      setState(() {
        _isLoading = false;
        if (res.containsKey('error') || res['success'] == false) {
          _mensagemErro =
              res['error'] ?? res['message'] ?? "Erro ao registar conta.";
        } else {
          _etapaAtual = 3;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Altura do azul para o 3/3 ajustada (Imagem da carta)
    final alturaAzul = _etapaAtual == 3
        ? MediaQuery.of(context).size.height * 0.35
        : (_etapaAtual == 2 ? 170.0 : 155.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _fundoEspecieBranco,
      body: Stack(
        children: [
          // 1. Fundo Azul
          Container(
            height: alturaAzul,
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
              top: alturaAzul - 100,
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
        const SizedBox(height: 28),
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
        const SizedBox(height: 52),
        const Text("Service Line",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _dropdown(
            _serviceLines.map((sl) => sl['nome'].toString()).toList(),
            _servicoEscolhido,
            (v) => setState(() {
                  _servicoEscolhido = v;
                  _atualizarAreasPorServiceLine(v);
                })),
        const SizedBox(height: 22),
        const Text("Área de Interesse",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _dropdown(
          _areasDisponiveis,
          _areaEscolhida,
          (v) => setState(() => _areaEscolhida = v),
          ativo: _servicoEscolhido != null,
          placeholder: _servicoEscolhido == null
              ? 'Escolha primeiro a Service Line'
              : 'Escolha a Área',
        ),
        const SizedBox(height: 34),
        const Text("Motivação",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        _caixaTexto(_motivacaoInput, "Explique brevemente o motivo do registo"),
        const SizedBox(height: 30),
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
              Expanded(
                child: RichText(
                  text: TextSpan(
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                      children: [
                        const TextSpan(text: "Eu aceito os "),
                        TextSpan(
                          text: "Termos e Condições",
                          style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _mostrarTermosRGPD,
                        ),
                        const TextSpan(text: " desta App"),
                      ]),
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
        const SizedBox(height: 190),
        const Text("Quase Tudo Pronto!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        const Text("O seu pedido de registo foi submetido.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4)),
        const SizedBox(height: 20),
        const Text(
            "Só poderá iniciar sessão depois de o administrador aprovar a sua conta. Receberá uma confirmação por email quando o acesso estiver ativo.",
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

  Widget _dropdown(List<String> itens, String? valor, Function(String?) mudar,
      {bool ativo = true, String? placeholder}) {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: DropdownButton<String>(
        value: itens.contains(valor) ? valor : null,
        hint: Text(placeholder ?? 'Selecione uma opção'),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
        items: itens
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: !ativo || itens.isEmpty ? null : mudar,
      ),
    );
  }

  Widget _botaoAcao(String texto, VoidCallback acao) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : acao,
        style: ElevatedButton.styleFrom(
            backgroundColor: _azulBotao,
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(texto,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }
}
