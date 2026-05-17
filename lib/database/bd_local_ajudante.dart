import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BDLocalAjudante {
  static final BDLocalAjudante _instance = BDLocalAjudante._internal();
  static Database? _database;

  BDLocalAjudante._internal();

  factory BDLocalAjudante() => _instance;

  Future<Database> get database async {
    //se a bd já estiver inicializada retorna-a, senao inicia
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'softinsa_badges.db');
    //caso a bd já exista esta função não é chamada
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, //só é chamada na primeira vez que a bd é criada
    );
  }

  Future _onCreate(Database db, int version) async {
    //Tabelas sem chaves estrangeiras de outras
    await db.execute('''
      CREATE TABLE OBJETIVO_TIMELINE (
        ID_OBJETIVO INTEGER PRIMARY KEY AUTOINCREMENT,
        TITULO TEXT NOT NULL,
        DESCRICAO TEXT,
        DATA_OBJETIVO TEXT NOT NULL,
        STATUS TEXT NOT NULL,
        DATA_CONCLUSAO TEXT,
        ORIGEM TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE SERVICE_LINE (
        ID_SERVICE_LINE INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_ADMIN INTEGER NOT NULL,
        ID_SLL INTEGER,
        NOME_SERVICE_LINE TEXT NOT NULL,
        DESCRICAO_SERVICE_LINE TEXT,
        ESTADO_ATIVO_SERVICE_LINE INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE NOTIFICACAO (
        ID_NOTIFICACAO INTEGER PRIMARY KEY AUTOINCREMENT,
        TITULO_NOTIFICACAO TEXT NOT NULL,
        MENSAGEM_NOTIFICACAO TEXT NOT NULL,
        DATA_ENVIO_NOTIFICACAO TEXT NOT NULL,
        TIPO_NOTIFICACAO TEXT,
        ESTADO_LIDO INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE MARCO_CONQUISTA (
        ID_MARCO INTEGER PRIMARY KEY AUTOINCREMENT,
        TITULO_MARCO TEXT NOT NULL,
        DESCRICAO_MARCO TEXT,
        PONTOS_EXTRA INTEGER NOT NULL,
        REGRA_ATRIBUICAO TEXT NOT NULL,
        URL_IMAGEM_MARCO TEXT NOT NULL
      )
    ''');

    //Tabelas com dependências de Nível 1
    await db.execute('''
      CREATE TABLE UTILIZADOR (
        ID_UTILIZADOR INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_ADMIN INTEGER,
        ID_OBJETIVO INTEGER,
        NOME_COMPLETO_UTILIZADOR TEXT NOT NULL,
        EMAIL_UTILIZADOR TEXT UNIQUE NOT NULL,
        ESTADO_CONTA_UTILIZADOR TEXT NOT NULL,
        DATA_REGISTO_UTILIZADOR TEXT NOT NULL,
        PERFIL_UTILIZADOR TEXT NOT NULL,
        PASSWORD_UTILIZADOR TEXT NOT NULL,
        IS_PRIMEIRO_ACESSO INTEGER NOT NULL,
        FOREIGN KEY (ID_OBJETIVO) REFERENCES OBJETIVO_TIMELINE (ID_OBJETIVO)
      )
    ''');

    await db.execute('''
      CREATE TABLE AREA (
        ID_AREA INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER NOT NULL,
        ID_SERVICE_LINE INTEGER NOT NULL,
        NOME_AREA TEXT NOT NULL,
        DESCRICAO_AREA TEXT,
        FOREIGN KEY (ID_UTILIZADOR) REFERENCES UTILIZADOR (ID_UTILIZADOR),
        FOREIGN KEY (ID_SERVICE_LINE) REFERENCES SERVICE_LINE (ID_SERVICE_LINE)
      )
    ''');

    await db.execute('''
      CREATE TABLE CONSULTOR (
        ID_CONSULTOR INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER,
        DATA_ENTRADA_EMPRESA TEXT NOT NULL,
        PONTUACAO_TOTAL INTEGER NOT NULL,
        FOREIGN KEY (ID_UTILIZADOR) REFERENCES UTILIZADOR (ID_UTILIZADOR)
      )
    ''');

    await db.execute('''
      CREATE TABLE BADGE (
        ID_BADGE INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_CATEGORIA INTEGER NOT NULL,
        ID_NIVEL INTEGER NOT NULL,
        ID_ADMIN INTEGER NOT NULL,
        NOME_BADGE TEXT NOT NULL,
        DESCRICAO_BADGE TEXT,
        CATEGORIA_BADGE TEXT NOT NULL,
        PONTOS_BADGE INTEGER NOT NULL,
        URL_IMAGEM TEXT NOT NULL,
        TEMPO_EXPIRACAO_BADGE INTEGER,
        IS_PREMIUM INTEGER NOT NULL,
        VALIDADE_MESES INTEGER,
        VALIDADE_EXPIRACAO TEXT NOT NULL
      )
    ''');

    //Tabelas com dependências de Nível 2
    await db.execute('''
      CREATE TABLE PEDIDO (
        ID_PEDIDO INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER NOT NULL,
        ID_TM INTEGER,
        ID_SLL INTEGER,
        ID_BADGE INTEGER NOT NULL,
        DATA_SUBMISSAO_PEDIDO TEXT NOT NULL,
        ESTADO_PEDIDO TEXT NOT NULL,
        COMENTARIO_CONSULTOR TEXT,
        DATA_ULTIMA_ATUALIZACAO TEXT NOT NULL,
        FOREIGN KEY (ID_UTILIZADOR) REFERENCES UTILIZADOR (ID_UTILIZADOR),
        FOREIGN KEY (ID_BADGE) REFERENCES BADGE (ID_BADGE)
      )
    ''');

    await db.execute('''
      CREATE TABLE REQUISITO (
        ID_REQUISITO INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_BADGE INTEGER NOT NULL,
        ID_REQUISITO_PADRAO INTEGER,
        TITULO_REQUISITO TEXT NOT NULL,
        DESCRICAO_REQUISITO TEXT NOT NULL,
        TIPO_REQUISITO TEXT NOT NULL,
        ORDEM_REQUISITO INTEGER,
        FOREIGN KEY (ID_BADGE) REFERENCES BADGE (ID_BADGE)
      )
    ''');

    await db.execute('''
      CREATE TABLE CONSULTOR_BADGE (
        ID_CONSULTOR INTEGER NOT NULL,
        ID_BADGE INTEGER NOT NULL,
        DATA_ATRIBUICAO_BADGE TEXT NOT NULL,
        DATA_EXPIRACAO TEXT,
        LINK_UNICO_BADGE TEXT NOT NULL,
        STATUS_GALERIA_PUBLICA INTEGER NOT NULL,
        PRIMARY KEY (ID_CONSULTOR, ID_BADGE),
        FOREIGN KEY (ID_CONSULTOR) REFERENCES CONSULTOR (ID_CONSULTOR),
        FOREIGN KEY (ID_BADGE) REFERENCES BADGE (ID_BADGE)
      )
    ''');

    await db.execute('''
      CREATE TABLE HISTORICO_PONTUACAO (
        ID_HISTORICO_PONTOS INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER NOT NULL,
        DATA_ATRIBUICAO TEXT NOT NULL,
        PONTOS_OBTIDOS INTEGER NOT NULL,
        ORIGEM_PONTOS TEXT,
        FOREIGN KEY (ID_UTILIZADOR) REFERENCES UTILIZADOR (ID_UTILIZADOR)
      )
    ''');

    //Tabelas com dependências de Nível 3
    await db.execute('''
      CREATE TABLE EVIDENCIA (
        ID_EVIDENCIA INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_PEDIDO INTEGER NOT NULL,
        ID_REQUISITO INTEGER NOT NULL,
        NOME_FICHEIRO TEXT NOT NULL,
        REQUISITO_MAPEADO TEXT,
        URL_FICHEIRO TEXT NOT NULL,
        FOREIGN KEY (ID_PEDIDO) REFERENCES PEDIDO (ID_PEDIDO),
        FOREIGN KEY (ID_REQUISITO) REFERENCES REQUISITO (ID_REQUISITO)
      )
    ''');

    await db.execute('''
      CREATE TABLE CERTIFICADO_PDF (
        ID_CERTIFICADO INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_CONSULTOR INTEGER NOT NULL,
        ID_BADGE INTEGER NOT NULL,
        URL_CERTIFICADO TEXT NOT NULL,
        DATA_EISSAO_CERTIFICADO TEXT NOT NULL,
        CODIGO_VERIFICACAO TEXT NOT NULL,
        FOREIGN KEY (ID_CONSULTOR) REFERENCES CONSULTOR (ID_CONSULTOR),
        FOREIGN KEY (ID_BADGE) REFERENCES BADGE (ID_BADGE)
      )
    ''');
  }

  // Métodos de ajuda
  Future<int> inserir(String tabela, Map<String, dynamic> dados) async {
    //recebe nome de uma tabela e um mapa de dados e insere na tabela
    final db = await database;
    return await db.insert(tabela, dados,
        conflictAlgorithm: ConflictAlgorithm.replace); //substitui se já existir
  }

  Future<List<Map<String, dynamic>>> listar(String tabela) async {
    //recebe o nome de uma tabela e retorna todos os dados dela com Select *
    final db = await database;
    return await db.query(tabela);
  }
}
