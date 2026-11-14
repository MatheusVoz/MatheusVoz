import 'package:material_ui/material_ui.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'animated_money.dart';
import 'pressable.dart';

/// Card de jogador na tela do leilao: nome, saldo e quantos itens ja tem.
class PlayerChip extends StatelessWidget {
  final Player jogador;
  final bool selecionado;
  final bool ativo;
  final String? motivoBloqueio;
  final VoidCallback onTap;
  final double altura;

  const PlayerChip({
    super.key,
    required this.jogador,
    required this.selecionado,
    required this.ativo,
    required this.onTap,
    this.motivoBloqueio,
    this.altura = 78,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? jogador.cor : AppColors.desativado;
    final compacto = altura < 80;
    return Semantics(
      button: true,
      selected: selecionado,
      label: '${jogador.nome}, saldo ${jogador.saldo} reais, ${jogador.compras.length} itens',
      child: Pressable(
        onTap: onTap,
        escala: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: altura,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: compacto ? 5 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selecionado
                ? Color.alphaBlend(cor.withValues(alpha: 0.28), AppColors.superficie)
                : (ativo ? AppColors.superficieClara : const Color(0xFFEDE8F5)),
            border: Border.all(
              color: selecionado ? AppColors.neon : cor.withValues(alpha: ativo ? 0.85 : 0.5),
              width: selecionado ? 3 : 2,
            ),
            boxShadow: selecionado
                ? [BoxShadow(color: cor.withValues(alpha: 0.8), blurRadius: 22, spreadRadius: 1)]
                : null,
          ),
          child: Row(
            children: [
              // Barra lateral com a cor do jogador.
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: ativo ? [BoxShadow(color: cor, blurRadius: 8)] : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: compacto ? _infoCompacta(cor) : _infoNormal(cor)),
            ],
          ),
        ),
      ),
    );
  }

  /// Quantidade de itens ja arrematados.
  String get _textoItens {
    final n = jogador.compras.length;
    return n == 1 ? '1 item' : '$n itens';
  }

  Widget _nome(double tamanho) => Text(
    jogador.nome,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.texto(
      tamanho,
      cor: ativo ? AppColors.branco : AppColors.lilas.withValues(alpha: 0.5),
      peso: FontWeight.w700,
    ),
  );

  Widget _dinheiro(double tamanho) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: AnimatedMoney(
      valor: jogador.saldo,
      tamanho: tamanho,
      cor: ativo ? AppColors.branco : AppColors.desativado,
    ),
  );

  Widget _status(double tamanho) => Text(
    motivoBloqueio ?? _textoItens,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.texto(tamanho, cor: ativo ? AppColors.lilas : AppColors.lilas.withValues(alpha: 0.45)),
  );

  /// Tres linhas: nome, saldo grande e itens.
  Widget _infoNormal(Color cor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [_nome(16), _dinheiro(21), _status(13)],
  );

  /// Duas linhas (telas menores ou 6 jogadores): nome inteiro em cima,
  /// saldo e itens embaixo.
  Widget _infoCompacta(Color cor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _nome(14.5),
      const SizedBox(height: 1),
      Row(
        children: [
          Flexible(flex: 3, child: _dinheiro(17)),
          const SizedBox(width: 6),
          Flexible(
            flex: 2,
            child: Text(
              motivoBloqueio == null ? _textoItens : 'sem R\$',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.texto(
                12,
                cor: ativo ? AppColors.lilas : AppColors.lilas.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
