"""Elenco do tema Futebol: so craques conhecidos, com funcao e nota (0-99).

Rode `python3 tool/elenco_futebol.py` para regerar:
  - lib/data/futebol_posicoes.dart (funcao e nota de cada jogador)
  - a lista de itens do Futebol em lib/data/themes_data.dart
A foto de cada um vem de tool/baixar_fotos.py (titulos em ELENCO abaixo).
"""
import os
import re

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')

G, D, M, A = 'goleiro', 'defensor', 'meia', 'atacante'

# nome no app: (funcao, nota, titulo do artigo na Wikipedia em ingles)
ELENCO = {
    # Goleiros
    'Yashin': (G, 96, 'Lev Yashin'),
    'Buffon': (G, 95, 'Gianluigi Buffon'),
    'Neuer': (G, 94, 'Manuel Neuer'),
    'Casillas': (G, 93, 'Iker Casillas'),
    'Gordon Banks': (G, 92, 'Gordon Banks'),
    'Zoff': (G, 92, 'Dino Zoff'),
    'Oliver Kahn': (G, 92, 'Oliver Kahn'),
    'Schmeichel': (G, 91, 'Peter Schmeichel'),
    'Van der Sar': (G, 90, 'Edwin van der Sar'),
    'Petr Čech': (G, 90, 'Petr Čech'),
    'Courtois': (G, 90, 'Thibaut Courtois'),
    'Alisson': (G, 90, 'Alisson Becker'),
    'Oblak': (G, 89, 'Jan Oblak'),
    'Taffarel': (G, 88, 'Cláudio Taffarel'),
    'Ederson': (G, 88, 'Ederson (footballer, born 1993)'),
    'Ter Stegen': (G, 88, 'Marc-André ter Stegen'),
    'Donnarumma': (G, 88, 'Gianluigi Donnarumma'),
    'Rogério Ceni': (G, 87, 'Rogério Ceni'),
    'Dibu Martínez': (G, 87, 'Emiliano Martínez'),
    'Keylor Navas': (G, 87, 'Keylor Navas'),
    'De Gea': (G, 87, 'David de Gea'),
    'Sepp Maier': (G, 89, 'Sepp Maier'),
    # Defensores e volantes
    'Beckenbauer': (D, 97, 'Franz Beckenbauer'),
    'Maldini': (D, 96, 'Paolo Maldini'),
    'Baresi': (D, 95, 'Franco Baresi'),
    'Matthäus': (D, 94, 'Lothar Matthäus'),
    'Cafu': (D, 93, 'Cafu'),
    'Roberto Carlos': (D, 93, 'Roberto Carlos'),
    'Rijkaard': (D, 93, 'Frank Rijkaard'),
    'Cannavaro': (D, 92, 'Fabio Cannavaro'),
    'Nesta': (D, 92, 'Alessandro Nesta'),
    'Sergio Ramos': (D, 92, 'Sergio Ramos'),
    'Carlos Alberto Torres': (D, 91, 'Carlos Alberto Torres'),
    'Nílton Santos': (D, 91, 'Nílton Santos'),
    'Van Dijk': (D, 91, 'Virgil van Dijk'),
    'Lahm': (D, 91, 'Philipp Lahm'),
    'Rodri': (D, 91, 'Rodri (footballer, born 1996)'),
    'Puyol': (D, 90, 'Carles Puyol'),
    'Thiago Silva': (D, 90, 'Thiago Silva'),
    'Daniel Alves': (D, 90, 'Dani Alves'),
    'Vieira': (D, 90, 'Patrick Vieira'),
    'Marcelo': (D, 89, 'Marcelo (footballer, born 1988)'),
    'Makélélé': (D, 89, 'Claude Makélélé'),
    'Casemiro': (D, 89, 'Casemiro'),
    'Kanté': (D, 89, "N'Golo Kanté"),
    'Busquets': (D, 89, 'Sergio Busquets'),
    'Hierro': (D, 89, 'Fernando Hierro'),
    'Koeman': (D, 89, 'Ronald Koeman'),
    'John Terry': (D, 89, 'John Terry'),
    'Lúcio': (D, 88, 'Lúcio'),
    'Dunga': (D, 88, 'Dunga'),
    'Rio Ferdinand': (D, 88, 'Rio Ferdinand'),
    'Piqué': (D, 88, 'Gerard Piqué'),
    'Gattuso': (D, 87, 'Gennaro Gattuso'),
    'Maicon': (D, 87, 'Maicon (footballer, born 1981)'),
    'Marquinhos': (D, 87, 'Marquinhos'),
    'Gilberto Silva': (D, 86, 'Gilberto Silva'),
    # Meias
    'Maradona': (M, 99, 'Diego Maradona'),
    'Cruyff': (M, 98, 'Johan Cruyff'),
    'Zidane': (M, 97, 'Zinedine Zidane'),
    'Platini': (M, 95, 'Michel Platini'),
    'Ronaldinho': (M, 95, 'Ronaldinho'),
    'Gullit': (M, 94, 'Ruud Gullit'),
    'Kaká': (M, 93, 'Kaká'),
    'Iniesta': (M, 93, 'Andrés Iniesta'),
    'Xavi': (M, 93, 'Xavi'),
    'Modric': (M, 93, 'Luka Modrić'),
    'Didi': (M, 92, 'Didi (footballer, born 1928)'),
    'De Bruyne': (M, 92, 'Kevin De Bruyne'),
    'Pirlo': (M, 92, 'Andrea Pirlo'),
    'Sócrates': (M, 92, 'Sócrates'),
    'Rivaldo': (M, 92, 'Rivaldo'),
    'Figo': (M, 91, 'Luís Figo'),
    'Kroos': (M, 91, 'Toni Kroos'),
    'Rivellino': (M, 91, 'Roberto Rivellino'),
    'Totti': (M, 91, 'Francesco Totti'),
    'Gérson': (M, 90, 'Gérson'),
    'Gerrard': (M, 90, 'Steven Gerrard'),
    'Lampard': (M, 90, 'Frank Lampard'),
    'Laudrup': (M, 90, 'Michael Laudrup'),
    'Nedvěd': (M, 90, 'Pavel Nedvěd'),
    'Beckham': (M, 89, 'David Beckham'),
    'Scholes': (M, 89, 'Paul Scholes'),
    'Seedorf': (M, 89, 'Clarence Seedorf'),
    'Riquelme': (M, 89, 'Juan Román Riquelme'),
    'Hagi': (M, 89, 'Gheorghe Hagi'),
    'Bellingham': (M, 89, 'Jude Bellingham'),
    'Özil': (M, 87, 'Mesut Özil'),
    'Valderrama': (M, 87, 'Carlos Valderrama'),
    'Pedri': (M, 87, 'Pedri'),
    'Bruno Fernandes': (M, 87, 'Bruno Fernandes'),
    'Ødegaard': (M, 87, 'Martin Ødegaard'),
    'Juninho Pernambucano': (M, 87, 'Juninho Pernambucano'),
    # Atacantes
    'Pelé': (A, 99, 'Pelé'),
    'Messi': (A, 98, 'Lionel Messi'),
    'Cristiano Ronaldo': (A, 97, 'Cristiano Ronaldo'),
    'Ronaldo Fenômeno': (A, 97, 'Ronaldo (Brazilian footballer)'),
    'Di Stéfano': (A, 96, 'Alfredo Di Stéfano'),
    'Puskás': (A, 95, 'Ferenc Puskás'),
    'Garrincha': (A, 95, 'Garrincha'),
    'Van Basten': (A, 95, 'Marco van Basten'),
    'Eusébio': (A, 94, 'Eusébio'),
    'Romário': (A, 94, 'Romário'),
    'Gerd Müller': (A, 94, 'Gerd Müller'),
    'Thierry Henry': (A, 93, 'Thierry Henry'),
    'Mbappé': (A, 93, 'Kylian Mbappé'),
    'Neymar': (A, 92, 'Neymar'),
    'Lewandowski': (A, 92, 'Robert Lewandowski'),
    'Haaland': (A, 92, 'Erling Haaland'),
    'Ibrahimovic': (A, 91, 'Zlatan Ibrahimović'),
    'Luis Suárez': (A, 91, 'Luis Suárez'),
    'Batistuta': (A, 91, 'Gabriel Batistuta'),
    'Benzema': (A, 91, 'Karim Benzema'),
    'Salah': (A, 91, 'Mohamed Salah'),
    'Vinícius Jr.': (A, 91, 'Vinícius Júnior'),
    'Jairzinho': (A, 91, 'Jairzinho'),
    'Del Piero': (A, 91, 'Alessandro Del Piero'),
    'Bergkamp': (A, 91, 'Dennis Bergkamp'),
    'Weah': (A, 90, 'George Weah'),
    "Eto'o": (A, 90, "Samuel Eto'o"),
    'Drogba': (A, 90, 'Didier Drogba'),
    'Rooney': (A, 90, 'Wayne Rooney'),
    'Raúl': (A, 90, 'Raúl (footballer)'),
    'Kempes': (A, 90, 'Mario Kempes'),
    'Harry Kane': (A, 90, 'Harry Kane'),
    'Bebeto': (A, 89, 'Bebeto'),
    'Careca': (A, 89, 'Careca'),
    'Tostão': (A, 89, 'Tostão'),
    'Klinsmann': (A, 89, 'Jürgen Klinsmann'),
    'Agüero': (A, 89, 'Sergio Agüero'),
    'Griezmann': (A, 89, 'Antoine Griezmann'),
    'Cantona': (A, 89, 'Eric Cantona'),
    'Michael Owen': (A, 88, 'Michael Owen'),
    'Fernando Torres': (A, 88, 'Fernando Torres'),
    'Lamine Yamal': (A, 87, 'Lamine Yamal'),
}


def gerar():
    linhas = [
        "import '../models/posicao.dart';",
        '',
        '// Gerado por tool/elenco_futebol.py. Para mudar o elenco, edite o script.',
        '',
        '/// Funcao e nota (0-99) de cada jogador do tema Futebol.',
        '/// A funcao define em que rodada da maleta ele aparece e onde pode jogar;',
        '/// a nota define o time mais forte na hora de chamar o juiz.',
        'const elencoFutebol = <String, ({Funcao funcao, int nota})>{',
    ]
    for nome, (f, n, _) in ELENCO.items():
        linhas.append("  %s: (funcao: Funcao.%s, nota: %d)," % (dart_str(nome), f, n))
    linhas += [
        '};',
        '',
        '/// Funcao de cada jogador (atalho para o elenco).',
        'final funcaoDoJogador = {for (final e in elencoFutebol.entries) e.key: e.value.funcao};',
        '',
        'Funcao funcaoDe(String jogador) => elencoFutebol[jogador]?.funcao ?? Funcao.atacante;',
        '',
        '/// Nota do jogador; quem nao esta no elenco (tema personalizado) vale 0.',
        'int notaDe(String jogador) => elencoFutebol[jogador]?.nota ?? 0;',
        '',
    ]
    open(os.path.join(RAIZ, 'lib', 'data', 'futebol_posicoes.dart'), 'w', encoding='utf-8').write('\n'.join(linhas))

    p = os.path.join(RAIZ, 'lib', 'data', 'themes_data.dart')
    s = open(p, encoding='utf-8').read()
    itens = ''.join('      %s,\n' % dart_str(n) for n in ELENCO)
    s, n = re.subn(r"(id: 'futebol',.*?itens: \[\n).*?(    \],)", lambda m: m.group(1) + itens + m.group(2), s, count=1,
                   flags=re.S)
    assert n == 1
    open(p, 'w', encoding='utf-8').write(s)
    print(len(ELENCO), 'jogadores;', {f: sum(1 for v in ELENCO.values() if v[0] == f) for f in (G, D, M, A)})


def dart_str(s):
    return '"%s"' % s if "'" in s else "'%s'" % s


if __name__ == '__main__':
    gerar()
