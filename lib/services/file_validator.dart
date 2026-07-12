import 'dart:io';

class FileValidator {
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'txt',
    'rtf',
    'ppt',
    'pptx',
    'zip',
    'rar'
  ];

  //Valida se a extensão é permitida
  static bool isValidFile(File file) {
    String extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  //Extrai o Requisito Mapeado do nome do ficheiro
  //Exemplo: "Evidencia_Joao_A1.pdf" -> Retorna "A1"
  static String? extrairRequisitoDoNome(String caminhoCompleto) {
    // Pega apenas no nome do ficheiro (ignora a pasta)
    String nomeFicheiro = caminhoCompleto.split(Platform.pathSeparator).last;

    // Expressão regular para encontrar códigos isolados como A1, B2, F10.
    RegExp regExp = RegExp(r'(?:^|[^A-Z0-9])([A-Z][0-9]+)(?=[^A-Z0-9]|$)',
        caseSensitive: false);

    Match? match = regExp.firstMatch(nomeFicheiro);

    if (match != null) {
      return match.group(1)?.toUpperCase(); // Retorna "A1"
    }

    return null; // Não encontrou nenhum código de requisito no nome do ficheiro
  }

  static bool textoContemCodigoRequisito(String texto, String codigo) {
    final normalizado = texto.toUpperCase();
    final codigoNorm = codigo.toUpperCase();
    return RegExp(
      '(?:^|[^A-Z0-9])${RegExp.escape(codigoNorm)}(?=[^A-Z0-9]|\$)',
      caseSensitive: false,
    ).hasMatch(normalizado);
  }

  static double getFileSizeInMB(File file) {
    //calcula o tamanho do ficheiro em MB covertendo de bytes
    int sizeInBytes = file.lengthSync();
    return sizeInBytes / (1024 * 1024);
  }
}
