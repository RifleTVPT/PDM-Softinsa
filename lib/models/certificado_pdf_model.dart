class CertificadoPDF {
  final int? idCertificado;
  final int idConsultor;
  final int idBadge;
  final String urlCertificado;
  final String dataEmissaoCertificado;
  final String codigoVerificacao;

  CertificadoPDF({
    this.idCertificado,
    required this.idConsultor,
    required this.idBadge,
    required this.urlCertificado,
    required this.dataEmissaoCertificado,
    required this.codigoVerificacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_CERTIFICADO': idCertificado,
      'ID_CONSULTOR': idConsultor,
      'ID_BADGE': idBadge,
      'URL_CERTIFICADO': urlCertificado,
      'DATA_EISSAO_CERTIFICADO': dataEmissaoCertificado,
      'CODIGO_VERIFICACAO': codigoVerificacao,
    };
  }

  factory CertificadoPDF.fromMap(Map<String, dynamic> map) {
    return CertificadoPDF(
      idCertificado: map['ID_CERTIFICADO'],
      idConsultor: map['ID_CONSULTOR'],
      idBadge: map['ID_BADGE'],
      urlCertificado: map['URL_CERTIFICADO'],
      dataEmissaoCertificado: map['DATA_EISSAO_CERTIFICADO'],
      codigoVerificacao: map['CODIGO_VERIFICACAO'],
    );
  }
}
