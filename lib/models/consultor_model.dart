class Consultor {
  final int? idConsultor;
  final int? idUtilizador;
  final String dataEntradaEmpresa;
  final int pontuacaoTotal;

  Consultor({
    this.idConsultor,
    this.idUtilizador,
    required this.dataEntradaEmpresa,
    required this.pontuacaoTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_CONSULTOR': idConsultor,
      'ID_UTILIZADOR': idUtilizador,
      'DATA_ENTRADA_EMPRESA': dataEntradaEmpresa,
      'PONTUACAO_TOTAL': pontuacaoTotal,
    };
  }

  factory Consultor.fromMap(Map<String, dynamic> map) {
    return Consultor(
      idConsultor: map['ID_CONSULTOR'],
      idUtilizador: map['ID_UTILIZADOR'],
      dataEntradaEmpresa: map['DATA_ENTRADA_EMPRESA'],
      pontuacaoTotal: map['PONTUACAO_TOTAL'],
    );
  }
}
