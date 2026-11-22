import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glow_button.dart';
import 'lance_icon.dart';

/// Dialogo de confirmacao no estilo do app. Retorna true se confirmado.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String sim = 'Sim',
  String nao = 'Cancelar',
  LanceIconType icone = LanceIconType.martelo,
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: AppColors.roxoEscuro.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.roxo, width: 2),
              boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LanceIcon(icone, tamanho: 56),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: AppText.titulo(22).copyWith(shadows: AppText.brilho),
                ),
                const SizedBox(height: 10),
                Text(mensagem, textAlign: TextAlign.center, style: AppText.texto(16)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GlowButton(
                        texto: nao,
                        estilo: EstiloBotao.secundario,
                        altura: 52,
                        tamanhoTexto: 17,
                        onTap: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowButton(
                        texto: sim,
                        altura: 52,
                        tamanhoTexto: 17,
                        onTap: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
  return r ?? false;
}

/// Aviso rapido no topo da tela. Nao bloqueia toques (fica por cima,
/// mas ignora o dedo), entao nunca cobre os botoes do leilao.
OverlayEntry? _avisoAtual;

void avisar(BuildContext context, String texto) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _avisoAtual?.remove();
  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => _Aviso(
      texto: texto,
      aoTerminar: () {
        if (_avisoAtual == entrada) _avisoAtual = null;
        if (entrada.mounted) entrada.remove();
      },
    ),
  );
  _avisoAtual = entrada;
  overlay.insert(entrada);
}

class _Aviso extends StatefulWidget {
  final String texto;
  final VoidCallback aoTerminar;
  const _Aviso({required this.texto, required this.aoTerminar});

  @override
  State<_Aviso> createState() => _AvisoState();
}

class _AvisoState extends State<_Aviso> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.aoTerminar();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 64,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, c) {
            final t = _ctrl.value;
            final entrada = Curves.easeOutBack.transform((t / 0.12).clamp(0.0, 1.0));
            final saida = t > 0.88 ? (1 - t) / 0.12 : 1.0;
            return Opacity(
              opacity: (entrada * saida).clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, -20 * (1 - entrada)), child: c),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.superficieClara,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neon, width: 1.5),
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Text(
                widget.texto,
                textAlign: TextAlign.center,
                style: AppText.texto(15, cor: AppColors.branco),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
