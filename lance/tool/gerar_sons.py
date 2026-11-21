"""Gera os efeitos sonoros do LANCE! por sintese (livres de direitos).
Uso: python3 tool/gerar_sons.py  -> grava em assets/sounds/*.wav"""
import math, random, struct, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

def salvar(nome, amostras):
    pico = max(1e-9, max(abs(a) for a in amostras))
    with wave.open(os.path.join(OUT, nome), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(a / pico * 0.9 * 32767)) for a in amostras))

def martelo():
    """Batida seca de madeira: ruido filtrado + modos ressonantes curtos."""
    random.seed(7)
    n = int(SR * 0.45); s = []; lp = 0.0
    for i in range(n):
        t = i / SR
        ruido = random.uniform(-1, 1); lp += (ruido - lp) * 0.25
        clique = lp * math.exp(-t * 90)
        corpo = sum(a * math.sin(2 * math.pi * f * t) * math.exp(-t * d)
                    for f, a, d in [(180, 1.0, 22), (410, 0.6, 30), (920, 0.35, 45), (1730, 0.2, 60)])
        s.append(clique * 1.4 + corpo)
    # segundo toque (eco do martelo batendo)
    atraso = int(SR * 0.12)
    for i in range(atraso, n):
        s[i] += s[i - atraso] * 0.35
    return s

def moeda():
    """Moeda: dois tons metalicos agudos em sequencia."""
    n = int(SR * 0.5); s = []
    for i in range(n):
        t = i / SR
        v = 0.0
        for inicio, f in [(0.0, 1975.5), (0.075, 2637.0)]:
            if t >= inicio:
                tt = t - inicio
                v += (math.sin(2*math.pi*f*tt) + 0.3*math.sin(2*math.pi*f*2.76*tt)) * math.exp(-tt * 9)
        s.append(v)
    return s

def fanfarra():
    """Fanfarra curta de metais (onda quadrada suavizada) em arpejo maior."""
    notas = [(0.00, 0.16, 523.25), (0.16, 0.16, 659.25), (0.32, 0.16, 783.99),
             (0.48, 0.9, 1046.5), (0.48, 0.9, 783.99), (0.48, 0.9, 659.25)]
    total = 1.5; n = int(SR * total); s = [0.0] * n
    for inicio, dur, f in notas:
        a = int(inicio * SR); b = min(n, int((inicio + dur + 0.25) * SR))
        for i in range(a, b):
            tt = (i - a) / SR
            env = min(1.0, tt / 0.02) * (1.0 if tt < dur else math.exp(-(tt - dur) * 14))
            vib = 1 + 0.004 * math.sin(2 * math.pi * 6 * tt)
            onda = sum(math.sin(2*math.pi*f*vib*k*tt) / k for k in (1, 3, 5, 7))
            s[i] += onda * env * 0.5
    return s

def toque():
    """Clique suave para botoes."""
    n = int(SR * 0.06)
    return [math.sin(2*math.pi*880*i/SR) * math.exp(-i/SR*70) for i in range(n)]

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    salvar('martelo.wav', martelo()); salvar('moeda.wav', moeda())
    salvar('fanfarra.wav', fanfarra()); salvar('toque.wav', toque())
    print('ok')
