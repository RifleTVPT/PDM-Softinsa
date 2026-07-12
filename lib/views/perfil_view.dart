import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';
import '../database/bd_local_ajudante.dart';
import '../components/avatar_utilizador_mobile.dart';

import '../services/api_servico.dart';

// Enum para gerir qual o ecrã visível dentro do Perfil
enum ModoPerfil { menuPrincipal, editarPerfil, centroAjuda }

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  // Estado inicial: Menu do Perfil
  ModoPerfil _modoAtual = ModoPerfil.menuPrincipal;

  // Dados carregados da BD
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;

  // Controladores para o Editar Perfil
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _slEscolhida = "";
  String _areaEscolhida = "";

  // Controladores para as Configurações da App
  String _avatarUrl = "";
  int _idUtilizador = -1;

  // Controladores do Modal de Password
  final _pwAtualCtrl = TextEditingController();
  final _novaPwCtrl = TextEditingController();
  final _confirmaPwCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    _idUtilizador = prefs.getInt('idUtilizador') ?? 1;

    final dados = await BDLocalAjudante().obterPerfil(_idUtilizador);

    if (!mounted) return;
    setState(() {
      _perfilData = dados;
      _nomeCtrl.text = prefs.getString('nomeCompleto') ?? dados['nome'] ?? '';
      _emailCtrl.text = prefs.getString('email') ?? dados['email'] ?? '';
      _slEscolhida = dados['serviceLine'] ?? 'N/A';
      _areaEscolhida = dados['area'] ?? 'Geral';
      _avatarUrl = prefs.getString('avatarUrl') ?? '';
      _isLoading = false;
    });
  }

  String _obterIniciais(String nome) {
    if (nome.isEmpty || nome == "A carregar...") return "?";
    List<String> partes = nome.trim().split(' ');
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return "${partes.first[0]}${partes.last[0]}".toUpperCase();
  }

  bool _validarPassword(String password) {
    final regex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).{8,}$');
    return regex.hasMatch(password);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _novaPwCtrl.dispose();
    _confirmaPwCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNÇÕES DE AÇÃO
  // ==========================================
  void _guardarAlteracoes() async {
    if (_nomeCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos!")));
      return;
    }

    final res = await ApiServico()
        .atualizarPerfil(_idUtilizador, _nomeCtrl.text, _emailCtrl.text);

    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final nomeAtualizado =
          res['data']?['nome']?.toString() ?? _nomeCtrl.text.trim();
      final emailAtualizado =
          res['data']?['email']?.toString() ?? _emailCtrl.text.trim();
      await prefs.setString('nomeCompleto', nomeAtualizado);
      await prefs.setString('email', emailAtualizado);
      await BDLocalAjudante().atualizarPerfilUtilizadorLocal(
          _idUtilizador, nomeAtualizado, emailAtualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Alterações guardadas com sucesso!"),
            backgroundColor: Colors.green),
      );
      setState(() => _modoAtual = ModoPerfil.menuPrincipal);
      _carregarPerfil(); // Reload para atualizar header
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Erro ao guardar.")),
      );
    }
  }

  Future<void> _alterarFotoPerfil() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    final res = await ApiServico().atualizarAvatar(_idUtilizador, path);
    if (res['success'] == true) {
      final novoAvatar = res['avatarUrl']?.toString() ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatarUrl', novoAvatar);
      if (!mounted) return;
      setState(() => _avatarUrl = novoAvatar);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto de perfil atualizada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Erro ao atualizar foto.")),
      );
    }
  }

  void _abrirModalPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Alterar Password",
            style: TextStyle(
                color: Color(0xFF34659D), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pwAtualCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Password Atual", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _novaPwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Nova Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmaPwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Confirmar Nova Password",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Text(
                "Mín. 8 caracteres, 1 maiúscula, 1 minúscula, 1 número e 1 especial (@\$!%*?&).",
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_novaPwCtrl.text != _confirmaPwCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("As passwords não coincidem.")));
                return;
              }
              if (!_validarPassword(_novaPwCtrl.text)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Formato de password inválido.")));
                return;
              }

              final res = await ApiServico().mudarPassword(
                  _idUtilizador, _pwAtualCtrl.text, _novaPwCtrl.text);
              if (res['success'] == true) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Password atualizada com sucesso!"),
                    backgroundColor: Colors.green));
                _pwAtualCtrl.clear();
                _novaPwCtrl.clear();
                _confirmaPwCtrl.clear();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['message'] ??
                        "Não foi possível alterar a password. Confirme a password atual."),
                    backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0980E9)),
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    bool isMenu = _modoAtual == ModoPerfil.menuPrincipal;

    return LayoutConsultor(
      corpo: Column(
        children: [
          // HEADER DINÂMICO (Adapta o tamanho se estiver no menu ou nos formulários)
          Container(
            width: double.infinity,
            color: const Color(0xFF34659D),
            padding: EdgeInsets.only(
                top: isMenu ? 20 : 10,
                bottom: isMenu ? 25 : 15,
                left: 10,
                right: 20),
            child: isMenu
                // 1. MODO MENU: Cabeçalho Grande
                ? Column(
                    children: [
                      AvatarUtilizadorMobile(
                        nome: _nomeCtrl.text,
                        foto: _avatarUrl,
                        raio: 45,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF34659D),
                      ),
                      const SizedBox(height: 15),
                      Text(_nomeCtrl.text,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(_emailCtrl.text,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(15)),
                              child: Text(_perfilData?['serviceLine'] ?? 'SLL',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15)),
                              child: Text(_perfilData?['area'] ?? 'Área',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                // 2. MODO FORMULÁRIO: Cabeçalho Compacto (Deixa muito mais ecrã para as opções)
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => setState(
                            () => _modoAtual = ModoPerfil.menuPrincipal),
                      ),
                      AvatarUtilizadorMobile(
                        nome: _nomeCtrl.text,
                        foto: _avatarUrl,
                        raio: 20,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF34659D),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _modoAtual == ModoPerfil.editarPerfil
                            ? "Editar Perfil"
                            : "Centro de Ajuda",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
          ),

          // CORPO DINÂMICO
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: _construirCorpo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCorpo() {
    switch (_modoAtual) {
      case ModoPerfil.menuPrincipal:
        return _construirMenuPrincipal();
      case ModoPerfil.editarPerfil:
        return _construirEditarPerfil();
      case ModoPerfil.centroAjuda:
        return _construirCentroAjuda();
    }
  }

  // ==========================================
  // 1. MENU PRINCIPAL (ESTADO 0)
  // ==========================================
  Widget _construirMenuPrincipal() {
    return Column(
      children: [
        _itemBotaoMenu(
            Icons.edit_outlined,
            "Editar Perfil",
            "Atualize os seus dados e Service Line",
            () => setState(() => _modoAtual = ModoPerfil.editarPerfil)),
        _itemBotaoMenu(
            Icons.help_outline,
            "Centro de Ajuda",
            "FAQs e suporte direto",
            () => setState(() => _modoAtual = ModoPerfil.centroAjuda)),
        const Divider(height: 40),
        _itemBotaoMenu(Icons.dashboard_outlined, "Retornar ao Dashboard",
            "Voltar à página inicial", () => context.go('/dashboard')),
        _itemBotaoMenu(
            Icons.logout, "Terminar Sessão", "Sair da plataforma em segurança",
            () async {
          await ApiServico().terminarSessao();
          if (mounted) context.go('/');
        }, corDestaque: Colors.red),
      ],
    );
  }

  Widget _itemBotaoMenu(
      IconData icone, String titulo, String sub, VoidCallback acao,
      {Color? corDestaque}) {
    Color corPrincipal = corDestaque ?? const Color(0xFF1A1A1A);
    Color corIcone = corDestaque ?? const Color(0xFF34659D);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: corIcone.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icone, color: corIcone)),
        title: Text(titulo,
            style: TextStyle(fontWeight: FontWeight.bold, color: corPrincipal)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: acao,
      ),
    );
  }

  // ==========================================
  // 2. EDITAR PERFIL (ESTADO 1)
  // ==========================================
  Widget _construirEditarPerfil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dados Pessoais",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Center(
          child: Column(
            children: [
              AvatarUtilizadorMobile(
                nome: _nomeCtrl.text,
                foto: _avatarUrl,
                raio: 38,
                backgroundColor: const Color(0xFFE9F1FA),
                foregroundColor: const Color(0xFF34659D),
              ),
              TextButton.icon(
                onPressed: _alterarFotoPerfil,
                icon: const Icon(Icons.photo_camera_outlined,
                    color: Color(0xFF34659D)),
                label: const Text("Alterar foto",
                    style: TextStyle(
                        color: Color(0xFF34659D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _campoTexto("Nome Completo", _nomeCtrl),
        const SizedBox(height: 15),
        _campoTexto("Endereço de Email", _emailCtrl, isEmail: true),
        const SizedBox(height: 30),

        const Text("Dados Profissionais",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),

        // Novos títulos explicativos
        const Text("Qual a sua Service Line primária?",
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: TextEditingController(text: _slEscolhida),
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: 15),
        const Text("A sua área de especialização (relativa à Service Line):",
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: TextEditingController(text: _areaEscolhida),
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _abrirModalPassword,
            icon: const Icon(Icons.lock_reset, color: Color(0xFF34659D)),
            label: const Text("Alterar Password",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF34659D))),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF34659D)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _guardarAlteracoes,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0980E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Guardar Alterações",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. CENTRO DE AJUDA (ESTADO 2)
  // ==========================================
  Widget _construirCentroAjuda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dúvidas Frequentes (FAQs)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _faqItem("O que são os Softinsa Badges?",
            "São reconhecimentos digitais das suas competências, conquistas e evolução profissional dentro da Softinsa."),
        _faqItem("Como posso obter um badge?",
            "Abra o catálogo, escolha um badge disponível, envie as evidências pedidas e acompanhe o estado no histórico de pedidos."),
        _faqItem("O que são badges especiais?",
            "São conquistas premium atribuídas automaticamente quando cumpre regras como pontos, badges obtidos, posição no ranking ou desempenho numa Service Line."),
        _faqItem("Posso corrigir uma candidatura?",
            "Sim. Quando um pedido é devolvido para correção, pode consultar o feedback, ajustar os ficheiros e voltar a submeter."),
        _faqItem("Onde vejo os meus certificados?",
            "Abra Meus Badges, entre nos detalhes do badge obtido e use as opções de certificado, galeria pública ou partilha."),
        _faqItem("Como altero os meus dados?",
            "Nas Configurações pode atualizar nome, email, password e foto de perfil. A sua Service Line e área são geridas pela organização."),
        const SizedBox(height: 30),
        const Text("Contactos de Suporte",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.email_outlined, color: Colors.blue),
          ),
          title: const Text("Email de Suporte",
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("softinsabadges@gmail.com"),
        ),
        const SizedBox(height: 30),
        const Center(
          child: Text("Softinsa Badges © 2026\nDesenvolvido com Flutter",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        )
      ],
    );
  }

  Widget _faqItem(String pergunta, String resposta) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(pergunta,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(resposta,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          )
        ],
      ),
    );
  }

  // Componentes Auxiliares
  Widget _campoTexto(String label, TextEditingController ctrl,
      {bool isEmail = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _dropdownSimples(
      String label, String valor, List<String> itens, Function(String?) mudar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: valor,
          hint: Text(label),
          items: itens
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: mudar,
        ),
      ),
    );
  }
}
