class Area {
  final int? idArea;
  final int idUtilizador;
  final int idServiceLine;
  final String nomeArea;
  final String? descricaoArea;

  Area({
    this.idArea,
    required this.idUtilizador,
    required this.idServiceLine,
    required this.nomeArea,
    this.descricaoArea,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_AREA': idArea,
      'ID_UTILIZADOR': idUtilizador,
      'ID_SERVICE_LINE': idServiceLine,
      'NOME_AREA': nomeArea,
      'DESCRICAO_AREA': descricaoArea,
    };
  }

  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      idArea: map['ID_AREA'],
      idUtilizador: map['ID_UTILIZADOR'],
      idServiceLine: map['ID_SERVICE_LINE'],
      nomeArea: map['NOME_AREA'],
      descricaoArea: map['DESCRICAO_AREA'],
    );
  }
}
