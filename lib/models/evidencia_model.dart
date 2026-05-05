class Evidencia {
  final int? idEvidencia;
  final int idPedido;
  final int idRequisito;
  final String nomeFicheiro;
  final String? requisitoMapeado;
  final String urlFicheiro;

  Evidencia({
    this.idEvidencia,
    required this.idPedido,
    required this.idRequisito,
    required this.nomeFicheiro,
    this.requisitoMapeado,
    required this.urlFicheiro,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_EVIDENCIA': idEvidencia,
      'ID_PEDIDO': idPedido,
      'ID_REQUISITO': idRequisito,
      'NOME_FICHEIRO': nomeFicheiro,
      'REQUISITO_MAPEADO': requisitoMapeado,
      'URL_FICHEIRO': urlFicheiro,
    };
  }

  factory Evidencia.fromMap(Map<String, dynamic> map) {
    return Evidencia(
      idEvidencia: map['ID_EVIDENCIA'],
      idPedido: map['ID_PEDIDO'],
      idRequisito: map['ID_REQUISITO'],
      nomeFicheiro: map['NOME_FICHEIRO'],
      requisitoMapeado: map['REQUISITO_MAPEADO'],
      urlFicheiro: map['URL_FICHEIRO'],
    );
  }
}
