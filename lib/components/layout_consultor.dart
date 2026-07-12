import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/api_servico.dart';
import '../services/conectividade_servico.dart';
import '../services/sincronizador.dart';
import 'avatar_utilizador_mobile.dart';

class LayoutConsultor extends StatefulWidget {
  final Widget corpo;
  final int indexMenuInferior;

  const LayoutConsultor({
    super.key,
    required this.corpo,
    this.indexMenuInferior = 0,
  });

  @override
  State<LayoutConsultor> createState() => _LayoutConsultorState();
}

class _LayoutConsultorState extends State<LayoutConsultor> {
  String _nomeCompleto = "A carregar...";
  String _email = "";
  String _avatarUrl = "";
  bool _temNet = true;
  StreamSubscription<bool>? _conectividadeSub;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    
    // Iniciar Sincronização e escuta da Net
    _verificarNetESincronizar();
  }

  void _verificarNetESincronizar() async {
    // 1. O Mega JSON é obrigatório quando se abre a app (Sincroniza inicial)
    await Sincronizador().sincronizarDadosIniciais();

    // 2. Escutar mudanças de rede para o Banner e Sincronizações posteriores
    bool netInicial = await ConectividadeServico().temInternet();
    if (mounted) {
      setState(() => _temNet = netInicial);
    }

    _conectividadeSub = ConectividadeServico().onConnectivityChanged.listen((temInternet) {
      if (mounted) {
        setState(() => _temNet = temInternet);
        // Se a net ligou de novo, atualizar a app mandando o Mega JSON (para refletir pedidos web)
        if (temInternet) {
          Sincronizador().sincronizarDadosIniciais();
        }
      }
    });
  }

  @override
  void dispose() {
    _conectividadeSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeCompleto = prefs.getString('nomeCompleto') ?? 'Consultor Softinsa';
      _email = prefs.getString('email') ?? 'consultor@softinsa.pt';
      _avatarUrl = prefs.getString('avatarUrl') ?? '';
    });
  }

  String _obterIniciais(String nome) {
    if (nome.isEmpty || nome == "A carregar...") return "?";
    List<String> partes = nome.trim().split(' ');
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return "${partes.first[0]}${partes.last[0]}".toUpperCase();
  }

  void _terminarSessao() async {
    await ApiServico().terminarSessao();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF34659D),
        elevation: 0,
        centerTitle: true,
        // imagem da Softinsa no topo
        title: Image.asset(
          'assets/images/logo_softinsa.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) => const Text(
            "SOFTINSA",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => context.push('/notificacoes'),
          ),
          GestureDetector(
            onTap: () => context.push('/perfil'),
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: AvatarUtilizadorMobile(
                nome: _nomeCompleto,
                foto: _avatarUrl,
                raio: 16,
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF34659D)),
              currentAccountPicture: AvatarUtilizadorMobile(
                nome: _nomeCompleto,
                foto: _avatarUrl,
                raio: 36,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF34659D),
              ),
              accountName: Text(_nomeCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(_email),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _itemMenu(context, Icons.dashboard_outlined, "Dashboard",
                      '/dashboard'),
                  _itemMenu(context, Icons.collections_bookmark_outlined,
                      "Catálogo de Badges", '/catalogo'),
                  _itemMenu(context, Icons.add_circle_outline,
                      "Nova Candidatura", '/candidatura'),
                  _itemMenu(context, Icons.verified_outlined, "Os Meus Badges",
                      '/meus_badges'),
                  _itemMenu(context, Icons.emoji_events_outlined,
                      "Conquistas Especiais", '/conquistas_especiais'),
                  _itemMenu(context, Icons.history, "Histórico Candidaturas",
                      '/historico_candidaturas'),
                  _itemMenu(context, Icons.track_changes, "Os Meus Objetivos",
                      '/objetivos'),
                  _itemMenu(context, Icons.leaderboard_outlined,
                      "Ranking e Comparações", '/ranking'),
                  const Divider(),
                  _itemMenu(context, Icons.settings_outlined,
                      "Configurações Gerais", '/perfil'),
                  _itemMenu(context, Icons.notifications_outlined,
                      "Notificações", '/notificacoes'),
                  _itemMenu(context, Icons.logout, "Terminar Sessão", '/',
                      color: Colors.red, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER OFFLINE (PDF 11)
          if (!_temNet)
            Container(
              width: double.infinity,
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sem Internet. Algumas informações podem estar desatualizadas.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: widget.corpo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        selectedIndex: widget.indexMenuInferior,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.push('/catalogo');
          if (index == 2) context.push('/candidatura');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_rounded), label: 'Catálogo'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline), label: 'Candidatura'),
        ],
      ),
    );
  }

  Widget _itemMenu(
      BuildContext context, IconData icon, String label, String rota,
      {Color? color, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF34659D)),
      title: Text(label,
          style: TextStyle(
              color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context); // Fechar drawer
        if (isLogout) {
          _terminarSessao();
        } else {
          context.push(rota);
        }
      },
    );
  }
}
