import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'lance_icon.dart';

/// Estilos de botao disponiveis.
enum EstiloBotao { principal, secundario, fantasma }

/// Botao grande, arredondado, com brilho neon e feedback de escala + brilho ao toque.
class GlowButton extends StatefulWidget {
  final String texto;
  final VoidCallback? onTap;
  final LanceIconType? icone;
  final EstiloBotao estilo;
  final double altura;
  final double tamanhoTexto;
  final bool expandir;

  const GlowButton({
    super.key,
    required this.texto,
    required this.onTap,
    this.icone,
    this.estilo = EstiloBotao.principal,
    this.altura = 52,
    this.tamanhoTexto = 17,
    this.expandir = true,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressionado = false;

  bool get _ativo => widget.onTap != null;

  void _set(bool v) {
    if (!_ativo) return;
    if (_pressionado != v) setState(() => _pressionado = v);
  }

  @override
  Widget build(BuildContext context) {
    final principal = widget.estilo == EstiloBotao.principal;
    final fantasma = widget.estilo == EstiloBotao.fantasma;
    final brilho = _ativo && !fantasma ? (_pressionado ? 34.0 : (principal ? 18.0 : 8.0)) : 0.0;
    final raio = BorderRadius.circular(widget.altura / 2.4);

    final decoracao = BoxDecoration(
      borderRadius: raio,
      gradient: _ativo && principal ? AppColors.gradienteBotao : null,
      color: !_ativo
          ? AppColors.desativado.withValues(alpha: 0.35)
          : principal
          ? null
          : fantasma
          ? Colors.transparent
          : AppColors.superficieClara,
      border: Border.all(
        color: !_ativo
            ? AppColors.desativado
            : principal
            ? AppColors.branco
            : AppColors.roxo.withValues(alpha: fantasma ? 0.5 : 0.9),
        width: 2,
      ),
      boxShadow: brilho > 0 ? [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))] : null,
    );

    final corTexto = _ativo
        ? (principal ? AppColors.textoSobreAmarelo : AppColors.branco)
        : AppColors.lilas.withValues(alpha: 0.45);
    final conteudo = Row(
      mainAxisSize: widget.expandir ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icone != null) ...[
          LanceIcon(
            widget.icone!,
            tamanho: widget.tamanhoTexto * 1.35,
            preenchimento: _ativo ? (principal ? AppColors.roxo : AppColors.neon) : AppColors.desativado,
            contorno: _ativo ? AppColors.roxoEscuro : AppColors.lilas.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.botao(widget.tamanhoTexto, cor: corTexto),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _ativo,
      label: widget.texto,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressionado ? 0.95 : 1,
          duration: Duration(milliseconds: _pressionado ? 80 : 300),
          curve: _pressionado ? Curves.easeOut : Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: widget.altura,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: decoracao,
            child: conteudo,
          ),
        ),
      ),
    );
  }
}
