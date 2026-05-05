class MarcoConquista {
  final int? idMarco;
  final String tituloMarco;
  final String? descricaoMarco;
  final int pontosExtra;
  final String regraAtribuicao;
  final String urlImagemMarco;

  MarcoConquista({
    this.idMarco,
    required this.tituloMarco,
    this.descricaoMarco,
    required this.pontosExtra,
    required this.regraAtribuicao,
    required this.urlImagemMarco,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_MARCO': idMarco,
      'TITULO_MARCO': tituloMarco,
      'DESCRICAO_MARCO': descricaoMarco,
      'PONTOS_EXTRA': pontosExtra,
      'REGRA_ATRIBUICAO': regraAtribuicao,
      'URL_IMAGEM_MARCO': urlImagemMarco,
    };
  }

  factory MarcoConquista.fromMap(Map<String, dynamic> map) {
    return MarcoConquista(
      idMarco: map['ID_MARCO'],
      tituloMarco: map['TITULO_MARCO'],
      descricaoMarco: map['DESCRICAO_MARCO'],
      pontosExtra: map['PONTOS_EXTRA'],
      regraAtribuicao: map['REGRA_ATRIBUICAO'],
      urlImagemMarco: map['URL_IMAGEM_MARCO'],
    );
  }
}
