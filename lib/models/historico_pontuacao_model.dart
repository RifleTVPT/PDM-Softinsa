class HistoricoPontuacao {
  final int? idHistoricoPontos;
  final int idUtilizador;
  final String dataAtribuicao;
  final int pontosObtidos;
  final String? origemPontos; // Ex: 'Badge Cloud Nível A', 'Bonus Timeline'

  HistoricoPontuacao({
    this.idHistoricoPontos,
    required this.idUtilizador,
    required this.dataAtribuicao,
    required this.pontosObtidos,
    this.origemPontos,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_HISTORICO_PONTOS': idHistoricoPontos,
      'ID_UTILIZADOR': idUtilizador,
      'DATA_ATRIBUICAO': dataAtribuicao,
      'PONTOS_OBTIDOS': pontosObtidos,
      'ORIGEM_PONTOS': origemPontos,
    };
  }

  factory HistoricoPontuacao.fromMap(Map<String, dynamic> map) {
    return HistoricoPontuacao(
      idHistoricoPontos: map['ID_HISTORICO_PONTOS'],
      idUtilizador: map['ID_UTILIZADOR'],
      dataAtribuicao: map['DATA_ATRIBUICAO'],
      pontosObtidos: map['PONTOS_OBTIDOS'],
      origemPontos: map['ORIGEM_PONTOS'],
    );
  }
}
