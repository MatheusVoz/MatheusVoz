import 'dart:convert';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/themes_data.dart';
import '../models/game_config.dart';
import '../models/player.dart';
import '../models/theme_category.dart';
import '../theme/app_colors.dart';

/// Etapas da partida (salvas para retomar se o app fechar).
enum FasePartida { leilao, revisao, juiz, podio }

/// Motivo pelo qual o leilao terminou.
enum MotivoFim { listasCompletas, semDinheiro, semItens, ninguemPodeComprar }

/// Uma acao registrada no historico (para o botao Desfazer).
class AcaoLeilao {
  /// Indice do item na fila no momento da acao.
  final int indiceItem;

  /// Jogador que arrematou (null = item pulado).
  final int? jogadorId;
  final int valor;

  const AcaoLeilao({required this.indiceItem, this.jogadorId, this.valor = 0});

  bool get venda => jogadorId != null;

  Map<String, dynamic> toJson() => {'i': indiceItem, 'j': jogadorId, 'v': valor};

  factory AcaoLeilao.fromJson(Map<String, dynamic> j) =>
      AcaoLeilao(indiceItem: j['i'] as int, jogadorId: j['j'] as int?, valor: j['v'] as int);
}

/// Resultado de uma tentativa de venda.
class ResultadoVenda {
  final bool ok;
  final String? erro;
  const ResultadoVenda.sucesso() : ok = true, erro = null;
  const ResultadoVenda.falha(this.erro) : ok = false;
}

/// Controla toda a regra do leilao.
class GameController extends ChangeNotifier {
  static const _chaveSalvamento = 'partida_atual_v1';

  /// Regra do R$1 por vaga (sincronizada com as configuracoes).
  bool regraReserva = true;

  /// Desliga a gravacao em disco (usado em testes de regra puros).
  bool persistir = true;

  GameConfig? _config;
  List<String> _itens = [];
  int _indice = 0;
  List<Player> _jogadores = [];
  final List<AcaoLeilao> _historico = [];
  FasePartida _fase = FasePartida.leilao;
  List<int> _ranking = [];

  GameConfig? get config => _config;
  List<String> get itens => List.unmodifiable(_itens);
  int get indiceAtual => _indice;
  List<Player> get jogadores => List.unmodifiable(_jogadores);
  FasePartida get fase => _fase;
  List<int> get ranking => List.unmodifiable(_ranking);
  bool get temPartida => _config != null;
  bool get podeDesfazer => _historico.isNotEmpty;
  AcaoLeilao? get ultimaAcao => _historico.isEmpty ? null : _historico.last;

  /// Item em leilao agora (null se acabou).
  String? get itemAtual => _indice < _itens.length ? _itens[_indice] : null;

  int get totalItens => _itens.length;

  /// Tema da partida atual.
  ThemeCategory get tema {
    final c = _config!;
    if (c.temaId == ThemeCategory.idPersonalizado) {
      return ThemeCategory.personalizado(c.itensPersonalizados, nome: c.temaNome);
    }
    return temaPorId(c.temaId) ?? ThemeCategory.personalizado(_itens, nome: c.temaNome);
  }

  Player jogador(int id) => _jogadores.firstWhere((j) => j.id == id);

  // -------------------------------------------------------------
  // Regras
  // -------------------------------------------------------------

  /// Vagas que ainda faltam na lista do jogador.
  int vagasRestantes(Player p) => _config!.tamanhoLista - p.compras.length;

  /// Maior lance permitido para o jogador agora.
  /// Com a regra de reserva, ele precisa manter R$1 para cada vaga
  /// que ainda faltara preencher depois deste item.
  int lanceMaximo(Player p) {
    final vagas = vagasRestantes(p);
    if (vagas <= 0) return 0;
    final reserva = regraReserva ? vagas - 1 : 0;
    return max(0, p.saldo - reserva);
  }

  /// Jogador pode arrematar o item atual?
  bool podeArrematar(Player p) => vagasRestantes(p) > 0 && lanceMaximo(p) >= 1;

  /// Texto curto explicando por que o jogador esta desativado.
  String? motivoBloqueio(Player p) {
    if (vagasRestantes(p) <= 0) return 'Lista completa';
    if (p.saldo <= 0) return 'Sem dinheiro';
    if (lanceMaximo(p) < 1) return 'Sem saldo livre';
    return null;
  }

  /// O leilao ja terminou?
  bool get leilaoEncerrado => motivoFim != null;

  /// Motivo do fim (null = leilao continua).
  MotivoFim? get motivoFim {
    if (_config == null) return null;
    final completos = _jogadores.every((p) => vagasRestantes(p) <= 0);
    if (completos) return MotivoFim.listasCompletas;
    final ativos = _jogadores.where((p) => vagasRestantes(p) > 0);
    if (ativos.every((p) => p.saldo <= 0)) return MotivoFim.semDinheiro;
    if (_indice >= _itens.length) return MotivoFim.semItens;
    if (!_jogadores.any(podeArrematar)) return MotivoFim.ninguemPodeComprar;
    return null;
  }

  String get textoMotivoFim => switch (motivoFim) {
    MotivoFim.listasCompletas => 'Todas as listas foram fechadas',
    MotivoFim.semDinheiro => 'Todos ficaram sem dinheiro',
    MotivoFim.semItens => 'Acabaram os itens',
    MotivoFim.ninguemPodeComprar => 'Ninguém pode mais arrematar',
    null => '',
  };

  // -------------------------------------------------------------
  // Ciclo da partida
  // -------------------------------------------------------------

  /// Comeca uma nova partida com a configuracao e o tema escolhidos.
  void iniciar(GameConfig config, ThemeCategory tema, {Random? random}) {
    final rnd = random ?? Random();
    final pool = tema.itens.toSet().toList()..shuffle(rnd);
    final qtd = min(config.quantidadeItens, pool.length);
    _config = config;
    _itens = pool.take(qtd).toList();
    _indice = 0;
    _historico.clear();
    _ranking = [];
    _fase = FasePartida.leilao;
    _jogadores = [
      for (var i = 0; i < config.jogadores.length; i++)
        Player(
          id: i,
          nome: config.jogadores[i].nome,
          cor: AppColors.coresJogadores[config.jogadores[i].corIndice % AppColors.coresJogadores.length],
          saldo: config.dinheiroInicial,
        ),
    ];
    _mudou();
  }

  /// Reinicia com as mesmas configuracoes (itens sorteados de novo).
  void jogarNovamente({Random? random}) {
    if (_config == null) return;
    iniciar(_config!, tema, random: random);
  }

  /// Registra a venda do item atual.
  ResultadoVenda vender(int jogadorId, int valor) {
    if (itemAtual == null || leilaoEncerrado) {
      return const ResultadoVenda.falha('O leilão já terminou.');
    }
    final p = jogador(jogadorId);
    if (vagasRestantes(p) <= 0) {
      return ResultadoVenda.falha('${p.nome} já completou a lista.');
    }
    if (valor < 1) return const ResultadoVenda.falha('O lance mínimo é R\$1.');
    if (valor > p.saldo) {
      return ResultadoVenda.falha('${p.nome} só tem R\$${p.saldo}.');
    }
    final maximo = lanceMaximo(p);
    if (valor > maximo) {
      return ResultadoVenda.falha('${p.nome} precisa guardar R\$1 por vaga. Lance máximo: R\$$maximo.');
    }
    p.saldo -= valor;
    p.compras.add(Purchase(item: itemAtual!, preco: valor, indiceItem: _indice));
    _historico.add(AcaoLeilao(indiceItem: _indice, jogadorId: jogadorId, valor: valor));
    _indice++;
    _mudou();
    return const ResultadoVenda.sucesso();
  }

  /// Ninguem quis o item: passa para o proximo.
  void pular() {
    if (itemAtual == null || leilaoEncerrado) return;
    _historico.add(AcaoLeilao(indiceItem: _indice));
    _indice++;
    _mudou();
  }

  /// Desfaz a ultima acao (venda ou pulo) e volta ao item correspondente.
  AcaoLeilao? desfazer() {
    if (_historico.isEmpty) return null;
    final a = _historico.removeLast();
    if (a.venda) {
      final p = jogador(a.jogadorId!);
      final idx = p.compras.lastIndexWhere((c) => c.indiceItem == a.indiceItem);
      if (idx >= 0) {
        p.compras.removeAt(idx);
        p.saldo += a.valor;
      }
    }
    _indice = a.indiceItem;
    _fase = FasePartida.leilao;
    _ranking = [];
    _mudou();
    return a;
  }

  /// Avanca para a tela de revisao.
  void irParaRevisao() {
    _fase = FasePartida.revisao;
    _mudou();
  }

  void irParaJuiz() {
    _fase = FasePartida.juiz;
    if (_ranking.length != _jogadores.length) {
      _ranking = _jogadores.map((j) => j.id).toList();
    }
    _mudou();
  }

  /// Confirma o ranking decidido pelo juiz (ids do 1o ao ultimo).
  void confirmarRanking(List<int> ids) {
    _ranking = List.of(ids);
    _fase = FasePartida.podio;
    _mudou();
  }

  /// Encerra e apaga a partida salva.
  Future<void> encerrarPartida() async {
    _config = null;
    _itens = [];
    _jogadores = [];
    _historico.clear();
    _ranking = [];
    _indice = 0;
    _fase = FasePartida.leilao;
    notifyListeners();
    if (persistir) {
      final p = await SharedPreferences.getInstance();
      await p.remove(_chaveSalvamento);
    }
  }

  // -------------------------------------------------------------
  // Persistencia
  // -------------------------------------------------------------

  void _mudou() {
    notifyListeners();
    if (persistir) _salvar();
  }

  Map<String, dynamic> toJson() => {
    'config': _config?.toJson(),
    'itens': _itens,
    'indice': _indice,
    'jogadores': _jogadores.map((j) => j.toJson()).toList(),
    'historico': _historico.map((a) => a.toJson()).toList(),
    'fase': _fase.name,
    'ranking': _ranking,
  };

  void carregarJson(Map<String, dynamic> j) {
    _config = GameConfig.fromJson(Map<String, dynamic>.from(j['config'] as Map));
    _itens = List<String>.from(j['itens'] as List);
    _indice = j['indice'] as int;
    _jogadores = (j['jogadores'] as List)
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _historico
      ..clear()
      ..addAll((j['historico'] as List).map((e) => AcaoLeilao.fromJson(Map<String, dynamic>.from(e as Map))));
    _fase = FasePartida.values.firstWhere((f) => f.name == j['fase'], orElse: () => FasePartida.leilao);
    _ranking = List<int>.from(j['ranking'] as List);
  }

  Future<void> _salvar() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (_config == null) {
        await p.remove(_chaveSalvamento);
      } else {
        await p.setString(_chaveSalvamento, jsonEncode(toJson()));
      }
    } catch (_) {
      // Se nao conseguir salvar, o jogo continua normalmente.
    }
  }

  /// Restaura a partida salva (retorna true se havia uma partida).
  Future<bool> restaurar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_chaveSalvamento);
      if (s == null) return false;
      carregarJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
