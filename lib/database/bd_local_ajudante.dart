import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BDLocalAjudante {
  static const _nomeBD = 'softinsa_badges.db';
  static const _versaoBD = 7;

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
    String path = join(await getDatabasesPath(), _nomeBD);
    //caso a bd já exista esta função não é chamada
    return await openDatabase(
      path,
      version: _versaoBD,
      onCreate: _onCreate, //só é chamada na primeira vez que a bd é criada
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS NIVEL (
          ID_NIVEL INTEGER PRIMARY KEY,
          ID_AREA INTEGER NOT NULL,
          NOME_NIVEL TEXT NOT NULL,
          ORDEM_HIERARQUICA INTEGER NOT NULL,
          DESCRICAO_NIVEL TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS MARCO_CONSULTOR (
          ID_CONSULTOR INTEGER NOT NULL,
          ID_MARCO INTEGER NOT NULL,
          DATA_CONQUISTA TEXT,
          PRIMARY KEY (ID_CONSULTOR, ID_MARCO)
        )
      ''');
      final colunasConsultor =
          await db.rawQuery('PRAGMA table_info(CONSULTOR)');
      if (!colunasConsultor.any((c) => c['name'] == 'ID_AREA')) {
        await db.execute('ALTER TABLE CONSULTOR ADD COLUMN ID_AREA INTEGER');
        await db.execute('ALTER TABLE CONSULTOR ADD COLUMN NOTIFICACOES_LIDAS TEXT DEFAULT "[]"');
      }

    }
    
    if (oldVersion < 3) {
      final colunasPedido = await db.rawQuery('PRAGMA table_info(PEDIDO)');
      if (!colunasPedido.any((c) => c['name'] == 'IS_SINCRONIZADO')) {
        await db.execute('ALTER TABLE PEDIDO ADD COLUMN IS_SINCRONIZADO INTEGER DEFAULT 1');
      }
    }
    
    if (oldVersion < 4) {
      final colunasObj = await db.rawQuery('PRAGMA table_info(OBJETIVO_TIMELINE)');
      if (!colunasObj.any((c) => c['name'] == 'ID_UTILIZADOR')) {
        await db.execute('ALTER TABLE OBJETIVO_TIMELINE ADD COLUMN ID_UTILIZADOR INTEGER');
      }
      if (!colunasObj.any((c) => c['name'] == 'TIPO_OBJETIVO')) {
        await db.execute('ALTER TABLE OBJETIVO_TIMELINE ADD COLUMN TIPO_OBJETIVO TEXT DEFAULT "Outro"');
      }
    }
    
    if (oldVersion < 6) {
      final colunasMarco = await db.rawQuery('PRAGMA table_info(MARCO_CONQUISTA)');
      if (!colunasMarco.any((c) => c['name'] == 'TIPO_MARCO')) {
        await db.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN TIPO_MARCO TEXT');
        await db.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_1 INTEGER');
        await db.execute('ALTER TABLE MARCO_CONQUISTA ADD COLUMN PARAMETRO_2 INTEGER');
      }
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS FILA_SINCRONIZACAO_OBJETIVOS (
          ID_FILA INTEGER PRIMARY KEY AUTOINCREMENT,
          TIPO_ACAO TEXT NOT NULL,
          DADOS_JSON TEXT NOT NULL
        )
      ''');
    }
  }

  Future _onCreate(Database db, int version) async {
    // Tabelas de Fila de Sincronização
    await db.execute('''
      CREATE TABLE FILA_SINCRONIZACAO_OBJETIVOS (
        ID_FILA INTEGER PRIMARY KEY AUTOINCREMENT,
        TIPO_ACAO TEXT NOT NULL,
        DADOS_JSON TEXT NOT NULL
      )
    ''');

    //Tabelas sem chaves estrangeiras de outras
    await db.execute('''
      CREATE TABLE OBJETIVO_TIMELINE (
        ID_OBJETIVO INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER,
        TITULO TEXT NOT NULL,
        DESCRICAO TEXT,
        DATA_OBJETIVO TEXT NOT NULL,
        STATUS TEXT NOT NULL,
        DATA_CONCLUSAO TEXT,
        ORIGEM TEXT NOT NULL,
        TIPO_OBJETIVO TEXT DEFAULT "Outro"
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
        REGRA_ATRIBUICAO TEXT,
        URL_IMAGEM_MARCO TEXT NOT NULL,
        TIPO_MARCO TEXT,
        PARAMETRO_1 INTEGER,
        PARAMETRO_2 INTEGER
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
      CREATE TABLE NIVEL (
        ID_NIVEL INTEGER PRIMARY KEY,
        ID_AREA INTEGER NOT NULL,
        NOME_NIVEL TEXT NOT NULL,
        ORDEM_HIERARQUICA INTEGER NOT NULL,
        DESCRICAO_NIVEL TEXT,
        FOREIGN KEY (ID_AREA) REFERENCES AREA (ID_AREA)
      )
    ''');

    await db.execute('''
      CREATE TABLE CONSULTOR (
        ID_CONSULTOR INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_UTILIZADOR INTEGER,
        ID_AREA INTEGER,
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
        VALIDADE_EXPIRACAO TEXT
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
        IS_SINCRONIZADO INTEGER DEFAULT 1,
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

    await db.execute('''
      CREATE TABLE MARCO_CONSULTOR (
        ID_CONSULTOR INTEGER NOT NULL,
        ID_MARCO INTEGER NOT NULL,
        DATA_CONQUISTA TEXT,
        PRIMARY KEY (ID_CONSULTOR, ID_MARCO),
        FOREIGN KEY (ID_CONSULTOR) REFERENCES CONSULTOR (ID_CONSULTOR),
        FOREIGN KEY (ID_MARCO) REFERENCES MARCO_CONQUISTA (ID_MARCO)
      )
    ''');

    //Tabelas com dependências de Nível 3
    await db.execute('''
      CREATE TABLE EVIDENCIA (
        ID_EVIDENCIA INTEGER PRIMARY KEY AUTOINCREMENT,
        ID_PEDIDO INTEGER NOT NULL,
        ID_REQUISITO INTEGER,
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

  // --- MÉTODOS ANALÍTICOS (DASHBOARD) ---
  Future<Map<String, dynamic>> obterDadosDashboard(int idUtilizador) async {
    final db = await database;
    Map<String, dynamic> dados = {
      'pontosTotais': 0,
      'badgesObtidos': 0,
      'totalBadgesSL': 0,
      'posicaoRanking': 0,
      'totalConsultores': 0,
      'aprendizagensAtivas': <Map<String, dynamic>>[],
      'pontosObtidosEstaSemana': 0,
      'meusPontosMedia': 0.0,
      'mediaServiceLine': 0.0,
      'mediaEmpresa': 0.0,
    };

    // 1. Obter ID_CONSULTOR e Pontos Totais
    final resultConsultor = await db.rawQuery(
        'SELECT ID_CONSULTOR, PONTUACAO_TOTAL, ID_AREA FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [idUtilizador]);
    if (resultConsultor.isEmpty) return dados;

    int idConsultor = resultConsultor.first['ID_CONSULTOR'] as int;
    dados['pontosTotais'] = resultConsultor.first['PONTUACAO_TOTAL'] as int;

    // 2. Badges Obtidos (Consultor_Badge)
    final resultBadges = await db.rawQuery(
        'SELECT COUNT(*) as count FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ?',
        [idConsultor]);
    dados['badgesObtidos'] = resultBadges.first['count'] as int;

    // 3. Total de badges normais pertencentes à Service Line do consultor.
    final resultTotalBadges = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM BADGE B
      INNER JOIN NIVEL N ON N.ID_NIVEL = B.ID_NIVEL
      INNER JOIN AREA A ON A.ID_AREA = N.ID_AREA
      WHERE A.ID_SERVICE_LINE = (
        SELECT ID_SERVICE_LINE FROM AREA WHERE ID_AREA = ?
      ) AND B.IS_PREMIUM = 0
    ''', [resultConsultor.first['ID_AREA']]);
    dados['totalBadgesSL'] = resultTotalBadges.first['count'] as int;

    final umaSemanaAtras = DateTime.now().subtract(const Duration(days: 7));
    final pontosSemana = await db.rawQuery('''
      SELECT COALESCE(SUM(PONTOS_OBTIDOS), 0) AS total
      FROM HISTORICO_PONTUACAO
      WHERE ID_UTILIZADOR = ? AND DATA_ATRIBUICAO >= ?
    ''', [
      idUtilizador,
      umaSemanaAtras.toIso8601String()
    ]);
    dados['pontosObtidosEstaSemana'] =
        (pontosSemana.first['total'] as num?)?.toInt() ?? 0;

    // 4. Ranking Global
    final resultConsultoresSL = await db.rawQuery('''
      SELECT C.ID_CONSULTOR, C.PONTUACAO_TOTAL 
      FROM CONSULTOR C
      ORDER BY C.PONTUACAO_TOTAL DESC
    ''');
    
    dados['totalConsultores'] = resultConsultoresSL.length;

    int ranking = 1;
    double somaSL = 0;
    for (var c in resultConsultoresSL) {
      if (c['ID_CONSULTOR'] == idConsultor) {
        dados['posicaoRanking'] = ranking;
      }
      somaSL += (c['PONTUACAO_TOTAL'] as int);
      ranking++;
    }
    
    if (resultConsultoresSL.isNotEmpty) {
      dados['mediaServiceLine'] = somaSL / resultConsultoresSL.length;
    }

    final resultAllConsultores = await db.rawQuery('SELECT PONTUACAO_TOTAL FROM CONSULTOR');
    double somaEmpresa = 0;
    for(var c in resultAllConsultores) {
      somaEmpresa += (c['PONTUACAO_TOTAL'] as int);
    }
    if (resultAllConsultores.isNotEmpty) {
      dados['mediaEmpresa'] = somaEmpresa / resultAllConsultores.length;
    }
    
    dados['meusPontosMedia'] = (dados['pontosTotais'] as int).toDouble();

    // 5. Histórico 6 Meses
    List<Map<String, dynamic>> ultimos6Meses = [];
    final DateTime hoje = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      DateTime mesAlvo = DateTime(hoje.year, hoje.month - i, 1);
      DateTime mesSeguinte = DateTime(hoje.year, hoje.month - i + 1, 1);
      final pResult = await db.rawQuery('''
        SELECT COALESCE(SUM(PONTOS_OBTIDOS), 0) as total
        FROM HISTORICO_PONTUACAO
        WHERE ID_UTILIZADOR = ? 
          AND DATA_ATRIBUICAO >= ? 
          AND DATA_ATRIBUICAO < ?
      ''', [idUtilizador, mesAlvo.toIso8601String(), mesSeguinte.toIso8601String()]);
      
      ultimos6Meses.add({
        'mes': mesAlvo.month,
        'ano': mesAlvo.year,
        'pontos': (pResult.first['total'] as num?)?.toInt() ?? 0
      });
    }
    dados['pontosUltimos6Meses'] = ultimos6Meses;

    // 6. Aprendizagens Ativas (Pedidos "Em Correção" ou Rascunhos)
    // Inicialmente vamos buscar apenas o que está na DB ("Em Correção").
    // Na vista do Dashboard vamos injetar os rascunhos das SharedPreferences que ainda não são Pedidos.
    final resultAprendizagens = await db.rawQuery('''
      SELECT B.NOME_BADGE, COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE, A.NOME_AREA, N.NOME_NIVEL, P.ID_PEDIDO, B.ID_BADGE
      FROM PEDIDO P 
      INNER JOIN BADGE B ON P.ID_BADGE = B.ID_BADGE 
      LEFT JOIN NIVEL N ON N.ID_NIVEL = B.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE P.ID_UTILIZADOR = ? AND P.ESTADO_PEDIDO = 'Em Correção'
    ''', [idUtilizador]);

    List<Map<String, dynamic>> ativas = [];
    for (var row in resultAprendizagens) {
      int idBadge = row['ID_BADGE'] as int;
      int idPedido = row['ID_PEDIDO'] as int;

      final reqTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM REQUISITO WHERE ID_BADGE = ?',
          [idBadge]);
      int totalReq = reqTotalResult.first['count'] as int;

      final reqValidadosResult = await db.rawQuery(
          'SELECT COUNT(DISTINCT ID_REQUISITO) as count FROM EVIDENCIA WHERE ID_PEDIDO = ? AND ID_REQUISITO IS NOT NULL',
          [idPedido]);
      int reqVal = reqValidadosResult.first['count'] as int;

      ativas.add({
        "titulo": row['NOME_BADGE'],
        "sl": row['SERVICE_LINE'],
        "area": row['NOME_AREA'],
        "nivel": row['NOME_NIVEL'],
        "idBadge": idBadge,
        "reqValidados": reqVal,
        "reqTotais": totalReq == 0 ? 1 : totalReq,
        "estado": "Em Correção",
      });
    }

    dados['aprendizagensAtivas'] = ativas;

    return dados;
  }

  // --- MÉTODOS DE CATÁLOGO ---
  Future<Map<String, dynamic>> obterCatalogo(int idUtilizador) async {
    final db = await database;
    Map<String, dynamic> dadosCatalogo = {
      'recomendados': <Map<String, dynamic>>[],
      'todos': <Map<String, dynamic>>[]
    };

    // Obter ID_CONSULTOR
    final resultConsultor = await db.rawQuery(
        'SELECT ID_CONSULTOR, ID_AREA FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [idUtilizador]);

    int idConsultor = -1;
    if (resultConsultor.isNotEmpty) {
      idConsultor = resultConsultor.first['ID_CONSULTOR'] as int;
    }

    // 1. Obter Todos os Badges (Catálogo completo)
    final resultTodos = await db.rawQuery('''
      SELECT B.ID_BADGE, B.NOME_BADGE, B.PONTOS_BADGE, B.URL_IMAGEM,
             N.NOME_NIVEL, N.ORDEM_HIERARQUICA, A.NOME_AREA,
             COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE,
             (SELECT COUNT(*) FROM REQUISITO R WHERE R.ID_BADGE = B.ID_BADGE) AS NUM_REQ,
             (SELECT COUNT(*) FROM CONSULTOR_BADGE CB WHERE CB.ID_BADGE = B.ID_BADGE AND CB.ID_CONSULTOR = ?) AS OBTIDO
      FROM BADGE B 
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE B.IS_PREMIUM = 0
    ''', [idConsultor]);

    String letraNivel(int? ordem) {
      if (ordem == null || ordem < 1) return 'A';
      return String.fromCharCode(64 + ordem);
    }

    List<Map<String, dynamic>> todosBadges = [];
    for (var b in resultTodos) {
      todosBadges.add({
        "id": b['ID_BADGE'],
        "titulo": b['NOME_BADGE'],
        "sl": b['SERVICE_LINE'],
        "area": b['NOME_AREA'],
        "nivel": letraNivel(b['ORDEM_HIERARQUICA'] as int?),
        "pontos": b['PONTOS_BADGE'],
        "urlImagem": b['URL_IMAGEM'],
        "numeroRequisitos": b['NUM_REQ'] ?? 0,
        "obtido": (b['OBTIDO'] as int? ?? 0) > 0
      });
    }
    dadosCatalogo['todos'] = todosBadges;

    // 2. Obter Badges Recomendados (Ainda não obtidos, ordenados por pontos)
    if (idConsultor != -1) {
      final resultRecomendados = await db.rawQuery('''
        SELECT B.ID_BADGE, B.NOME_BADGE, B.PONTOS_BADGE, B.URL_IMAGEM,
               N.NOME_NIVEL, N.ORDEM_HIERARQUICA, A.NOME_AREA,
               COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE,
               (SELECT COUNT(*) FROM REQUISITO R WHERE R.ID_BADGE = B.ID_BADGE) AS NUM_REQ
        FROM BADGE B 
        INNER JOIN NIVEL N ON N.ID_NIVEL = B.ID_NIVEL
        INNER JOIN AREA A ON A.ID_AREA = N.ID_AREA
        LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
        WHERE B.ID_BADGE NOT IN (SELECT ID_BADGE FROM CONSULTOR_BADGE WHERE ID_CONSULTOR = ?)
          AND A.ID_SERVICE_LINE = (SELECT ID_SERVICE_LINE FROM AREA WHERE ID_AREA = ?)
          AND B.IS_PREMIUM = 0
        ORDER BY B.PONTOS_BADGE DESC LIMIT 3
      ''', [idConsultor, resultConsultor.first['ID_AREA']]);

      List<Map<String, dynamic>> recomendados = [];
      for (var r in resultRecomendados) {
        recomendados.add({
          "id": r['ID_BADGE'],
          "titulo": r['NOME_BADGE'],
          "sl": r['SERVICE_LINE'],
          "area": r['NOME_AREA'],
          "nivel": letraNivel(r['ORDEM_HIERARQUICA'] as int?),
          "pontos": r['PONTOS_BADGE'],
          "urlImagem": r['URL_IMAGEM'],
          "numeroRequisitos": r['NUM_REQ'] ?? 0
        });
      }
      dadosCatalogo['recomendados'] = recomendados;
    }

    return dadosCatalogo;
  }

  // --- MÉTODOS DE HISTÓRICO DE CANDIDATURAS ---
  Future<List<Map<String, dynamic>>> obterHistoricoCandidaturas(
      int idUtilizador) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT P.ID_PEDIDO, B.NOME_BADGE, B.URL_IMAGEM, P.ESTADO_PEDIDO,
             P.DATA_SUBMISSAO_PEDIDO, P.DATA_ULTIMA_ATUALIZACAO, P.COMENTARIO_CONSULTOR,
             N.NOME_NIVEL, N.ORDEM_HIERARQUICA, A.NOME_AREA,
             COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE
      FROM PEDIDO P
      INNER JOIN BADGE B ON P.ID_BADGE = B.ID_BADGE
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE P.ID_UTILIZADOR = ?
      ORDER BY P.ID_PEDIDO DESC
    ''', [idUtilizador]);

    String letraNivel(int? ordem) {
      if (ordem == null || ordem < 1) return 'A';
      return String.fromCharCode(64 + ordem);
    }

    List<Map<String, dynamic>> historico = [];
    for (var r in result) {
      historico.add({
        "id": r['ID_PEDIDO'],
        "titulo": r['NOME_BADGE'],
        "icone": r['URL_IMAGEM'],
        "sl": r['SERVICE_LINE'] ?? 'Sem SL',
        "area": r['NOME_AREA'] ?? 'Sem Área',
        "nivel": letraNivel(r['ORDEM_HIERARQUICA'] as int?),
        "status": r['ESTADO_PEDIDO'],
        "data_submissao": r['DATA_SUBMISSAO_PEDIDO'],
        "data_acao": r['DATA_ULTIMA_ATUALIZACAO'] ?? r['DATA_SUBMISSAO_PEDIDO'],
        "feedback": r['COMENTARIO_CONSULTOR'] ?? '-',
      });
    }
    return historico;
  }

  // --- MÉTODOS PARA OBJETIVOS DA TIMELINE ---
  Future<List<Map<String, dynamic>>> obterObjetivos(int idUtilizador) async {
    final db = await database;
    return await db.query(
      'OBJETIVO_TIMELINE', 
      where: 'ID_UTILIZADOR = ?',
      whereArgs: [idUtilizador],
      orderBy: 'DATA_OBJETIVO ASC'
    );
  }

  Future<int> adicionarObjetivo(Map<String, dynamic> objetivo) async {
    final db = await database;
    return await db.insert('OBJETIVO_TIMELINE', objetivo);
  }

  Future<int> concluirObjetivo(int idObjetivo) async {
    final db = await database;
    final String dataHj = DateTime.now().toIso8601String().split('T')[0];
    return await db.update(
      'OBJETIVO_TIMELINE',
      {'STATUS': 'Concluído', 'DATA_CONCLUSAO': dataHj},
      where: 'ID_OBJETIVO = ?',
      whereArgs: [idObjetivo]
    );
  }

  // --- MÉTODOS FILA DE SINCRONIZAÇÃO DE OBJETIVOS ---
  Future<int> adicionarFilaSincronizacaoObjetivo(String tipoAcao, Map<String, dynamic> dados) async {
    final db = await database;
    return await db.insert('FILA_SINCRONIZACAO_OBJETIVOS', {
      'TIPO_ACAO': tipoAcao,
      'DADOS_JSON': jsonEncode(dados),
    });
  }

  Future<List<Map<String, dynamic>>> obterFilaSincronizacaoObjetivos() async {
    final db = await database;
    return await db.query('FILA_SINCRONIZACAO_OBJETIVOS', orderBy: 'ID_FILA ASC');
  }

  Future<int> limparFilaSincronizacaoObjetivos(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    return await db.delete('FILA_SINCRONIZACAO_OBJETIVOS', where: 'ID_FILA IN (${ids.join(',')})');
  }

  // --- MÉTODOS PARA ESTATÍSTICAS E RANKING ---
  Future<Map<String, dynamic>> obterEstatisticasConsultor(int idUtilizador) async {
    final db = await database;
    
    // Obter dados do consultor
    final consResult = await db.rawQuery('''
      SELECT C.PONTUACAO_TOTAL, 
             (SELECT COUNT(*) FROM CONSULTOR_BADGE CB WHERE CB.ID_CONSULTOR = C.ID_CONSULTOR) as TOTAL_BADGES
      FROM CONSULTOR C WHERE C.ID_UTILIZADOR = ?
    ''', [idUtilizador]);
    
    int meusPontos = 0;
    int meusBadges = 0;
    if (consResult.isNotEmpty) {
      meusPontos = consResult.first['PONTUACAO_TOTAL'] as int;
      meusBadges = consResult.first['TOTAL_BADGES'] as int;
    }

    // Calcular Posição Ranking
    final rankResult = await db.rawQuery('SELECT ID_UTILIZADOR, PONTUACAO_TOTAL FROM CONSULTOR ORDER BY PONTUACAO_TOTAL DESC');
    int myRank = rankResult.indexWhere((r) => r['ID_UTILIZADOR'] == idUtilizador) + 1;
    if (myRank == 0) myRank = 1;
    int totalUsers = rankResult.length > 0 ? rankResult.length : 1;
    
    int percentagemCatalogo = (meusBadges / 30 * 100).clamp(0, 100).toInt();

    // Fallback Mock de Gráficos (Offline)
    List<String> mesesLabels = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun"];
    List<int> dadosLinha = [
      (meusPontos * 0.5).round(), (meusPontos * 0.6).round(), (meusPontos * 0.7).round(),
      (meusPontos * 0.85).round(), (meusPontos * 0.95).round(), meusPontos
    ];
    List<int> normais = [0, 1, 1, 2];
    List<int> especiais = [0, 0, 1, 0];

    // Ranking Mock (Offline Fallback)
    final top5 = rankResult.take(5).map((r) => {
      'pos': rankResult.indexOf(r) + 1,
      'nome': 'Consultor ID ${r['ID_UTILIZADOR']}',
      'pontos': r['PONTUACAO_TOTAL'],
      'badges': 0,
      'serviceLine': 'Offline',
      'area': 'Offline',
      'isMe': r['ID_UTILIZADOR'] == idUtilizador
    }).toList();

    return {
      'kpis': {
        'ranking': myRank,
        'totalConsultores': totalUsers,
        'pontos': meusPontos,
        'crescimentoPontos': "+0",
        'percentagemBadges': percentagemCatalogo,
      },
      'graficoLinha': {
        'labels': mesesLabels,
        'data': dadosLinha
      },
      'graficoBarras': {
        'labels': mesesLabels.sublist(2),
        'normais': normais,
        'especiais': especiais
      },
      'top5': top5,
      'rankingCompleto': rankResult.map((r) => {
        'pos': rankResult.indexOf(r) + 1,
        'nome': 'Consultor ID ${r['ID_UTILIZADOR']}',
        'pontos': r['PONTUACAO_TOTAL'],
        'badges': 0,
        'serviceLine': 'Offline',
        'area': 'Offline',
        'isMe': r['ID_UTILIZADOR'] == idUtilizador
      }).toList()
    };
  }

  Future<List<Map<String, dynamic>>> obterRankingCompleto() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT U.ID_UTILIZADOR, U.NOME_COMPLETO_UTILIZADOR as nome, C.PONTUACAO_TOTAL as pontos,
             COALESCE(SL.NOME_SERVICE_LINE, 'Sem SL') as serviceLine,
             COALESCE(A.NOME_AREA, 'Sem Área') as area,
             (SELECT COUNT(*) FROM CONSULTOR_BADGE CB WHERE CB.ID_CONSULTOR = C.ID_CONSULTOR) as badges
      FROM CONSULTOR C
      JOIN UTILIZADOR U ON C.ID_UTILIZADOR = U.ID_UTILIZADOR
      LEFT JOIN AREA A ON C.ID_AREA = A.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON A.ID_SERVICE_LINE = SL.ID_SERVICE_LINE
      ORDER BY C.PONTUACAO_TOTAL DESC
    ''');
    
    List<Map<String, dynamic>> ranking = [];
    for (int i = 0; i < result.length; i++) {
      var r = Map<String, dynamic>.from(result[i]);
      r['pos'] = i + 1;
      ranking.add(r);
    }
    
    return ranking;
  }

  // --- MÉTODOS MEUS BADGES ---
  Future<List<Map<String, dynamic>>> obterMeusBadges(int idUtilizador) async {
    final db = await database;

    // Obter ID_CONSULTOR
    final resultConsultor = await db.rawQuery(
        'SELECT ID_CONSULTOR FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [idUtilizador]);

    if (resultConsultor.isEmpty) return [];
    int idConsultor = resultConsultor.first['ID_CONSULTOR'] as int;

    final result = await db.rawQuery('''
      SELECT B.ID_BADGE, B.NOME_BADGE, B.PONTOS_BADGE, B.URL_IMAGEM, B.TEMPO_EXPIRACAO_BADGE, B.IS_PREMIUM, B.VALIDADE_MESES,
             CB.DATA_ATRIBUICAO_BADGE, CB.LINK_UNICO_BADGE, CB.DATA_EXPIRACAO,
             N.NOME_NIVEL, N.ORDEM_HIERARQUICA, A.NOME_AREA,
             COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE,
             (SELECT COUNT(*) FROM REQUISITO R WHERE R.ID_BADGE = B.ID_BADGE) AS NUM_REQ
      FROM CONSULTOR_BADGE CB
      INNER JOIN BADGE B ON CB.ID_BADGE = B.ID_BADGE
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE CB.ID_CONSULTOR = ?
      ORDER BY CB.DATA_ATRIBUICAO_BADGE DESC
    ''', [idConsultor]);

    String letraNivel(int? ordem) {
      if (ordem == null || ordem < 1) return 'A';
      return String.fromCharCode(64 + ordem);
    }

    List<Map<String, dynamic>> meusBadges = [];
    for (var r in result) {
      meusBadges.add({
        "id": r['ID_BADGE'],
        "idConsultor": idConsultor,
        "titulo": r['NOME_BADGE'],
        "sl": r['SERVICE_LINE'],
        "area": r['NOME_AREA'],
        "pontos": r['PONTOS_BADGE'],
        "urlImagem": r['URL_IMAGEM'],
        "nivel": letraNivel(r['ORDEM_HIERARQUICA'] as int?),
        "nomeNivel": r['NOME_NIVEL'] ?? 'A',
        "data": r['DATA_ATRIBUICAO_BADGE'],
        "dataExpiracao": r['DATA_EXPIRACAO'],
        "linkUnico": r['LINK_UNICO_BADGE'],
        "numeroRequisitos": r['NUM_REQ'] ?? 0,
        "isPremium": (r['IS_PREMIUM'] as int) == 1,
        "validadeMeses": r['VALIDADE_MESES'] ?? r['TEMPO_EXPIRACAO_BADGE'] ?? 0,
      });
    }
    return meusBadges;
  }

  // --- MÉTODOS DETALHES DO BADGE ---
  Future<Map<String, dynamic>?> obterBadgeDetalhe(int idBadge, int idUtilizador) async {
    final db = await database;

    // 1. Obter Badge base
    final resultBadge = await db.rawQuery('''
      SELECT B.*, N.NOME_NIVEL, A.NOME_AREA,
             COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE
      FROM BADGE B
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE B.ID_BADGE = ?
    ''', [idBadge]);

    if (resultBadge.isEmpty) return null;
    final row = resultBadge.first;

    Map<String, dynamic> detalhe = {
      "id": row['ID_BADGE'],
      "titulo": row['NOME_BADGE'],
      "sl": row['SERVICE_LINE'],
      "area": row['NOME_AREA'] ?? '',
      "nivel": row['NOME_NIVEL'] ?? 'A',
      "descricao": row['DESCRICAO_BADGE'] ?? '',
      "pontos": row['PONTOS_BADGE'],
      "urlImagem": row['URL_IMAGEM'],
      "isPremium": (row['IS_PREMIUM'] as int) == 1,
      "validadeMeses": row['VALIDADE_MESES'],
      "dataObtencao": null,
      "linkUnico": null,
      "requisitosTotal": 0,
      "requisitos": [],
      "obtido": false,
    };

    // 2. Verificar se o Consultor tem o badge
    final resultConsultor = await db.rawQuery(
        'SELECT ID_CONSULTOR FROM CONSULTOR WHERE ID_UTILIZADOR = ?',
        [idUtilizador]);
    
    if (resultConsultor.isNotEmpty) {
      int idConsultor = resultConsultor.first['ID_CONSULTOR'] as int;
      final resultObtido = await db.rawQuery('''
        SELECT DATA_ATRIBUICAO_BADGE, LINK_UNICO_BADGE, DATA_EXPIRACAO 
        FROM CONSULTOR_BADGE 
        WHERE ID_CONSULTOR = ? AND ID_BADGE = ?
      ''', [idConsultor, idBadge]);

      if (resultObtido.isNotEmpty) {
        detalhe['obtido'] = true;
        detalhe['dataObtencao'] = resultObtido.first['DATA_ATRIBUICAO_BADGE'];
        detalhe['linkUnico'] = resultObtido.first['LINK_UNICO_BADGE'];
        detalhe['dataExpiracao'] = resultObtido.first['DATA_EXPIRACAO'];
      }
    }

    final resultPedido = await db.rawQuery('''
      SELECT ESTADO_PEDIDO FROM PEDIDO 
      WHERE ID_UTILIZADOR = ? AND ID_BADGE = ? 
      ORDER BY DATA_SUBMISSAO_PEDIDO DESC LIMIT 1
    ''', [idUtilizador, idBadge]);
    
    if (resultPedido.isNotEmpty) {
      detalhe['estadoPedido'] = resultPedido.first['ESTADO_PEDIDO'];
    }

    // 3. Requisitos
    final resultReq = await db.rawQuery('''
      SELECT ID_REQUISITO, TITULO_REQUISITO, DESCRICAO_REQUISITO 
      FROM REQUISITO 
      WHERE ID_BADGE = ?
      ORDER BY ORDEM_REQUISITO ASC
    ''', [idBadge]);

    detalhe['requisitosTotal'] = resultReq.length;
    List<Map<String, dynamic>> reqs = [];
    for (var req in resultReq) {
      reqs.add({
        "id": req['ID_REQUISITO'],
        "titulo": req['TITULO_REQUISITO'],
        "desc": req['DESCRICAO_REQUISITO'],
        "concluido": detalhe['obtido'], // Simplificação: se tem o badge, estão concluídos
      });
    }
    detalhe['requisitos'] = reqs;

    return detalhe;
  }

  // Obter evidencias submetidas pelo utilizador para aquele Badge (Aprovado)
  Future<List<Map<String, dynamic>>> obterEvidenciasDePedidoAprovado(int idBadge, int idUtilizador) async {
    final db = await database;
    
    // Obter o pedido aprovado para aquele badge e utilizador
    final resultPedido = await db.rawQuery('''
      SELECT ID_PEDIDO FROM PEDIDO 
      WHERE ID_BADGE = ? AND ID_UTILIZADOR = ? AND ESTADO_PEDIDO = 'Aprovado' 
      ORDER BY DATA_ULTIMA_ATUALIZACAO DESC LIMIT 1
    ''', [idBadge, idUtilizador]);

    if (resultPedido.isEmpty) return [];

    int idPedido = resultPedido.first['ID_PEDIDO'] as int;

    // Obter as evidencias
    final resultEvidencias = await db.query('EVIDENCIA', where: 'ID_PEDIDO = ?', whereArgs: [idPedido]);
    return resultEvidencias;
  }

  // --- MÉTODOS PARA CANDIDATURAS OFFLINE ---
  Future<int> inserirPedidoOffline(Map<String, dynamic> pedido) async {
    final db = await database;
    return await db.insert(
      'PEDIDO',
      pedido,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> inserirEvidenciaOffline(Map<String, dynamic> evidencia) async {
    final db = await database;
    return await db.insert(
      'EVIDENCIA',
      evidencia,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- MÉTODOS DE PERFIL E NOTIFICAÇÕES ---
  Future<Map<String, dynamic>> obterPerfil(int idUtilizador) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT U.NOME_COMPLETO_UTILIZADOR as nome, U.EMAIL_UTILIZADOR as email, C.PONTUACAO_TOTAL as pontos, 
             A.NOME_AREA as area, SL.NOME_SERVICE_LINE as serviceLine
      FROM UTILIZADOR U
      LEFT JOIN CONSULTOR C ON U.ID_UTILIZADOR = C.ID_UTILIZADOR
      LEFT JOIN AREA A ON C.ID_AREA = A.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON A.ID_SERVICE_LINE = SL.ID_SERVICE_LINE
      WHERE U.ID_UTILIZADOR = ?
    ''', [idUtilizador]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> obterNotificacoes(int idUtilizador) async {
    final db = await database;
    return await db.query(
      'NOTIFICACAO',
      orderBy: 'DATA_ENVIO_NOTIFICACAO DESC'
    );
  }

  // --- MÉTODOS DE GAMIFICAÇÃO ---
  Future<List<Map<String, dynamic>>> obterTimeline() async {
    final db = await database;
    return await db.query('OBJETIVO_TIMELINE', orderBy: 'DATA_OBJETIVO DESC');
  }

  Future<List<Map<String, dynamic>>> obterConquistasEspeciais(int idUtilizador) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT MC.ID_MARCO, MC.TITULO_MARCO, MC.DESCRICAO_MARCO, MC.PONTOS_EXTRA, MC.URL_IMAGEM_MARCO, MC.REGRA_ATRIBUICAO, C.DATA_CONQUISTA
      FROM MARCO_CONQUISTA MC
      INNER JOIN MARCO_CONSULTOR C ON MC.ID_MARCO = C.ID_MARCO
      INNER JOIN CONSULTOR CO ON C.ID_CONSULTOR = CO.ID_CONSULTOR
      WHERE CO.ID_UTILIZADOR = ?
    ''', [idUtilizador]);
  }

  Future<List<Map<String, dynamic>>> obterHistoricoPontos(int idUtilizador) async {
    final db = await database;
    return await db.query(
      'HISTORICO_PONTUACAO',
      where: 'ID_UTILIZADOR = ?',
      whereArgs: [idUtilizador],
      orderBy: 'DATA_ATRIBUICAO DESC'
    );
  }

  // --- MÉTODOS DE PEDIDO ---
  Future<Map<String, dynamic>?> obterPedidoDetalhe(int idPedido) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT P.ID_PEDIDO, P.ESTADO_PEDIDO, P.DATA_ULTIMA_ATUALIZACAO, P.DATA_SUBMISSAO_PEDIDO, P.COMENTARIO_CONSULTOR, P.IS_SINCRONIZADO,
             B.NOME_BADGE, B.URL_IMAGEM, B.IS_PREMIUM, B.PONTOS_BADGE, B.VALIDADE_MESES,
             N.NOME_NIVEL, A.NOME_AREA, COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE,
             (SELECT COUNT(*) FROM REQUISITO R WHERE R.ID_BADGE = B.ID_BADGE) AS NUM_REQ
      FROM PEDIDO P
      INNER JOIN BADGE B ON P.ID_BADGE = B.ID_BADGE
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE P.ID_PEDIDO = ?
    ''', [idPedido]);

    if (result.isEmpty) return null;

    Map<String, dynamic> pedido = Map.from(result.first);

    // Evidencias
    final evidencias = await db.rawQuery('''
      SELECT E.*, R.TITULO_REQUISITO 
      FROM EVIDENCIA E 
      LEFT JOIN REQUISITO R ON E.ID_REQUISITO = R.ID_REQUISITO 
      WHERE E.ID_PEDIDO = ?
    ''', [idPedido]);
    pedido['evidencias'] = evidencias;

    return pedido;
  }

  Future<Map<String, dynamic>?> obterUltimoPedidoCandidatura(int idUtilizador) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT P.ID_PEDIDO, B.NOME_BADGE, B.URL_IMAGEM, B.PONTOS_BADGE, P.ESTADO_PEDIDO,
             N.NOME_NIVEL, A.NOME_AREA, COALESCE(SL.NOME_SERVICE_LINE, B.CATEGORIA_BADGE) AS SERVICE_LINE
      FROM PEDIDO P
      INNER JOIN BADGE B ON P.ID_BADGE = B.ID_BADGE
      LEFT JOIN NIVEL N ON B.ID_NIVEL = N.ID_NIVEL
      LEFT JOIN AREA A ON A.ID_AREA = N.ID_AREA
      LEFT JOIN SERVICE_LINE SL ON SL.ID_SERVICE_LINE = A.ID_SERVICE_LINE
      WHERE P.ID_UTILIZADOR = ? AND P.ESTADO_PEDIDO NOT IN ('Rascunho', 'Em Correção')
      ORDER BY P.DATA_SUBMISSAO_PEDIDO DESC LIMIT 1
    ''', [idUtilizador]);

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<Map<String, dynamic>>> obterMarcosDisponiveis(int idUtilizador) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT MC.*
      FROM MARCO_CONQUISTA MC
      WHERE MC.ID_MARCO NOT IN (
        SELECT C.ID_MARCO 
        FROM MARCO_CONSULTOR C 
        INNER JOIN CONSULTOR CO ON C.ID_CONSULTOR = CO.ID_CONSULTOR 
        WHERE CO.ID_UTILIZADOR = ?
      )
    ''', [idUtilizador]);
  }
}
