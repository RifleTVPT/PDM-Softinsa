import 'api_servico.dart';

class AssetUrl {
  static String? resolver(String? url) {
    if (url == null) return null;
    final value = url.trim();
    if (value.isEmpty || value == 'null' || value == 'undefined') return null;
    if (value.startsWith('data:')) return value;
    if (RegExp(r'^https?://localhost:3000', caseSensitive: false).hasMatch(value)) {
      return value.replaceFirst(RegExp(r'^https?://localhost:3000', caseSensitive: false), ApiServico.baseUrl);
    }
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) return value;
    if (value.startsWith('/')) return '${ApiServico.baseUrl}$value';
    return '${ApiServico.baseUrl}/uploads/${value.replaceFirst(RegExp(r'^uploads/'), '')}';
  }

  static String imagemBadge(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty ||
        value == 'null' ||
        value == 'undefined' ||
        value.contains('placeholder') ||
        value.contains('3112946.png') ||
        value.contains('default-trophy') ||
        value.contains('trofeu-padrao')) {
      return '${ApiServico.baseUrl}/uploads/default-trophy.png';
    }
    return resolver(value) ?? '${ApiServico.baseUrl}/uploads/default-trophy.png';
  }
}
