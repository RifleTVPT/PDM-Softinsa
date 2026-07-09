import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResultadoLogin {
  final bool sucesso;
  final String mensagem;
  final bool primeiroAcesso;
  final Map<String, dynamic>? utilizador;

  const ResultadoLogin({
    required this.sucesso,
    required this.mensagem,
    this.primeiroAcesso = false,
    this.utilizador,
  });
}

class ApiServico {
  // Em produção:
  // flutter run --dart-define=API_BASE_URL=https://nome-do-backend.onrender.com
  // O valor por defeito funciona no emulador Android com o backend no computador.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://softinsa-api-riya.onrender.com',
  );

  Future<Map<String, String>> _cabecalhosAutenticados() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ResultadoLogin> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      final corpo = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final utilizador = Map<String, dynamic>.from(corpo['user'] as Map);
        final perfis =
            (utilizador['PERFIL_UTILIZADOR'] ?? '').toString().toLowerCase();
        if (!perfis.contains('consultor')) {
          return const ResultadoLogin(
            sucesso: false,
            mensagem:
                'A aplicação móvel está disponível apenas para consultores.',
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', corpo['token'].toString());
        await prefs.setInt(
          'idUtilizador',
          (utilizador['ID_UTILIZADOR'] as num).toInt(),
        );
        await prefs.setString('nomeCompleto', utilizador['NOME_COMPLETO_UTILIZADOR']?.toString() ?? 'Consultor Softinsa');
        await prefs.setString('email', utilizador['EMAIL_UTILIZADOR']?.toString() ?? 'consultor@softinsa.pt');
        String avatar = utilizador['URL_FOTO']?.toString() ?? '';
        if (avatar == 'null') avatar = '';
        await prefs.setString('avatarUrl', avatar);
        await prefs.setBool('isLogged', true);

        return ResultadoLogin(
          sucesso: true,
          mensagem: corpo['message']?.toString() ?? 'Login efetuado.',
          primeiroAcesso:
              corpo['firstAccess'] == true || corpo['firstAccess'] == 1,
          utilizador: utilizador,
        );
      }

      return ResultadoLogin(
        sucesso: false,
        mensagem:
            corpo['message']?.toString() ?? 'Não foi possível iniciar sessão.',
      );
    } catch (e) {
      return const ResultadoLogin(
        sucesso: false,
        mensagem:
            'Sem ligação ao servidor. Ligue-se à Internet para iniciar sessão.',
      );
    }
  }

  Future<Map<String, dynamic>?> fetchDadosSincronizacao() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/sync'),
        headers: await _cabecalhosAutenticados(),
      );

      if (response.statusCode == 200) {
        final corpo = jsonDecode(response.body) as Map<String, dynamic>;
        return Map<String, dynamic>.from(corpo['data'] as Map);
      } else {
        print("Erro na API ao sincronizar: Código ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Erro no pedido de sincronização: $e');
      return null; // Retorna nulo em caso de falta de internet ou servidor em baixo
    }
  }

  Future<bool> sincronizarObjetivos(List<Map<String, dynamic>> acoes) async {
    try {
      final url = Uri.parse('$baseUrl/mobile/sincronizar-objetivos');
      final response = await http.post(
        url,
        headers: await _cabecalhosAutenticados(),
        body: jsonEncode({'acoes': acoes}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Erro API Objetivos: ${response.body}");
        return false;
      }
    } catch (e) {
      print('Erro ao sincronizar fila de objetivos: $e');
      return false;
    }
  }

  // ENVIAR DADOS (SUBMETER CANDIDATURAS / PEDIDOS OFFLINE)
  Future<bool> enviarPedido(Map<String, dynamic> pedidoMap) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile/pedidos'),
        body: jsonEncode(pedidoMap),
        headers: await _cabecalhosAutenticados(),
      );

      // Código 201 significa "Created" (Criado com sucesso no servidor)
      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao enviar pedido para a API: $e');
      return false;
    }
  }

  Future<void> registarFcmToken(String token) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: await _cabecalhosAutenticados(),
        body: jsonEncode({'token': token}),
      );
    } catch (_) {
      // O token volta a ser enviado no próximo arranque/refresh.
    }
  }

  Future<Map<String, dynamic>> registar(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Sem ligação ao servidor.'};
    }
  }

  Future<Map<String, dynamic>> recuperarPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Sem ligação ao servidor.'};
    }
  }

  Future<Map<String, dynamic>> atualizarPerfil(int id, String nome, String email) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/update/$id'),
        headers: await _cabecalhosAutenticados(),
        body: jsonEncode({'NOME_COMPLETO_UTILIZADOR': nome, 'EMAIL_UTILIZADOR': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Sem ligação ao servidor.'};
    }
  }

  Future<Map<String, dynamic>> mudarPassword(int id, String passwordAtual, String novaPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/mudar-password/$id'),
        headers: await _cabecalhosAutenticados(),
        body: jsonEncode({'passwordAtual': passwordAtual, 'novaPassword': novaPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Sem ligação ao servidor.'};
    }
  }

  // OBTER DETALHES COMPLETOS DE UM PEDIDO
  Future<Map<String, dynamic>?> obterDetalhesPedidoApi(int idPedido) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/detalhes/$idPedido'),
        headers: await _cabecalhosAutenticados(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success']) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      print('Erro ao obter detalhes do pedido na API: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchEstatisticasConsultor(int idUtilizador) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estatisticas/consultor/$idUtilizador'),
        headers: await _cabecalhosAutenticados(),
      );

      if (response.statusCode == 200) {
        final corpo = jsonDecode(response.body);
        if (corpo['success']) {
          return corpo['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> terminarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('idUtilizador');
    await prefs.remove('nomeCompleto');
    await prefs.remove('email');
    await prefs.remove('avatarUrl');
    await prefs.setBool('isLogged', false);
  }

  Future<bool> marcarNotificacaoComoLida(int idNotificacao) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/notificacoes/$idNotificacao/read'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> marcarTodasNotificacoesComoLidas(int idUtilizador) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/notificacoes/user/$idUtilizador/read-all'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
