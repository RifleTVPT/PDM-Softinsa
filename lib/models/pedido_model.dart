class Pedido {
  final int? idPedido;
  final int idUtilizador;
  final int? idTm;
  final int? idSll;
  final int idBadge;
  final String dataSubmissaoPedido;
  final String estadoPedido; //Status em tempo real
  final String? comentarioConsultor;
  final String dataUltimaAtualizacao;

  Pedido({
    this.idPedido,
    required this.idUtilizador,
    this.idTm,
    this.idSll,
    required this.idBadge,
    required this.dataSubmissaoPedido,
    required this.estadoPedido,
    this.comentarioConsultor,
    required this.dataUltimaAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_PEDIDO': idPedido,
      'ID_UTILIZADOR': idUtilizador,
      'ID_TM': idTm,
      'ID_SLL': idSll,
      'ID_BADGE': idBadge,
      'DATA_SUBMISSAO_PEDIDO': dataSubmissaoPedido,
      'ESTADO_PEDIDO': estadoPedido,
      'COMENTARIO_CONSULTOR': comentarioConsultor,
      'DATA_ULTIMA_ATUALIZACAO': dataUltimaAtualizacao,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      idPedido: map['ID_PEDIDO'],
      idUtilizador: map['ID_UTILIZADOR'],
      idTm: map['ID_TM'],
      idSll: map['ID_SLL'],
      idBadge: map['ID_BADGE'],
      dataSubmissaoPedido: map['DATA_SUBMISSAO_PEDIDO'],
      estadoPedido: map['ESTADO_PEDIDO'],
      comentarioConsultor: map['COMENTARIO_CONSULTOR'],
      dataUltimaAtualizacao: map['DATA_ULTIMA_ATUALIZACAO'],
    );
  }
}
