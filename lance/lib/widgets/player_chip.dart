import 'package:material_ui/material_ui.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'animated_money.dart';
import 'pressable.dart';

/// Card de jogador na tela do leilao: nome, saldo e vagas restantes.
class PlayerChip extends StatelessWidget {
  final Player jogador;
  final int vagasRestantes;
  final int tamanhoLista;
  final bool selecionado;
  final bool ativo;
  final String? motivoBloqueio;
  final VoidCallback onTap;
  final double altura;

  const PlayerChip({
    super.key,
    required this.jogador,
    required this.vagasRestantes,
    required this.tamanhoLista,
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
      label: '${jogador.nome}, saldo ${jogador.saldo} reais, $vagasRestantes vagas',
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
                : (ativo ? AppColors.superficieClara : const Color(0xFF16131C)),
            border: Border.all(
              color: selecionado ? AppColors.branco : cor.withValues(alpha: ativo ? 0.85 : 0.5),
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
              // Bolinhas das vagas (cheias = arrematadas).
              _Vagas(
                total: tamanhoLista,
                ocupadas: tamanhoLista - vagasRestantes,
                cor: cor,
                compacto: compacto,
              ),
            ],
          ),
        ),
      ),
    );
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
    motivoBloqueio ?? 'Vagas $vagasRestantes/$tamanhoLista',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.texto(tamanho, cor: ativo ? AppColors.lilas : AppColors.lilas.withValues(alpha: 0.45)),
  );

  /// Tres linhas: nome, saldo grande e vagas.
  Widget _infoNormal(Color cor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [_nome(16), _dinheiro(21), _status(13)],
  );

  /// Duas linhas (telas menores ou 6 jogadores): nome inteiro em cima,
  /// saldo e vagas embaixo.
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
              motivoBloqueio == null ? '$vagasRestantes/$tamanhoLista' : motivoBloqueio!.split(' ').last,
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

class _Vagas extends StatelessWidget {
  final int total, ocupadas;
  final Color cor;
  final bool compacto;
  const _Vagas({required this.total, required this.ocupadas, required this.cor, required this.compacto});

  @override
  Widget build(BuildContext context) {
    final d = compacto ? 7.0 : 8.0;
    final porColuna = (total / 2).ceil();
    Widget bolinha(int i) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: d,
      height: d,
      margin: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: i < ocupadas ? cor : Colors.transparent,
        border: Border.all(color: cor.withValues(alpha: 0.8), width: 1.4),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < 2; c++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = c * porColuna; i < (c + 1) * porColuna && i < total; i++) bolinha(i)],
          ),
      ],
    );
  }
}
