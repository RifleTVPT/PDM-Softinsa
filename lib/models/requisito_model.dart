class Requisito {
  final int? idRequisito;
  final int idBadge;
  final int? idRequisitoPadrao;
  final String tituloRequisito;
  final String descricaoRequisito;
  final String tipoRequisito;
  final int? ordemRequisito;

  Requisito({
    this.idRequisito,
    required this.idBadge,
    this.idRequisitoPadrao,
    required this.tituloRequisito,
    required this.descricaoRequisito,
    required this.tipoRequisito,
    this.ordemRequisito,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_REQUISITO': idRequisito,
      'ID_BADGE': idBadge,
      'ID_REQUISITO_PADRAO': idRequisitoPadrao,
      'TITULO_REQUISITO': tituloRequisito,
      'DESCRICAO_REQUISITO': descricaoRequisito,
      'TIPO_REQUISITO': tipoRequisito,
      'ORDEM_REQUISITO': ordemRequisito,
    };
  }

  factory Requisito.fromMap(Map<String, dynamic> map) {
    return Requisito(
      idRequisito: map['ID_REQUISITO'],
      idBadge: map['ID_BADGE'],
      idRequisitoPadrao: map['ID_REQUISITO_PADRAO'],
      tituloRequisito: map['TITULO_REQUISITO'],
      descricaoRequisito: map['DESCRICAO_REQUISITO'],
      tipoRequisito: map['TIPO_REQUISITO'],
      ordemRequisito: map['ORDEM_REQUISITO'],
    );
  }
}
