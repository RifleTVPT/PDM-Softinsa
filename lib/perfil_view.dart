import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/layout_consultor.dart';
import 'package:go_router/go_router.dart';

// Enum para gerir qual o ecrã visível dentro do Perfil
enum ModoPerfil { menuPrincipal, editarPerfil, configuracoesApp }

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  // Estado inicial: Menu do Perfil
  ModoPerfil _modoAtual = ModoPerfil.menuPrincipal;

  // Controladores para o Editar Perfil
  final _nomeCtrl = TextEditingController(text: "João Silva");
  final _emailCtrl = TextEditingController(text: "joao.silva@softinsa.pt");
  String _slEscolhida = "Hybrid Cloud";
  String _areaEscolhida = "LowCode (Outsystems)";

  // Controladores para as Configurações da App
  String _idiomaEscolhido = "Português";
  bool _notifAprovacoes = true;
  bool _notifExpiracao = true;
  bool _partilhaLinkedIn = true;

  // Controladores do Modal de Password
  final _novaPwCtrl = TextEditingController();
  final _confirmaPwCtrl = TextEditingController();

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
  void _guardarAlteracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Alterações guardadas com sucesso!"),
          backgroundColor: Colors.green),
    );
    setState(() => _modoAtual = ModoPerfil.menuPrincipal);
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
            const Text("Deve conter mín. 8 caracteres, 1 maiúscula e 1 número.",
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Password atualizada!"),
                  backgroundColor: Colors.green));
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
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 50, color: Color(0xFF34659D)),
                      ),
                      const SizedBox(height: 15),
                      const Text("João Silva",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      const Text("joao.silva@softinsa.pt",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(15)),
                        child: const Text("Perfil: Consultor",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
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
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 24, color: Color(0xFF34659D)),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _modoAtual == ModoPerfil.editarPerfil
                            ? "Editar Perfil"
                            : "Configurações da App",
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
      case ModoPerfil.configuracoesApp:
        return _construirConfiguracoes();
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
            Icons.settings_outlined,
            "Configurações da App",
            "Notificações, idioma e RGPD",
            () => setState(() => _modoAtual = ModoPerfil.configuracoesApp)),
        const Divider(height: 40),
        _itemBotaoMenu(Icons.dashboard_outlined, "Retornar ao Dashboard",
            "Voltar à página inicial", () => context.go('/dashboard')),
        _itemBotaoMenu(
            Icons.logout, "Terminar Sessão", "Sair da plataforma em segurança",
            () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLogged', false); // Apaga a sessão da memória
          context.go('/');
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
        _dropdownSimples(
            "Service Line",
            _slEscolhida,
            ["Hybrid Cloud", "DevOps", "Data & AI"],
            (v) => setState(() => _slEscolhida = v!)),

        const SizedBox(height: 15),
        const Text("A sua área de especialização (relativa à Service Line):",
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 5),
        _dropdownSimples(
            "Área de Especialização",
            _areaEscolhida,
            ["LowCode (Outsystems)", "Java", "C#"],
            (v) => setState(() => _areaEscolhida = v!)),
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
  // 3. CONFIGURAÇÕES DA APP (ESTADO 2)
  // ==========================================
  Widget _construirConfiguracoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Preferências de Idioma",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        const Text("Selecione o idioma da aplicação:",
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 5),
        _dropdownSimples(
            "Idioma da Aplicação",
            _idiomaEscolhido,
            ["Português", "Inglês", "Espanhol"],
            (v) => setState(() => _idiomaEscolhido = v!)),
        const SizedBox(height: 30),
        const Text("Notificações e Avisos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Atualizações de Candidaturas",
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text("Alertas quando o SLL aprova ou rejeita.",
              style: TextStyle(fontSize: 12)),
          value: _notifAprovacoes,
          activeColor: const Color(0xFF34659D),
          onChanged: (v) => setState(() => _notifAprovacoes = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Avisos de Expiração",
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text("Avisa quando um badge está prestes a caducar.",
              style: TextStyle(fontSize: 12)),
          value: _notifExpiracao,
          activeColor: const Color(0xFF34659D),
          onChanged: (v) => setState(() => _notifExpiracao = v),
        ),
        const SizedBox(height: 30),
        const Text("Integrações",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Sincronização com LinkedIn",
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text(
              "Permitir partilha automática de novas conquistas.",
              style: TextStyle(fontSize: 12)),
          value: _partilhaLinkedIn,
          activeColor: const Color(0xFF0077b5),
          onChanged: (v) => setState(() => _partilhaLinkedIn = v),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _guardarAlteracoes,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0980E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text("Guardar Configurações",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
      ],
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
