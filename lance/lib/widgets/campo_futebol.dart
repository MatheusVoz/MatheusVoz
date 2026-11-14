import 'package:material_ui/material_ui.dart';

import '../models/posicao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'foto_item.dart';
import 'lance_icon.dart';
import 'pressable.dart';

/// Campinho de futebol (como no jogo da maleta): gramado em perspectiva com
/// 5 posicoes. Posicao vazia = bolinha roxa; preenchida = foto + nome.
/// As posicoes em [selecionaveis] pulsam em amarelo e podem ser tocadas.
class CampoFutebol extends StatelessWidget {
  /// Jogador escalado em cada posicao (ausente = vazia).
  final Map<Posicao, String> escalacao;
  final Set<Posicao> selecionaveis;
  final ValueChanged<Posicao>? onEscolher;
  final String? titulo;
  final Color cor;

  /// Mostra os nomes embaixo das fotos (desligue em campos muito pequenos).
  final bool mostrarNomes;

  const CampoFutebol({
    super.key,
    required this.escalacao,
    this.selecionaveis = const {},
    this.onEscolher,
    this.titulo,
    this.cor = AppColors.roxo,
    this.mostrarNomes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (titulo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    titulo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.texto(13, cor: AppColors.branco, peso: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        AspectRatio(
          aspectRatio: 1.0,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final bola = w * 0.21;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _Gramado())),
                  for (final pos in Posicao.values)
                    Positioned(
                      left: pos.x * w - bola / 2,
                      top: pos.y * h - bola / 2,
                      width: bola,
                      height: bola,
                      child: _Bolinha(
                        key: ValueKey('pos_${pos.name}'),
                        posicao: pos,
                        item: escalacao[pos],
                        selecionavel: selecionaveis.contains(pos),
                        mostrarNome: mostrarNomes,
                        onTap: onEscolher == null || !selecionaveis.contains(pos)
                            ? null
                            : () => onEscolher!(pos),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Bolinha extends StatelessWidget {
  final Posicao posicao;
  final String? item;
  final bool selecionavel;
  final bool mostrarNome;
  final VoidCallback? onTap;

  const _Bolinha({
    super.key,
    required this.posicao,
    required this.item,
    required this.selecionavel,
    required this.mostrarNome,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final lado = c.maxWidth;
        final circulo = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: item == null
                ? const RadialGradient(
                    center: Alignment(-0.35, -0.4),
                    colors: [Color(0xFFA35BFF), Color(0xFF7B2FF7), Color(0xFF4A12A8)],
                  )
                : null,
            border: Border.all(
              color: selecionavel
                  ? AppColors.neon
                  : (item == null ? const Color(0xFF3A0E86) : AppColors.brancoPuro),
              width: selecionavel ? lado * 0.08 : lado * 0.05,
            ),
            boxShadow: [
              BoxShadow(
                color: selecionavel ? AppColors.neon.withValues(alpha: 0.8) : Colors.black26,
                blurRadius: selecionavel ? lado * 0.3 : lado * 0.12,
                offset: selecionavel ? Offset.zero : Offset(0, lado * 0.05),
              ),
            ],
          ),
          child: item == null
              ? Center(
                  child: Text(
                    posicao.sigla,
                    style: AppText.texto(lado * 0.24, cor: AppColors.brancoPuro, peso: FontWeight.w700),
                  ),
                )
              : ClipOval(
                  child: FotoItem(
                    temaId: Posicao.temaFutebol,
                    item: item!,
                    icone: LanceIconType.jogador,
                    raio: 0,
                  ),
                ),
        );
        return Semantics(
          button: selecionavel,
          label: selecionavel ? 'Escalar em ${posicao.nome}' : (item ?? posicao.nome),
          excludeSemantics: true,
          child: Pressable(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Posicoes disponiveis pulsam para chamar a atencao.
                if (selecionavel)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1.08),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOut,
                    builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                    child: circulo,
                  )
                else
                  Positioned.fill(child: circulo),
                if (item != null && mostrarNome)
                  Positioned(
                    bottom: -lado * 0.34,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: lado * 1.9),
                      padding: EdgeInsets.symmetric(horizontal: lado * 0.08, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.roxoEscuro.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.texto(lado * 0.19, cor: AppColors.brancoPuro, peso: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gramado em perspectiva (mais estreito em cima) com faixas e linhas brancas.
class _Gramado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final topo = w * 0.14;
    Offset p(double fx, double fy) {
      // Interpola a largura do topo (estreito) para a base (largo).
      final margem = topo * (1 - fy);
      return Offset(margem + (w - 2 * margem) * fx, h * fy);
    }

    final campo = Path()
      ..moveTo(p(0, 0).dx, 0)
      ..lineTo(p(1, 0).dx, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    // Sombra e borda verde escura (efeito de placa 3D).
    canvas.drawPath(campo.shift(Offset(0, h * 0.025)), Paint()..color = const Color(0xFF2E7D1E));
    canvas.save();
    canvas.clipPath(campo);
    const faixas = 8;
    for (var i = 0; i < faixas; i++) {
      canvas.drawRect(
        Rect.fromLTRB(0, h * i / faixas, w, h * (i + 1) / faixas),
        Paint()..color = i.isEven ? const Color(0xFF5DBB2F) : const Color(0xFF52AC27),
      );
    }
    canvas.restore();

    final linha = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.011;
    final borda = Path()
      ..moveTo(p(0.03, 0.02).dx, h * 0.02)
      ..lineTo(p(0.97, 0.02).dx, h * 0.02)
      ..lineTo(p(0.97, 0.98).dx, h * 0.98)
      ..lineTo(p(0.03, 0.98).dx, h * 0.98)
      ..close();
    canvas.drawPath(borda, linha);
    canvas.drawLine(p(0.03, 0.5), p(0.97, 0.5), linha);
    canvas.drawOval(Rect.fromCenter(center: p(0.5, 0.5), width: w * 0.28, height: h * 0.2), linha);
    // Areas (em cima e embaixo).
    void area(double y0, double y1, double x0, double x1) {
      canvas.drawPath(
        Path()
          ..moveTo(p(x0, y0).dx, h * y0)
          ..lineTo(p(x0, y1).dx, h * y1)
          ..lineTo(p(x1, y1).dx, h * y1)
          ..lineTo(p(x1, y0).dx, h * y0),
        linha,
      );
    }

    area(0.02, 0.17, 0.28, 0.72);
    area(0.02, 0.08, 0.4, 0.6);
    area(0.98, 0.8, 0.25, 0.75);
    area(0.98, 0.9, 0.38, 0.62);
  }

  @override
  bool shouldRepaint(_Gramado old) => false;
}
