import 'dart:io';

class FileValidator {
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'png', 'docx'];

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

    // Expressão Regular para encontrar uma letra seguida de números (ex: A1, B2, C10)
    // O padrão r'([A-E][0-9]+)' procura: letras de A a E seguidas de 1 ou mais números
    RegExp regExp = RegExp(r'([A-E][0-9]+)', caseSensitive: false);

    Match? match = regExp.firstMatch(nomeFicheiro);

    if (match != null) {
      return match.group(0)?.toUpperCase(); // Retorna "A1"
    }

    return null; // Não encontrou nenhum código de requisito no nome do ficheiro
  }

  static double getFileSizeInMB(File file) {
    //calcula o tamanho do ficheiro em MB covertendo de bytes
    int sizeInBytes = file.lengthSync();
    return sizeInBytes / (1024 * 1024);
  }
}
