class Objetivo {
  final int? idObjetivo;
  final String titulo;
  final String? descricao;
  final String dataObjetivo;
  final String status; // Ex:'Pendente', 'Concluído'
  final String? dataConclusao;
  final String origem; // Ex:'Manual', 'Sugerido'

  Objetivo({
    this.idObjetivo,
    required this.titulo,
    this.descricao,
    required this.dataObjetivo,
    required this.status,
    this.dataConclusao,
    required this.origem,
  });

  Map<String, dynamic> toMap() {
    return {
      'ID_OBJETIVO': idObjetivo,
      'TITULO': titulo,
      'DESCRICAO': descricao,
      'DATA_OBJETIVO': dataObjetivo,
      'STATUS': status,
      'DATA_CONCLUSAO': dataConclusao,
      'ORIGEM': origem,
    };
  }

  factory Objetivo.fromMap(Map<String, dynamic> map) {
    return Objetivo(
      idObjetivo: map['ID_OBJETIVO'],
      titulo: map['TITULO'],
      descricao: map['DESCRICAO'],
      dataObjetivo: map['DATA_OBJETIVO'],
      status: map['STATUS'],
      dataConclusao: map['DATA_CONCLUSAO'],
      origem: map['ORIGEM'],
    );
  }
}
