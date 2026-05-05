import 'dart:convert'; // Essencial para converter JSON de/e para Dart
import 'package:http/http.dart' as http; // Biblioteca para fazer pedidos HTTP
import '../models/utilizador_model.dart';

class ApiServico {
  // Vamos substituir pelo URL real do servidor (API) quando este estiver feito e online
  static const String baseUrl = "https://sua-api-aqui.com/api";

  // LOGIN
  Future<Utilizador?> login(String email, String password) async {
    try {
      final response = await http.post(
        // Envia o email e password para a API
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {
          'Content-Type': 'application/json'
        }, // Informa ao servidor que estamos a enviar um ficheiro do tipo JSON
      );

      // Na arquitetura REST o código 200 significa Sucesso
      if (response.statusCode == 200) {
        // Se o login for bem sucedido retorna o utilizador
        return Utilizador.fromMap(jsonDecode(
            response.body)); // Converte o JSON para um objeto Utilizador
      }
      return null; // Credenciais inválidas ou erro
    } catch (e) {
      print("Erro de rede no Login: $e");
      return null;
    }
  }

  // OBTER DADOS (MEGA JSON) a API dá uma única resposta para vários pedidos
  Future<Map<String, dynamic>?> fetchDadosSincronizacao() async {
    try {
      // Fazemos um único pedido GET para obter todas as listas iniciais necessárias
      final response = await http.get(Uri.parse('$baseUrl/sync'));

      if (response.statusCode == 200) {
        // Converte o corpo (String JSON) num Map (Dicionário DART)
        // O JSON devolvido pela API deve ter listas lá dentro (ex: "badges": [...], "service_lines": [...])
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Erro na API ao sincronizar: Código ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Erro no pedido de sincronização: $e');
      return null; // Retorna nulo em caso de falta de internet ou servidor em baixo
    }
  }

  // ENVIAR DADOS (SUBMETER CANDIDATURAS / PEDIDOS OFFLINE)
  Future<bool> enviarPedido(Map<String, dynamic> pedidoMap) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pedidos'),
        body: jsonEncode(pedidoMap),
        headers: {'Content-Type': 'application/json'},
      );

      // Código 201 significa "Created" (Criado com sucesso no servidor)
      return response.statusCode == 201;
    } catch (e) {
      print('Erro ao enviar pedido para a API: $e');
      return false;
    }
  }
}
