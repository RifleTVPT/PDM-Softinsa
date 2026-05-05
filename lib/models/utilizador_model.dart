class Utilizador {
  final int?
      idUtilizador; //permite null porque no inicio nao tem e vai ser gerado pela bd
  final int idAdmin;
  final int idObjetivo;
  final String nomeCompletoUtilizador;
  final String emailUtilizador;
  final String estadoContaUtilizador;
  final String dataRegistoUtilizador;
  final String perfilUtilizador;
  final String passwordUtilizador;
  final int isPrimeiroAcesso; //(0 ou 1)

  Utilizador({
    this.idUtilizador,
    required this.idAdmin,
    required this.idObjetivo,
    required this.nomeCompletoUtilizador,
    required this.emailUtilizador,
    required this.estadoContaUtilizador,
    required this.dataRegistoUtilizador,
    required this.perfilUtilizador,
    required this.passwordUtilizador,
    required this.isPrimeiroAcesso,
  });

  Map<String, dynamic> toMap() {
    //obrigatório para inserir dados no sqflite
    return {
      'ID_UTILIZADOR': idUtilizador, //maisculas para ser igual ao script sql
      'ID_ADMIN': idAdmin,
      'ID_OBJETIVO': idObjetivo,
      'NOME_COMPLETO_UTILIZADOR': nomeCompletoUtilizador,
      'EMAIL_UTILIZADOR': emailUtilizador,
      'ESTADO_CONTA_UTILIZADOR': estadoContaUtilizador,
      'DATA_REGISTO_UTILIZADOR': dataRegistoUtilizador,
      'PERFIL_UTILIZADOR': perfilUtilizador,
      'PASSWORD_UTILIZADOR': passwordUtilizador,
      'IS_PRIMEIRO_ACESSO':
          isPrimeiroAcesso, //transforma para 0 ou 1 se for preciso
    };
  }

  factory Utilizador.fromMap(Map<String, dynamic> map) {
    //pega no map e cria um objeto utilizador
    return Utilizador(
      idUtilizador: map['ID_UTILIZADOR'],
      idAdmin: map['ID_ADMIN'],
      idObjetivo: map['ID_OBJETIVO'],
      nomeCompletoUtilizador: map['NOME_COMPLETO_UTILIZADOR'],
      emailUtilizador: map['EMAIL_UTILIZADOR'],
      estadoContaUtilizador: map['ESTADO_CONTA_UTILIZADOR'],
      dataRegistoUtilizador: map['DATA_REGISTO_UTILIZADOR'],
      perfilUtilizador: map['PERFIL_UTILIZADOR'],
      passwordUtilizador: map['PASSWORD_UTILIZADOR'],
      isPrimeiroAcesso: map['IS_PRIMEIRO_ACESSO'] is bool
          ? (map['IS_PRIMEIRO_ACESSO'] ? 1 : 0)
          //transformar bool para int (0 ou 1)
          : map['IS_PRIMEIRO_ACESSO'], //se ja for int, mantem o valor
    );
  }
}
