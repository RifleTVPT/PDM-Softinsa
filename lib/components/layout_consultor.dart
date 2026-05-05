import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LayoutConsultor extends StatelessWidget {
  final Widget corpo;
  final int indexMenuInferior;

  const LayoutConsultor({
    super.key,
    required this.corpo,
    this.indexMenuInferior = 0,
  });

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
            child: const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF34659D)),
              currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child:
                      Icon(Icons.person, color: Color(0xFF34659D), size: 40)),
              accountName: Text("João Silva",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text("Consultor Softinsa"),
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
                      '/historico_badges'),
                  _itemMenu(context, Icons.emoji_events_outlined,
                      "Conquistas Especiais", '/historico_badges'),
                  _itemMenu(context, Icons.history, "Histórico Candidaturas",
                      '/historico_candidaturas'),
                  _itemMenu(context, Icons.track_changes, "Os Meus Objetivos",
                      '/timeline'),
                  _itemMenu(context, Icons.leaderboard_outlined,
                      "Ranking e Comparações", '/estatisticas'),
                  const Divider(),
                  _itemMenu(context, Icons.settings_outlined,
                      "Configurações Gerais", '/perfil'),
                  _itemMenu(context, Icons.notifications_outlined,
                      "Notificações", '/notificacoes'),
                  _itemMenu(context, Icons.logout, "Terminar Sessão", '/',
                      color: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
      body: corpo,
      bottomNavigationBar: NavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        selectedIndex: indexMenuInferior,
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
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF34659D)),
      title: Text(label,
          style: TextStyle(
              color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        context.push(rota);
      },
    );
  }
}
