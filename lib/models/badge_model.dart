class BadgeModel {
  final int? idBadge;
  final int idCategoria;
  final int idNivel;
  final int idAdmin;
  final String nomeBadge;
  final String? descricaoBadge;
  final String categoriaBadge;
  final int pontosBadge;
  final String urlImagem;
  final int? tempoExpiracaoBadge;
  final int isPremium; //Conquistas especiais
  final int? validadeMeses;
  final String validadeExpiracao;

  BadgeModel({
    this.idBadge,
    required this.idCategoria,
    required this.idNivel,
    required this.idAdmin,
    required this.nomeBadge,
    this.descricaoBadge,
    required this.categoriaBadge,
    required this.pontosBadge,
    required this.urlImagem,
    this.tempoExpiracaoBadge,
    required this.isPremium,
    this.validadeMeses,
    required this.validadeExpiracao,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_BADGE': idBadge,
      'ID_CATEGORIA': idCategoria,
      'ID_NIVEL': idNivel,
      'ID_ADMIN': idAdmin,
      'NOME_BADGE': nomeBadge,
      'DESCRICAO_BADGE': descricaoBadge,
      'CATEGORIA_BADGE': categoriaBadge,
      'PONTOS_BADGE': pontosBadge,
      'URL_IMAGEM': urlImagem,
      'TEMPO_EXPIRACAO_BADGE': tempoExpiracaoBadge,
      'IS_PREMIUM': isPremium,
      'VALIDADE_MESES': validadeMeses,
      'VALIDADE_EXPIRACAO': validadeExpiracao,
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      idBadge: map['ID_BADGE'],
      idCategoria: map['ID_CATEGORIA'],
      idNivel: map['ID_NIVEL'],
      idAdmin: map['ID_ADMIN'],
      nomeBadge: map['NOME_BADGE'],
      descricaoBadge: map['DESCRICAO_BADGE'],
      categoriaBadge: map['CATEGORIA_BADGE'],
      pontosBadge: map['PONTOS_BADGE'],
      urlImagem: map['URL_IMAGEM'],
      tempoExpiracaoBadge: map['TEMPO_EXPIRACAO_BADGE'],
      isPremium: map['IS_PREMIUM'] is bool
          ? (map['IS_PREMIUM'] ? 1 : 0)
          : map['IS_PREMIUM'],
      validadeMeses: map['VALIDADE_MESES'],
      validadeExpiracao: map['VALIDADE_EXPIRACAO'],
    );
  }
}
