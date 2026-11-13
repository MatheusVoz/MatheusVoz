"""Gera o icone do launcher do LANCE!: martelo de leilao roxo sobre fundo preto.
Uso: python3 tool/gerar_icone.py  (requer Pillow)
Grava os PNGs em android/app/src/main/res/mipmap-*/ e o icone adaptativo."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

RAIZ = os.path.join(os.path.dirname(__file__), '..')
RES = os.path.join(RAIZ, 'android', 'app', 'src', 'main', 'res')

FUNDO = (10, 10, 15)
ROXO = (139, 44, 245)
NEON = (178, 102, 255)
CONTORNO = (233, 214, 255)
ESCURO = (26, 11, 46)

N = 1024  # resolucao de trabalho


def rot(pts, ang, cx, cy):
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts]


def ret_arred(d, caixa, raio, fill, outline, largura):
    d.rounded_rectangle(caixa, radius=raio, fill=fill, outline=outline, width=largura)


def poligono_arred(img, pts, fill, outline, largura):
    """Desenha poligono com contorno grosso e cantos arredondados."""
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=outline, width=largura, joint='curve')
    r = largura / 2
    for x, y in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=outline)


def retangulo_rotacionado(w, h, cx, cy, ang, ox=0.0, oy=0.0):
    pts = [(-w / 2 + ox, -h / 2 + oy), (w / 2 + ox, -h / 2 + oy), (w / 2 + ox, h / 2 + oy), (-w / 2 + ox, h / 2 + oy)]
    return rot(pts, ang, cx, cy)


def desenhar_martelo(tamanho, escala=1.0, deslocar=(0, 0)):
    """Retorna imagem RGBA so com o martelo (fundo transparente)."""
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = N / 100 * escala
    ox = N / 2 + deslocar[0] * k - 50 * k
    oy = N / 2 + deslocar[1] * k - 50 * k
    lw = int(4.2 * k)

    def P(x, y):
        return (ox + x * k, oy + y * k)

    # Bloco onde o martelo bate.
    x0, y0 = P(48, 76)
    x1, y1 = P(92, 91)
    ret_arred(d, (x0, y0, x1, y1), int(6 * k), ROXO, CONTORNO, lw)

    cx, cy = P(44, 42)
    ang = math.pi / 4
    # Cabo.
    cabo = retangulo_rotacionado(12 * k, 56 * k, cx, cy, ang, 0, 24 * k)
    poligono_arred(img, cabo, ROXO, CONTORNO, lw)
    # Cabeca.
    cab = retangulo_rotacionado(54 * k, 26 * k, cx, cy, ang, 0, -14 * k)
    poligono_arred(img, cab, ROXO, CONTORNO, lw)
    # Aneis da cabeca.
    for dx in (-15, 15):
        a = rot([(dx * k, -25 * k), (dx * k, -3 * k)], ang, cx, cy)
        d.line(a, fill=CONTORNO, width=int(3.2 * k))
    return img.resize((tamanho, tamanho), Image.LANCZOS)


def fundo(tamanho, redondo=False):
    img = Image.new('RGBA', (N, N), FUNDO + (255,))
    # Brilho roxo radial no centro.
    brilho = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    bd = ImageDraw.Draw(brilho)
    for i in range(40, 0, -1):
        r = N * 0.46 * i / 40
        alfa = int(230 * (1 - i / 40) ** 1.6)
        bd.ellipse((N / 2 - r, N / 2 - r, N / 2 + r, N / 2 + r), fill=(91, 27, 168, alfa))
    brilho = brilho.filter(ImageFilter.GaussianBlur(N * 0.04))
    img = Image.alpha_composite(img, brilho)
    if redondo:
        mask = Image.new('L', (N, N), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, N - 1, N - 1), fill=255)
        out = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        img = out
    return img.resize((tamanho, tamanho), Image.LANCZOS)


def glow(martelo):
    """Adiciona brilho neon atras do martelo."""
    a = martelo.split()[3]
    sombra = Image.new('RGBA', martelo.size, NEON + (0,))
    sombra.putalpha(a.filter(ImageFilter.GaussianBlur(martelo.size[0] * 0.03)).point(lambda v: int(v * 0.8)))
    return Image.alpha_composite(sombra, martelo)


def icone_legado(tam, redondo):
    base = fundo(N, redondo)
    m = glow(desenhar_martelo(N, escala=0.72, deslocar=(0, 0)))
    if redondo:
        mask = base.split()[3]
        m2 = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        m2.paste(m, (0, 0), mask)
        m = m2
    return Image.alpha_composite(base, m).resize((tam, tam), Image.LANCZOS)


def main():
    densidades = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for nome, f in densidades.items():
        pasta = os.path.join(RES, 'mipmap-' + nome)
        os.makedirs(pasta, exist_ok=True)
        icone_legado(int(48 * f), False).save(os.path.join(pasta, 'ic_launcher.png'))
        icone_legado(int(48 * f), True).save(os.path.join(pasta, 'ic_launcher_round.png'))
        # Icone adaptativo: 108dp, conteudo seguro nos 66dp centrais.
        t = int(108 * f)
        frente = glow(desenhar_martelo(N, escala=0.5))
        frente.resize((t, t), Image.LANCZOS).save(os.path.join(pasta, 'ic_launcher_foreground.png'))
        fundo(t).save(os.path.join(pasta, 'ic_launcher_background.png'))
    # Previa grande para conferencia.
    icone_legado(512, False).save(os.path.join(RAIZ, 'tool', 'icone_preview.png'))
    print('ok')


if __name__ == '__main__':
    main()
