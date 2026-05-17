class NotificacaoModel {
  final int? idNotificacao;
  final String tituloNotificacao;
  final String mensagemNotificacao;
  final String dataEnvioNotificacao;
  final String tipoNotificacao; // 'aprovado', 'rejeitado', 'expiracao', 'aviso'
  final int estadoLido; // 0 = Não Lido, 1 = Lido

  NotificacaoModel({
    this.idNotificacao,
    required this.tituloNotificacao,
    required this.mensagemNotificacao,
    required this.dataEnvioNotificacao,
    required this.tipoNotificacao,
    required this.estadoLido,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_NOTIFICACAO': idNotificacao,
      'TITULO_NOTIFICACAO': tituloNotificacao,
      'MENSAGEM_NOTIFICACAO': mensagemNotificacao,
      'DATA_ENVIO_NOTIFICACAO': dataEnvioNotificacao,
      'TIPO_NOTIFICACAO': tipoNotificacao,
      'ESTADO_LIDO': estadoLido,
    };
  }

  factory NotificacaoModel.fromMap(Map<String, dynamic> map) {
    return NotificacaoModel(
      idNotificacao: map['ID_NOTIFICACAO'],
      tituloNotificacao: map['TITULO_NOTIFICACAO'] ?? '',
      mensagemNotificacao: map['MENSAGEM_NOTIFICACAO'] ?? '',
      dataEnvioNotificacao: map['DATA_ENVIO_NOTIFICACAO'] ?? '',
      tipoNotificacao: map['TIPO_NOTIFICACAO'] ?? 'aviso',
      estadoLido: map['ESTADO_LIDO'] is bool
          ? (map['ESTADO_LIDO'] ? 1 : 0)
          : (map['ESTADO_LIDO'] ?? 0),
    );
  }
}
