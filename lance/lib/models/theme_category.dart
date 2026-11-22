import '../widgets/lance_icon.dart';

/// Um tema de leilao (ex.: Bebidas) com sua lista de itens.
class ThemeCategory {
  /// Identificador estavel (usado para salvar a partida).
  final String id;

  /// Nome exibido.
  final String nome;

  /// Frase curta exibida no card do tema.
  final String descricao;

  /// Icone desenhado do tema.
  final LanceIconType icone;

  /// Itens disponiveis para o leilao.
  final List<String> itens;

  const ThemeCategory({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.itens,
  });

  /// Id reservado para o tema digitado pelo usuario.
  static const idPersonalizado = 'personalizado';

  bool get personalizado => id == idPersonalizado;

  /// Cria o tema personalizado a partir dos itens digitados.
  factory ThemeCategory.personalizado(List<String> itens, {String nome = 'Personalizado'}) => ThemeCategory(
    id: idPersonalizado,
    nome: nome,
    descricao: 'Seus próprios itens',
    icone: LanceIconType.lapis,
    itens: itens,
  );
}
