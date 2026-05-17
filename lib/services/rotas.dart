import 'package:go_router/go_router.dart';
import '../views/login_view.dart';
import '../views/dashboard_view.dart';
import '../views/registo_view.dart';
import '../views/recuperar_pw_view.dart';
import '../views/catalogo_view.dart';
import '../views/candidatura_view.dart';
import '../views/meus_badges_view.dart';
import '../views/conquistas_especiais_view.dart';
import '../views/historico_candidaturas_view.dart';
import '../views/timeline_view.dart';
import '../views/objetivo_view.dart';
import '../views/estatisticas_view.dart';
import '../views/perfil_view.dart';
import '../views/notificacoes_view.dart';
import '../views/badge_detalhe_view.dart';
import '../views/pedido_status_view.dart';

// Agora é uma função que recebe a rota inicial para a parte do login só ser feito na 1 vez (e verificar se o utilizador está logado)
GoRouter criarRouter(String rotaInicial) {
  return GoRouter(
    initialLocation: rotaInicial,
    routes: [
      GoRoute(
          name: 'login',
          path: '/',
          builder: (context, state) => const LoginView()),
      GoRoute(
          name: 'dashboard',
          path: '/dashboard',
          builder: (context, state) => const DashboardView()),
      GoRoute(
          name: 'registo',
          path: '/registo',
          builder: (context, state) => const RegistoView()),
      GoRoute(
          name: 'recuperar',
          path: '/recuperar',
          builder: (context, state) => const RecuperarPwView()),
      GoRoute(
          name: 'catalogo',
          path: '/catalogo',
          builder: (context, state) => const CatalogoView()),
      GoRoute(
          name: 'candidatura',
          path: '/candidatura',
          builder: (context, state) => const CandidaturaView()),
      GoRoute(
          name: 'meus_badges',
          path: '/meus_badges',
          builder: (context, state) => const MeusBadgesView()),
      GoRoute(
          name: 'conquistas_especiais',
          path: '/conquistas_especiais',
          builder: (context, state) => const ConquistasEspeciaisView()),
      GoRoute(
          name: 'historico_candidaturas',
          path: '/historico_candidaturas',
          builder: (context, state) => const HistoricoCandidaturasView()),
      GoRoute(
          name: 'timeline',
          path: '/timeline',
          builder: (context, state) => const TimelineView()),
      GoRoute(
          name: 'objetivo',
          path: '/objetivo',
          builder: (context, state) => const ObjetivoView()),
      GoRoute(
          name: 'estatisticas',
          path: '/estatisticas',
          builder: (context, state) => const EstatisticasView()),
      GoRoute(
          name: 'perfil',
          path: '/perfil',
          builder: (context, state) => const PerfilView()),
      GoRoute(
          name: 'notificacoes',
          path: '/notificacoes',
          builder: (context, state) => const NotificacoesView()),
      GoRoute(
          name: 'badge_detalhe',
          path: '/badge_detalhe',
          builder: (context, state) => const BadgeDetalheView()),
      GoRoute(
          name: 'pedido_status',
          path: '/pedido_status',
          builder: (context, state) => const PedidoStatusView()),
    ],
  );
}
