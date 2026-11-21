import 'package:material_ui/material_ui.dart';

import '../models/game_mode.dart';
import '../models/theme_category.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/confetti.dart';
import '../widgets/foto_item.dart';
import '../widgets/glow_button.dart';
import '../widgets/lance_background.dart';
import '../widgets/lance_card.dart';
import '../widgets/lance_icon.dart';
import '../widgets/lance_top_bar.dart';
import '../widgets/pressable.dart';

/// Etapas do modo Impostor.
enum _Fase { config, passar, ver, votacao, resultado }

/// Modo Impostor: o celular passa de mao em mao. Todos veem o mesmo item
/// (ex.: Ronaldinho), menos um, que ve "IMPOSTOR". O grupo conversa, vota e
/// o app mostra se o impostor ganhou ou perdeu.
class ImpostorScreen extends StatefulWidget {
  final ThemeCategory tema;
  const ImpostorScreen({super.key, required this.tema});

  @override
  State<ImpostorScreen> createState() => _ImpostorScreenState();
}

class _ImpostorScreenState extends State<ImpostorScreen> {
  _Fase _fase = _Fase.config;
  int _jogadores = 4;
  late RodadaImpostor _rodada;

  /// Jogador que esta com o celular agora.
  int _vez = 0;

  /// Jogador mais votado pelo grupo.
  int? _votado;

  String _nome(int i) => 'Jogador ${i + 1}';

  void _comecar() {
    setState(() {
      _rodada = RodadaImpostor.sortear(widget.tema, _jogadores);
      _vez = 0;
      _votado = null;
      _fase = _Fase.passar;
    });
  }

  void _ver() => setState(() => _fase = _Fase.ver);

  void _esconderEPassar() {
    setState(() {
      if (_vez + 1 < _jogadores) {
        _vez++;
        _fase = _Fase.passar;
      } else {
        _fase = _Fase.votacao;
      }
    });
  }

  void _votar(int i) {
    setState(() {
      _votado = i;
      _fase = _Fase.resultado;
    });
    FeedbackService.instancia.vibrarForte();
    FeedbackService.instancia.tocar(_rodada.impostorGanhou(i) ? Som.martelo : Som.fanfarra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LanceBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const LanceTopBar(titulo: 'Impostor'),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: c),
                      ),
                      child: KeyedSubtree(key: ValueKey('${_fase.name}_$_vez'), child: _conteudo()),
                    ),
                  ),
                ],
              ),
            ),
            if (_fase == _Fase.resultado && !_rodada.impostorGanhou(_votado!))
              const Positioned.fill(child: ConfettiRain()),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() => switch (_fase) {
    _Fase.config => _config(),
    _Fase.passar => _passar(),
    _Fase.ver => _verPalavra(),
    _Fase.votacao => _votacao(),
    _Fase.resultado => _resultado(),
  };

  Widget _centro(List<Widget> filhos) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Column(children: filhos),
  );

  Widget _config() => _centro([
    const Spacer(),
    const LanceIcon(LanceIconType.mascara, tamanho: 84),
    const SizedBox(height: 10),
    Text('Tema: ${widget.tema.nome}', style: AppText.texto(16)),
    const SizedBox(height: 24),
    Text('Quantas pessoas vão jogar?', style: AppText.texto(16, cor: AppColors.branco)),
    const SizedBox(height: 12),
    LanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          BotaoIcone(
            icone: LanceIconType.menos,
            rotulo: 'Menos jogadores',
            onTap: _jogadores > RodadaImpostor.minimo ? () => setState(() => _jogadores--) : null,
          ),
          Expanded(
            child: Text(
              '$_jogadores',
              key: const ValueKey('qtd_impostor'),
              textAlign: TextAlign.center,
              style: AppText.numero(40),
            ),
          ),
          BotaoIcone(
            icone: LanceIconType.mais,
            rotulo: 'Mais jogadores',
            onTap: _jogadores < RodadaImpostor.maximo ? () => setState(() => _jogadores++) : null,
          ),
        ],
      ),
    ),
    const SizedBox(height: 8),
    Text('Um deles será o impostor', style: AppText.texto(13)),
    const Spacer(),
    GlowButton(texto: 'Começar', icone: LanceIconType.play, onTap: _comecar),
  ]);

  Widget _passar() => _centro([
    Text('${_vez + 1} de $_jogadores', style: AppText.texto(14)),
    const Spacer(),
    const LanceIcon(LanceIconType.celular, tamanho: 72),
    const SizedBox(height: 16),
    Text('Passe o celular para', style: AppText.texto(18)),
    const SizedBox(height: 6),
    Text(_nome(_vez).toUpperCase(), style: AppText.titulo(34)),
    const SizedBox(height: 12),
    Text('Só ele pode olhar a tela.', style: AppText.texto(14)),
    const Spacer(),
    GlowButton(texto: 'Ver minha palavra', icone: LanceIconType.play, onTap: _ver),
  ]);

  Widget _verPalavra() {
    final impostor = _rodada.ehImpostor(_vez);
    return _centro([
      Text(_nome(_vez), style: AppText.texto(16)),
      const Spacer(),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (_, v, c) => Transform.scale(scale: 0.6 + 0.4 * v, child: c),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
          decoration: BoxDecoration(
            color: impostor ? AppColors.roxoEscuro : AppColors.superficie,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: impostor ? AppColors.alerta : AppColors.neon, width: 3),
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            children: [
              // Quem nao e impostor ve a foto do item; o impostor ve a mascara.
              if (impostor)
                const LanceIcon(LanceIconType.mascara, tamanho: 70)
              else
                SizedBox(
                  width: 190,
                  height: 190,
                  child: FotoItem(temaId: widget.tema.id, item: _rodada.palavra, icone: widget.tema.icone),
                ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _rodada.revelacaoPara(_vez).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.titulo(34, cor: impostor ? AppColors.brancoPuro : AppColors.branco),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                impostor ? 'Disfarce! Ninguém pode descobrir.' : 'Descubra quem é o impostor.',
                textAlign: TextAlign.center,
                style: AppText.texto(14, cor: impostor ? AppColors.brancoPuro : AppColors.lilas),
              ),
            ],
          ),
        ),
      ),
      const Spacer(),
      GlowButton(
        texto: _vez + 1 < _jogadores ? 'Esconder e passar' : 'Esconder e votar',
        icone: LanceIconType.check,
        onTap: _esconderEPassar,
      ),
    ]);
  }

  Widget _votacao() => _centro([
    const SizedBox(height: 6),
    Text('HORA DE VOTAR', style: AppText.titulo(26)),
    const SizedBox(height: 6),
    Text('Conversem e decidam. Em quem o grupo votou?', textAlign: TextAlign.center, style: AppText.texto(15)),
    const SizedBox(height: 18),
    Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: [
          for (var i = 0; i < _jogadores; i++)
            Pressable(
              key: ValueKey('voto_$i'),
              onTap: () => _votar(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.coresJogadores[i % AppColors.coresJogadores.length], width: 2),
                ),
                child: Text(
                  _nome(i),
                  style: AppText.texto(16, cor: AppColors.branco, peso: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    ),
  ]);

  Widget _resultado() {
    final ganhou = _rodada.impostorGanhou(_votado!);
    return _centro([
      const Spacer(),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (_, v, c) => Transform.scale(scale: v, child: c),
        child: Column(
          children: [
            LanceIcon(ganhou ? LanceIconType.mascara : LanceIconType.trofeu, tamanho: 90),
            const SizedBox(height: 12),
            Text('O IMPOSTOR', style: AppText.titulo(28)),
            Text(
              ganhou ? 'GANHOU!' : 'PERDEU!',
              style: AppText.titulo(46, cor: ganhou ? AppColors.alerta : AppColors.roxo),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      LanceCard(
        child: Column(
          children: [
            Text('O impostor era', style: AppText.texto(14)),
            Text(_nome(_rodada.impostor), style: AppText.titulo(22)),
            const SizedBox(height: 10),
            Text('A palavra era', style: AppText.texto(14)),
            Text(_rodada.palavra, textAlign: TextAlign.center, style: AppText.titulo(22)),
            if (ganhou) ...[
              const SizedBox(height: 10),
              Text('Vocês votaram em ${_nome(_votado!)}', style: AppText.texto(13)),
            ],
          ],
        ),
      ),
      const Spacer(),
      GlowButton(texto: 'Jogar de novo', icone: LanceIconType.play, onTap: _comecar),
      const SizedBox(height: 8),
      GlowButton(
        texto: 'Menu',
        estilo: EstiloBotao.secundario,
        altura: 46,
        tamanhoTexto: 15,
        onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    ]);
  }
}
