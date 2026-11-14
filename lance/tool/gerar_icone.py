"""Gera o icone do launcher do LANCE! (versao 2).

Selo roxo com cantos arredondados, martelo amarelo com contorno escuro
batendo num bloco, linhas de impacto e brilho. Sem texto (legivel em qualquer tamanho).
Uso: python3 tool/gerar_icone.py  (requer Pillow)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
RES = os.path.join(RAIZ, 'android', 'app', 'src', 'main', 'res')

N = 1024
ROXO_CLARO = (150, 86, 255)
ROXO = (123, 47, 247)
ROXO_FUNDO = (74, 20, 170)
AMARELO = (255, 200, 31)
AMARELO_CLARO = (255, 230, 120)
CONTORNO = (36, 16, 79)


def gradiente(tam, c1, c2):
    """Gradiente diagonal de c1 (canto superior esquerdo) para c2."""
    g = Image.new('RGB', (tam, tam))
    px = g.load()
    for y in range(tam):
        for x in range(tam):
            t = (x + y) / (2 * tam - 2)
            px[x, y] = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
    return g


def rot(pts, ang, cx, cy):
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts]


def ret(w, h, ox, oy, raio_pts=0):
    return [(-w / 2 + ox, -h / 2 + oy), (w / 2 + ox, -h / 2 + oy), (w / 2 + ox, h / 2 + oy), (-w / 2 + ox, h / 2 + oy)]


def poligono(d, pts, fill, contorno, lw):
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=contorno, width=lw, joint='curve')
    r = lw / 2
    for x, y in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=contorno)


def martelo(escala=1.0, dx=0.0, dy=0.0):
    """Martelo + bloco + linhas de impacto, em RGBA transparente."""
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = N / 100 * escala
    ox, oy = N / 2 + (dx - 50) * k, N / 2 + (dy - 50) * k
    lw = max(2, int(4.6 * k))

    def P(x, y):
        return (ox + x * k, oy + y * k)

    # Linhas de impacto (atras de tudo).
    for ang, comp in ((-30, 9), (-60, 8), (0, 8)):
        a = math.radians(ang)
        cx, cy = P(80, 70)
        x1, y1 = cx + math.cos(a) * 13 * k, cy + math.sin(a) * 13 * k
        x2, y2 = cx + math.cos(a) * (13 + comp) * k, cy + math.sin(a) * (13 + comp) * k
        d.line((x1, y1, x2, y2), fill=AMARELO_CLARO, width=int(3.6 * k))
        for (x, y) in ((x1, y1), (x2, y2)):
            r = 1.8 * k
            d.ellipse((x - r, y - r, x + r, y + r), fill=AMARELO_CLARO)

    # Bloco.
    x0, y0 = P(46, 78)
    x1, y1 = P(90, 92)
    d.rounded_rectangle((x0, y0, x1, y1), radius=int(5 * k), fill=AMARELO, outline=CONTORNO, width=lw)
    d.line((P(52, 82.5), P(66, 82.5)), fill=AMARELO_CLARO, width=int(2.4 * k))

    cx, cy = P(42, 42)
    ang = math.pi / 4
    # Cabo.
    poligono(d, rot(ret(11 * k, 54 * k, 0, 26 * k), ang, cx, cy), AMARELO, CONTORNO, lw)
    # Cabeca.
    cab = rot(ret(52 * k, 27 * k, 0, -13 * k), ang, cx, cy)
    poligono(d, cab, AMARELO, CONTORNO, lw)
    # Brilho na cabeca.
    d.line(rot([(-20 * k, -22 * k), (8 * k, -22 * k)], ang, cx, cy), fill=AMARELO_CLARO, width=int(3.4 * k))
    # Aneis.
    for x in (-14, 14):
        d.line(rot([(x * k, -26 * k), (x * k, 0)], ang, cx, cy), fill=CONTORNO, width=int(3.6 * k))
    return img


def sombra(img, deslocamento=0.018, blur=0.02, alfa=0.45):
    a = img.split()[3].filter(ImageFilter.GaussianBlur(N * blur)).point(lambda v: int(v * alfa))
    s = Image.new('RGBA', img.size, CONTORNO + (0,))
    s.putalpha(a)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(s, (int(N * deslocamento * 0.6), int(N * deslocamento)), s)
    return Image.alpha_composite(out, img)


def fundo_roxo():
    base = gradiente(256, ROXO_CLARO, ROXO_FUNDO).resize((N, N), Image.BICUBIC).convert('RGBA')
    # Brilho suave no topo.
    luz = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(luz).ellipse((-N * 0.3, -N * 0.75, N * 1.3, N * 0.45), fill=(255, 255, 255, 38))
    luz = luz.filter(ImageFilter.GaussianBlur(N * 0.14))
    return Image.alpha_composite(base, luz)


def mascara(forma):
    m = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(m)
    if forma == 'circulo':
        d.ellipse((0, 0, N - 1, N - 1), fill=255)
    elif forma == 'selo':
        d.rounded_rectangle((0, 0, N - 1, N - 1), radius=int(N * 0.23), fill=255)
    else:
        d.rectangle((0, 0, N, N), fill=255)
    return m


def icone(forma, escala):
    f = fundo_roxo()
    f = Image.alpha_composite(f, sombra(martelo(escala)))
    out = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    out.paste(f, (0, 0), mascara(forma))
    return out


def main():
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    legado = icone('selo', 0.80)
    redondo = icone('circulo', 0.74)
    frente = sombra(martelo(0.56))
    fundo = fundo_roxo()
    for nome, f in dens.items():
        pasta = os.path.join(RES, 'mipmap-' + nome)
        os.makedirs(pasta, exist_ok=True)
        t = int(48 * f)
        legado.resize((t, t), Image.LANCZOS).save(os.path.join(pasta, 'ic_launcher.png'))
        redondo.resize((t, t), Image.LANCZOS).save(os.path.join(pasta, 'ic_launcher_round.png'))
        ta = int(108 * f)
        frente.resize((ta, ta), Image.LANCZOS).save(os.path.join(pasta, 'ic_launcher_foreground.png'))
        fundo.resize((ta, ta), Image.LANCZOS).save(os.path.join(pasta, 'ic_launcher_background.png'))
    # Icone para a loja / previa.
    legado.resize((512, 512), Image.LANCZOS).save(os.path.join(RAIZ, 'tool', 'icone_preview.png'))
    print('ok')


if __name__ == '__main__':
    main()
