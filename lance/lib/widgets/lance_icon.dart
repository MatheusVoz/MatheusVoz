import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Todos os icones do LANCE!, desenhados a mao com CustomPainter.
/// Estilo: traco grosso, cantos arredondados, preenchimento roxo
/// com contorno mais claro.
enum LanceIconType {
  martelo,
  moeda,
  trofeu,
  coroa,
  jogador,
  jogadores,
  cronometro,
  bola,
  hamburguer,
  garrafa,
  celular,
  carro,
  etiqueta,
  claquete,
  pata,
  engrenagem,
  play,
  desfazer,
  pular,
  lapis,
  voltar,
  check,
  mais,
  menos,
  livro,
  som,
  somMudo,
  vibracao,
  arrastar,
  fechar,
  lixeira,
  lista,
  teclado,
}

/// Widget que desenha um icone proprio.
class LanceIcon extends StatelessWidget {
  final LanceIconType tipo;
  final double tamanho;
  final Color preenchimento;
  final Color contorno;

  const LanceIcon(
    this.tipo, {
    super.key,
    this.tamanho = 32,
    this.preenchimento = AppColors.roxo,
    this.contorno = const Color(0xFFE9D6FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(painter: LanceIconPainter(tipo, preenchimento, contorno)),
    );
  }
}

/// Pintor dos icones. Desenha em um espaco de 100x100 que e escalado.
class LanceIconPainter extends CustomPainter {
  final LanceIconType tipo;
  final Color fill;
  final Color stroke;

  LanceIconPainter(this.tipo, this.fill, this.stroke);

  /// Espessura do contorno (no espaco 100x100).
  static const double sw = 6.5;

  late Canvas _c;

  Paint get _fill => Paint()
    ..color = fill
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke([double w = sw]) => Paint()
    ..color = stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Preenche e contorna um caminho.
  void _fs(Path p) {
    _c.drawPath(p, _fill);
    _c.drawPath(p, _stroke());
  }

  /// Linha grossa "contornada": borda clara por fora, roxo por dentro.
  void _linha(Path p, [double largura = 11]) {
    _c.drawPath(p, _stroke(largura + sw * 1.6));
    _c.drawPath(
      p,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = largura
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Detalhe interno no tom do contorno.
  void _detalhe(Path p, [double w = 4.5]) => _c.drawPath(p, _stroke(w));

  Path _rr(double l, double t, double r, double b, double raio) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(raio)));

  Path _circ(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  Path _poli(List<Offset> pts) => Path()..addPolygon(pts, true);

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (tipo) {
      case LanceIconType.martelo:
        _martelo();
      case LanceIconType.moeda:
        _moeda();
      case LanceIconType.trofeu:
        _trofeu();
      case LanceIconType.coroa:
        _coroa();
      case LanceIconType.jogador:
        _jogador(50, 0, 1);
      case LanceIconType.jogadores:
        _jogadores();
      case LanceIconType.cronometro:
        _cronometro();
      case LanceIconType.bola:
        _bola();
      case LanceIconType.hamburguer:
        _hamburguer();
      case LanceIconType.garrafa:
        _garrafa();
      case LanceIconType.celular:
        _celular();
      case LanceIconType.carro:
        _carro();
      case LanceIconType.etiqueta:
        _etiqueta();
      case LanceIconType.claquete:
        _claquete();
      case LanceIconType.pata:
        _pata();
      case LanceIconType.engrenagem:
        _engrenagem();
      case LanceIconType.play:
        _fs(_poli(const [Offset(30, 16), Offset(84, 50), Offset(30, 84)]));
      case LanceIconType.desfazer:
        _desfazer();
      case LanceIconType.pular:
        _pular();
      case LanceIconType.lapis:
        _lapis();
      case LanceIconType.voltar:
        _linha(
          Path()
            ..moveTo(62, 18)
            ..lineTo(32, 50)
            ..lineTo(62, 82),
        );
      case LanceIconType.check:
        _linha(
          Path()
            ..moveTo(18, 52)
            ..lineTo(40, 74)
            ..lineTo(84, 28),
        );
      case LanceIconType.mais:
        _linha(
          Path()
            ..moveTo(50, 18)
            ..lineTo(50, 82)
            ..moveTo(18, 50)
            ..lineTo(82, 50),
        );
      case LanceIconType.menos:
        _linha(
          Path()
            ..moveTo(18, 50)
            ..lineTo(82, 50),
        );
      case LanceIconType.livro:
        _livro();
      case LanceIconType.som:
        _som(true);
      case LanceIconType.somMudo:
        _som(false);
      case LanceIconType.vibracao:
        _vibracao();
      case LanceIconType.arrastar:
        _linha(
          Path()
            ..moveTo(22, 30)
            ..lineTo(78, 30)
            ..moveTo(22, 50)
            ..lineTo(78, 50)
            ..moveTo(22, 70)
            ..lineTo(78, 70),
          7,
        );
      case LanceIconType.fechar:
        _linha(
          Path()
            ..moveTo(24, 24)
            ..lineTo(76, 76)
            ..moveTo(76, 24)
            ..lineTo(24, 76),
        );
      case LanceIconType.lixeira:
        _lixeira();
      case LanceIconType.lista:
        _lista();
      case LanceIconType.teclado:
        _teclado();
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------
  // Desenhos individuais
  // ---------------------------------------------------------------

  void _martelo() {
    // Bloco onde o martelo bate.
    _fs(_rr(50, 76, 92, 90, 6));
    _c.save();
    _c.translate(46, 42);
    _c.rotate(math.pi / 4);
    // Cabo.
    _fs(_rr(-6, -2, 6, 52, 6));
    // Cabeca.
    _fs(_rr(-26, -26, 26, -2, 7));
    // Aneis decorativos da cabeca.
    _detalhe(
      Path()
        ..moveTo(-15, -24)
        ..lineTo(-15, -4)
        ..moveTo(15, -24)
        ..lineTo(15, -4),
    );
    _c.restore();
  }

  void _moeda() {
    _fs(_circ(50, 50, 40));
    _detalhe(_circ(50, 50, 29), 4);
    // Simbolo de cifrao estilizado.
    final s = Path()
      ..moveTo(61, 39)
      ..cubicTo(58, 33, 42, 32, 40, 40)
      ..cubicTo(38, 48, 60, 48, 60, 58)
      ..cubicTo(60, 68, 42, 68, 38, 61);
    _detalhe(s, 6);
    _detalhe(
      Path()
        ..moveTo(50, 27)
        ..lineTo(50, 73),
      5,
    );
  }

  void _trofeu() {
    // Alcas laterais.
    final alcas = Path()
      ..moveTo(28, 26)
      ..cubicTo(8, 26, 10, 52, 32, 52)
      ..moveTo(72, 26)
      ..cubicTo(92, 26, 90, 52, 68, 52);
    _c.drawPath(alcas, _stroke(7));
    // Taca.
    final taca = Path()
      ..moveTo(24, 14)
      ..lineTo(76, 14)
      ..lineTo(74, 34)
      ..cubicTo(72, 52, 62, 62, 50, 62)
      ..cubicTo(38, 62, 28, 52, 26, 34)
      ..close();
    _fs(taca);
    _fs(_rr(43, 60, 57, 74, 3));
    _fs(_rr(26, 74, 74, 88, 6));
    // Brilho interno.
    _detalhe(
      Path()
        ..moveTo(38, 24)
        ..quadraticBezierTo(38, 44, 46, 52),
      4,
    );
  }

  void _coroa() {
    final p = Path()
      ..moveTo(14, 76)
      ..lineTo(10, 32)
      ..lineTo(32, 50)
      ..lineTo(50, 20)
      ..lineTo(68, 50)
      ..lineTo(90, 32)
      ..lineTo(86, 76)
      ..close();
    _fs(p);
    _fs(_rr(14, 76, 86, 88, 5));
    for (final o in const [Offset(10, 30), Offset(50, 17), Offset(90, 30)]) {
      _fs(_circ(o.dx, o.dy, 6.5));
    }
    _fs(_circ(50, 60, 6));
  }

  void _jogador(double cx, double dy, double esc) {
    _c.save();
    _c.translate(cx, dy);
    _c.scale(esc);
    _c.translate(-50, 0);
    _fs(
      Path()..addRRect(
        RRect.fromLTRBAndCorners(
          18,
          58,
          82,
          90,
          topLeft: const Radius.circular(32),
          topRight: const Radius.circular(32),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
      ),
    );
    _fs(_circ(50, 32, 18));
    _c.restore();
  }

  void _jogadores() {
    _jogador(34, 8, 0.72);
    _jogador(66, 8, 0.72);
    _jogador(50, 14, 0.82);
  }

  void _cronometro() {
    _fs(_rr(41, 6, 59, 16, 4));
    _c.drawPath(
      Path()
        ..moveTo(50, 16)
        ..lineTo(50, 22),
      _stroke(7),
    );
    _fs(_circ(50, 58, 34));
    _detalhe(
      Path()
        ..moveTo(50, 58)
        ..lineTo(50, 36)
        ..moveTo(50, 58)
        ..lineTo(64, 66),
      6,
    );
    _c.drawPath(_circ(50, 58, 3), Paint()..color = stroke);
  }

  void _bola() {
    _fs(_circ(50, 50, 40));
    // Pentagono central.
    final pts = <Offset>[];
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      pts.add(Offset(50 + 13 * math.cos(a), 50 + 13 * math.sin(a)));
    }
    final pent = _poli(pts);
    _c.drawPath(pent, Paint()..color = stroke);
    // Costuras ate a borda.
    final costuras = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      costuras
        ..moveTo(50 + 13 * math.cos(a), 50 + 13 * math.sin(a))
        ..lineTo(50 + 38 * math.cos(a), 50 + 38 * math.sin(a));
    }
    _detalhe(costuras, 4.5);
  }

  void _hamburguer() {
    // Pao de cima.
    final topo = Path()
      ..moveTo(12, 46)
      ..cubicTo(12, 10, 88, 10, 88, 46)
      ..close();
    _fs(topo);
    // Gergelim.
    final paintGergelim = Paint()..color = stroke;
    for (final o in const [Offset(36, 30), Offset(52, 24), Offset(66, 32), Offset(46, 38)]) {
      _c.drawOval(Rect.fromCenter(center: o, width: 7, height: 4.5), paintGergelim);
    }
    // Alface ondulada.
    final alface = Path()..moveTo(10, 52);
    for (var x = 10.0; x < 90; x += 10) {
      alface.quadraticBezierTo(x + 5, 62, x + 10, 52);
    }
    _c.drawPath(alface, _stroke(5));
    // Carne.
    _fs(_rr(10, 56, 90, 68, 6));
    // Pao de baixo.
    _fs(_rr(14, 72, 86, 88, 8));
  }

  void _garrafa() {
    _fs(_rr(40, 6, 60, 16, 3));
    final corpo = Path()
      ..moveTo(42, 16)
      ..lineTo(58, 16)
      ..lineTo(58, 30)
      ..cubicTo(58, 36, 72, 38, 72, 50)
      ..lineTo(72, 86)
      ..quadraticBezierTo(72, 92, 66, 92)
      ..lineTo(34, 92)
      ..quadraticBezierTo(28, 92, 28, 86)
      ..lineTo(28, 50)
      ..cubicTo(28, 38, 42, 36, 42, 30)
      ..close();
    _fs(corpo);
    // Rotulo.
    _detalhe(_rr(34, 56, 66, 76, 4), 4.5);
  }

  void _celular() {
    _fs(_rr(26, 6, 74, 94, 11));
    _detalhe(_rr(33, 17, 67, 78, 4), 3.5);
    _c.drawPath(_circ(50, 86, 3.5), Paint()..color = stroke);
  }

  void _carro() {
    final cabine = Path()
      ..moveTo(24, 48)
      ..lineTo(34, 24)
      ..quadraticBezierTo(36, 20, 40, 20)
      ..lineTo(62, 20)
      ..quadraticBezierTo(66, 20, 68, 24)
      ..lineTo(80, 48)
      ..close();
    _fs(cabine);
    _detalhe(
      Path()
        ..moveTo(52, 24)
        ..lineTo(52, 46),
      4,
    );
    _fs(_rr(6, 46, 94, 72, 11));
    _fs(_circ(28, 74, 11));
    _fs(_circ(72, 74, 11));
    _c.drawPath(_circ(28, 74, 3.5), Paint()..color = stroke);
    _c.drawPath(_circ(72, 74, 3.5), Paint()..color = stroke);
  }

  void _etiqueta() {
    final p = Path()
      ..moveTo(52, 10)
      ..lineTo(86, 10)
      ..quadraticBezierTo(90, 10, 90, 14)
      ..lineTo(90, 48)
      ..lineTo(50, 88)
      ..quadraticBezierTo(47, 91, 44, 88)
      ..lineTo(12, 56)
      ..quadraticBezierTo(9, 53, 12, 50)
      ..close();
    _fs(p);
    _detalhe(_circ(72, 28, 7), 5);
  }

  void _claquete() {
    _fs(_rr(10, 40, 90, 90, 8));
    _c.save();
    _c.translate(12, 36);
    _c.rotate(-0.22);
    _fs(_rr(0, -16, 78, 0, 4));
    final listras = Path();
    for (var x = 14.0; x < 76; x += 16) {
      listras
        ..moveTo(x, -14)
        ..lineTo(x - 8, -2);
    }
    _detalhe(listras, 4.5);
    _c.restore();
    _detalhe(
      Path()
        ..moveTo(10, 54)
        ..lineTo(90, 54),
      4.5,
    );
  }

  void _pata() {
    _fs(Path()..addOval(Rect.fromCenter(center: const Offset(50, 68), width: 46, height: 36)));
    for (final o in const [Offset(20, 44), Offset(38, 24), Offset(62, 24), Offset(80, 44)]) {
      _fs(Path()..addOval(Rect.fromCenter(center: o, width: 18, height: 22)));
    }
  }

  void _engrenagem() {
    const dentes = 8;
    final p = Path();
    for (var i = 0; i < dentes * 4; i++) {
      final a = i * 2 * math.pi / (dentes * 4) - math.pi / 2;
      final fase = i % 4;
      final r = (fase == 1 || fase == 2) ? 44.0 : 33.0;
      final pt = Offset(50 + r * math.cos(a), 50 + r * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    p.addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 13));
    p.fillType = PathFillType.evenOdd;
    _fs(p);
  }

  void _desfazer() {
    _linha(
      Path()
        ..moveTo(34, 36)
        ..lineTo(58, 36)
        ..arcToPoint(const Offset(58, 80), radius: const Radius.circular(22))
        ..lineTo(36, 80),
    );
    _fs(_poli(const [Offset(14, 36), Offset(38, 18), Offset(38, 54)]));
  }

  void _pular() {
    _fs(_poli(const [Offset(10, 22), Offset(44, 50), Offset(10, 78)]));
    _fs(_poli(const [Offset(42, 22), Offset(76, 50), Offset(42, 78)]));
    _fs(_rr(80, 22, 90, 78, 4));
  }

  void _lapis() {
    _c.save();
    _c.translate(50, 50);
    _c.rotate(math.pi / 4);
    _fs(_rr(-10, -42, 10, 22, 4));
    _fs(_poli(const [Offset(-10, 22), Offset(10, 22), Offset(0, 42)]));
    _detalhe(
      Path()
        ..moveTo(-10, -28)
        ..lineTo(10, -28),
      4,
    );
    _c.restore();
  }

  void _livro() {
    final esq = Path()
      ..moveTo(48, 28)
      ..quadraticBezierTo(30, 18, 8, 22)
      ..lineTo(8, 80)
      ..quadraticBezierTo(30, 76, 48, 86)
      ..close();
    final dir = Path()
      ..moveTo(52, 28)
      ..quadraticBezierTo(70, 18, 92, 22)
      ..lineTo(92, 80)
      ..quadraticBezierTo(70, 76, 52, 86)
      ..close();
    _fs(esq);
    _fs(dir);
    _detalhe(
      Path()
        ..moveTo(18, 40)
        ..quadraticBezierTo(28, 38, 38, 42)
        ..moveTo(18, 54)
        ..quadraticBezierTo(28, 52, 38, 56)
        ..moveTo(62, 42)
        ..quadraticBezierTo(72, 38, 82, 40)
        ..moveTo(62, 56)
        ..quadraticBezierTo(72, 52, 82, 54),
      3.5,
    );
  }

  void _som(bool ligado) {
    _fs(
      _poli(const [
        Offset(10, 38),
        Offset(28, 38),
        Offset(50, 18),
        Offset(50, 82),
        Offset(28, 62),
        Offset(10, 62),
      ]),
    );
    if (ligado) {
      _c.drawPath(
        Path()
          ..addArc(Rect.fromCircle(center: const Offset(52, 50), radius: 18), -0.9, 1.8)
          ..addArc(Rect.fromCircle(center: const Offset(52, 50), radius: 34), -0.9, 1.8),
        _stroke(7),
      );
    } else {
      _linha(
        Path()
          ..moveTo(64, 36)
          ..lineTo(90, 64)
          ..moveTo(90, 36)
          ..lineTo(64, 64),
        7,
      );
    }
  }

  void _vibracao() {
    _fs(_rr(32, 12, 68, 88, 8));
    _detalhe(_rr(38, 22, 62, 72, 3), 3);
    final ondas = Path()
      ..moveTo(20, 30)
      ..lineTo(12, 40)
      ..lineTo(20, 50)
      ..lineTo(12, 60)
      ..lineTo(20, 70)
      ..moveTo(80, 30)
      ..lineTo(88, 40)
      ..lineTo(80, 50)
      ..lineTo(88, 60)
      ..lineTo(80, 70);
    _c.drawPath(ondas, _stroke(5.5));
  }

  void _lixeira() {
    _fs(_rr(16, 22, 84, 32, 4));
    _fs(_rr(40, 12, 60, 22, 3));
    _fs(
      Path()
        ..moveTo(22, 34)
        ..lineTo(78, 34)
        ..lineTo(72, 90)
        ..lineTo(28, 90)
        ..close(),
    );
    _detalhe(
      Path()
        ..moveTo(40, 46)
        ..lineTo(42, 78)
        ..moveTo(60, 46)
        ..lineTo(58, 78),
      4.5,
    );
  }

  void _lista() {
    _fs(_rr(16, 8, 84, 92, 10));
    final linhas = Path();
    for (final y in const [30.0, 50.0, 70.0]) {
      linhas
        ..moveTo(42, y)
        ..lineTo(72, y);
      _c.drawPath(_circ(30, y, 4), Paint()..color = stroke);
    }
    _detalhe(linhas, 5);
  }

  void _teclado() {
    _fs(_rr(10, 22, 90, 78, 10));
    final p = Paint()..color = stroke;
    for (var l = 0; l < 2; l++) {
      for (var c = 0; c < 4; c++) {
        _c.drawRRect(
          RRect.fromLTRBR(
            20 + c * 17.0,
            32 + l * 14.0,
            30 + c * 17.0,
            40 + l * 14.0,
            const Radius.circular(2),
          ),
          p,
        );
      }
    }
    _c.drawRRect(RRect.fromLTRBR(28, 60, 72, 68, const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(LanceIconPainter old) => old.tipo != tipo || old.fill != fill || old.stroke != stroke;
}
