class ServiceLine {
  final int? idServiceLine;
  final int idAdmin;
  final int? idSll;
  final String nomeServiceLine;
  final String? descricaoServiceLine;
  final int estadoAtivoServiceLine; //(0 ou 1)

  ServiceLine({
    this.idServiceLine,
    required this.idAdmin,
    this.idSll,
    required this.nomeServiceLine,
    this.descricaoServiceLine,
    required this.estadoAtivoServiceLine,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_SERVICE_LINE': idServiceLine,
      'ID_ADMIN': idAdmin,
      'ID_SLL': idSll,
      'NOME_SERVICE_LINE': nomeServiceLine,
      'DESCRICAO_SERVICE_LINE': descricaoServiceLine,
      'ESTADO_ATIVO_SERVICE_LINE': estadoAtivoServiceLine,
    };
  }

  factory ServiceLine.fromMap(Map<String, dynamic> map) {
    return ServiceLine(
      idServiceLine: map['ID_SERVICE_LINE'],
      idAdmin: map['ID_ADMIN'],
      idSll: map['ID_SLL'],
      nomeServiceLine: map['NOME_SERVICE_LINE'],
      descricaoServiceLine: map['DESCRICAO_SERVICE_LINE'],
      estadoAtivoServiceLine: map['ESTADO_ATIVO_SERVICE_LINE'] is bool
          ? (map['ESTADO_ATIVO_SERVICE_LINE'] ? 1 : 0)
          : map['ESTADO_ATIVO_SERVICE_LINE'],
    );
  }
}
