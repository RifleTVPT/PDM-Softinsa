import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/bd_local_ajudante.dart';
import '../models/notificacao_model.dart';
import 'sincronizador.dart';
import 'api_servico.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Guarda a notificação push recebida em background na BD Local
  final remoteNotif = message.notification;
  if (remoteNotif != null) {
    final novaNotif = NotificacaoModel(
      tituloNotificacao: remoteNotif.title ?? 'Aviso Softinsa',
      mensagemNotificacao: remoteNotif.body ?? '',
      dataEnvioNotificacao: DateTime.now().toString().substring(0, 16),
      tipoNotificacao: message.data['tipo'] ?? 'aviso',
      estadoLido: 0,
    );
    await BDLocalAjudante().inserir('NOTIFICACAO', novaNotif.toMap());
  }
  // Também sincroniza nas mensagens apenas com dados, usadas para atualizar a cache.
  await Sincronizador().sincronizarDadosIniciais();
}

class Notificacoes {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navKey;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal para notificações importantes.',
    importance: Importance.max,
  );

  Future<void> inicializar(GlobalKey<NavigatorState> key) async {
    _navKey = key;

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _firebaseMessaging.getToken();
    if (token != null) await ApiServico().registarFcmToken(token);
    _firebaseMessaging.onTokenRefresh.listen(
      (novoToken) => ApiServico().registarFcmToken(novoToken),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (_) => _abrirNotificacoesSeSessaoAtiva(),
    );

    // Escuta em Background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _abrirNotificacoesSeSessaoAtiva();
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirNotificacoesSeSessaoAtiva();
      });
    }

    // Escuta em Foreground (App aberta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Cria e Insere o registo localmente de forma persistente
        final novaNotif = NotificacaoModel(
          tituloNotificacao: notification.title ?? 'Notificação',
          mensagemNotificacao: notification.body ?? '',
          dataEnvioNotificacao: DateTime.now().toString().substring(0, 16),
          tipoNotificacao: message.data['tipo'] ?? 'aviso',
          estadoLido: 0,
        );
        await BDLocalAjudante().inserir('NOTIFICACAO', novaNotif.toMap());

        // Dispara o balão do sistema no topo
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon,
            ),
          ),
          payload: 'notificacoes',
        );

        // Mostra o Popup Modal no meio do ecrã
        _mostrarPopup(
            notification.title ?? 'Nova Notificação', notification.body ?? '');

        // Regra de PDM: Sincronização offline-first disparada por Push Notification
        await Sincronizador().sincronizarDadosIniciais();
      }
    });
  }

  Future<void> _abrirNotificacoesSeSessaoAtiva() async {
    final context = _navKey?.currentContext;
    if (context == null) return;
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('isLogged') ?? false;
    final token = prefs.getString('jwtToken');
    if (isLogged && token != null && token.isNotEmpty) {
      context.go('/notificacoes');
    } else {
      context.go('/');
    }
  }

  void _mostrarPopup(String titulo, String corpo) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF34659D))),
          content: Text(corpo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
