class ConsultorBadge {
  final int idConsultor;
  final int idBadge;
  final String dataAtribuicaoBadge;
  final String? dataExpiracao;
  final String linkUnicoBadge;
  final int statusGaleriaPublica;

  ConsultorBadge({
    required this.idConsultor,
    required this.idBadge,
    required this.dataAtribuicaoBadge,
    this.dataExpiracao,
    required this.linkUnicoBadge,
    required this.statusGaleriaPublica,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_CONSULTOR': idConsultor,
      'ID_BADGE': idBadge,
      'DATA_ATRIBUICAO_BADGE': dataAtribuicaoBadge,
      'DATA_EXPIRACAO': dataExpiracao,
      'LINK_UNICO_BADGE': linkUnicoBadge,
      'STATUS_GALERIA_PUBLICA': statusGaleriaPublica,
    };
  }
}
