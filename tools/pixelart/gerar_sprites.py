#!/usr/bin/env python3
"""Gera a pixel art do jogo (top-down 16x16) — versão 2.

Técnicas (guias pixel-art-professional e td2d / threedee-twodee), feitas em 2D:
- Rampas por material: 3 a 5 tons, do mais escuro ao mais claro, com hue shifting
  (sombras puxam para azul/roxo, luzes para amarelo).
- Sombreado em faixas (toon) com luz fixa vinda de cima/esquerda: tampo = faixa clara,
  frente = faixa média, lado direito e base = faixas escuras.
- "Linhas" internas no tom mais escuro do próprio material (não preto) onde partes se encontram.
- Passe de contorno externo automático (1 px, 8 vizinhos) e limpeza de pixels soltos.
- Sombra no chão pontilhada (padrão fixo, não "anda" na animação).
- Personagens montados por partes ("rig" 2D): caminhada de 4 quadros com balanço de 1 px,
  respiração parada de 2 quadros; direção leste = espelho da oeste.
- Validação no fim: cores fora da paleta, máximo de cores, pixels soltos e tremido da animação.

Uso:  python3 tools/pixelart/gerar_sprites.py
Saída: assets/sprites/*.png, tools/pixelart/previa.png, tools/pixelart/validacao.json
Os PNGs podem ser retocados no Aseprite.
"""
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites"
TOOLS = ROOT / "tools" / "pixelart"

# ------------------------------------------------------------------ rampas (escuro -> claro)
R = {
    "madeira": ["#4a2a35", "#7a4630", "#b0703e", "#dca05c", "#f0c886"],
    "metal": ["#22203a", "#363859", "#52587a", "#7a82a4"],          # corpo de equipamentos
    "plastico": ["#5e6688", "#959ebf", "#c6cce2", "#eef0f8"],       # branco/cinza claro
    "tela": ["#121f3a", "#1b3256", "#284c78"],                      # tela desligada
    "tela_on": ["#2a64a8", "#46a0dc", "#8cd6f4", "#d6f4ff"],
    "azul": ["#1c2a66", "#2a52a4", "#4a84d8", "#8ec2f4"],
    "lousa": ["#12332f", "#1b5243", "#2a7454"],
    "vermelho": ["#4e1a3a", "#9c2c40", "#d9534c", "#f59a7a"],
    "amarelo": ["#7e3f1c", "#c8801e", "#f2b934", "#ffe9a0"],
    "pele": ["#6e3640", "#b56c56", "#e8a27c", "#ffd3ad"],
    "cabelo": ["#24142a", "#45273a", "#6c4034"],
    "cabelo_loiro": ["#7a4a28", "#c08a3a", "#ecc35a"],
    "camisa": ["#14384a", "#1d6466", "#2c9886", "#68cca4"],
    "camisa_roxa": ["#2b1d4e", "#55398a", "#8a68c6", "#bea2ec"],
    "calca": ["#18203f", "#283868", "#3f5594"],
    "folha": ["#15372f", "#1f6342", "#369a52", "#86d066"],
    "verde_led": ["#1a6b45", "#2fbf6a", "#9ef0a0"],
    "papel": ["#c9b98f", "#efe3bd", "#fffbe8"],
    # pisos e paredes
    "tijolo": ["#94604f", "#b98063", "#d39f78", "#e8bf92"],
    "taco": ["#6e3f30", "#9a5c3a", "#c27f4e", "#dda36a"],
    "frio": ["#4f86aa", "#79b0cc", "#a6d4e6", "#d4f0f8"],
    "corredor": ["#7e86a8", "#a4abc6", "#c9cde0", "#e6e8f2"],
    "parede": ["#9a9bc8", "#c3c4e6", "#dcdcf4", "#f0effc"],
    "moldura": ["#26315e", "#3f5596", "#5a78c2", "#88a6e6"],
}
CONTORNO = "#1e1b33"
SOMBRA = "#3a4466"         # sombra no chão (como o groundShadow do td2d)
EXTRA = [CONTORNO, SOMBRA, "#ffffff"]

PALETA = {c.lower() for ramp in R.values() for c in ramp} | {c.lower() for c in EXTRA}

# matriz de Bayer 4x4 (pontilhado ordenado, padrão fixo na tela)
BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def rgba(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def hexof(p):
    return "#%02x%02x%02x" % p[:3]


class C:
    """Tela de desenho com primitivas (sem contorno: o contorno é um passe no fim)."""

    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.w, self.h = w, h

    def px(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), rgba(col))

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.img.getpixel((x, y))
        return (0, 0, 0, 0)

    def rect(self, x, y, w, h, col):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.px(xx, yy, col)

    def hline(self, x, y, w, col):
        self.rect(x, y, w, 1, col)

    def vline(self, x, y, h, col):
        self.rect(x, y, 1, h, col)

    def dither(self, x, y, w, h, col_a, col_b, level):
        """Mistura dois tons com Bayer 4x4. level 0..1 = quanto de col_b."""
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                t = (BAYER4[yy % 4][xx % 4] + 0.5) / 16.0
                self.px(xx, yy, col_b if t < level else col_a)

    def paste(self, other, x, y):
        img = other.img if isinstance(other, C) else other
        self.img.alpha_composite(img, (x, y))

    # --- primitivas com sombreado em faixas (luz de cima/esquerda)
    def block(self, x, y, w, top, front, ramp, line=True):
        """Caixa vista de cima/frente: tampo (claro) + frente (média) + lado direito e base escuros."""
        n = len(ramp)
        self.rect(x, y, w, top, ramp[n - 2])
        self.hline(x, y, w, ramp[n - 1])                 # aresta de cima pega luz
        self.vline(x, y, top, ramp[n - 1])               # lado esquerdo do tampo pega luz
        self.rect(x, y + top, w, front, ramp[n - 3] if n >= 3 else ramp[0])
        self.vline(x + w - 1, y, top + front, ramp[1])   # lado direito: sombra
        self.hline(x, y + top + front - 1, w, ramp[0])   # base: sombra de contato
        if line and top > 0:
            self.hline(x + 1, y + top, w - 2, ramp[1])   # linha entre tampo e frente

    def ground_shadow(self, x, y, w, h):
        """Sombra no chão pontilhada (xadrez), sempre no mesmo padrão."""
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if (xx + yy) % 2 == 0:
                    self.px(xx, yy, SOMBRA)

    def disc(self, cx, cy, r, ramp):
        """Círculo com luz de cima/esquerda (3 faixas)."""
        n = len(ramp)
        for yy in range(int(cy - r - 1), int(cy + r + 2)):
            for xx in range(int(cx - r - 1), int(cx + r + 2)):
                dx, dy = xx + 0.5 - cx, yy + 0.5 - cy
                if dx * dx + dy * dy <= r * r:
                    light = -(dx + dy) / (r * 1.6)        # -1 (sombra) .. 1 (luz)
                    band = max(0, min(n - 1, int((light + 1) / 2 * n)))
                    self.px(xx, yy, ramp[band])


# ------------------------------------------------------------------ passes (como no td2d)
def outline_pass(img, color=CONTORNO):
    """Anel de 1 px em volta da silhueta (8 vizinhos)."""
    w, h = img.size
    src = img.copy()
    out = img.copy()
    col = rgba(color)
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    p = src.getpixel((nx, ny))
                    if p[3] != 0 and hexof(p) != SOMBRA:
                        out.putpixel((x, y), col)
                        break
    return out


def cleanup_pass(img):
    """Remove pixels opacos sem nenhum vizinho opaco (pixels soltos)."""
    w, h = img.size
    out = img.copy()
    removed = 0
    for y in range(h):
        for x in range(w):
            if img.getpixel((x, y))[3] == 0:
                continue
            n = 0
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and img.getpixel((nx, ny))[3] != 0:
                    n += 1
            if n == 0 and hexof(img.getpixel((x, y))) != SOMBRA:
                out.putpixel((x, y), (0, 0, 0, 0))
                removed += 1
    return out, removed


def finish(c, outline=True):
    img = c.img if isinstance(c, C) else c
    img, _ = cleanup_pass(img)
    return outline_pass(img) if outline else img


# ------------------------------------------------------------------ tiles (sem contorno)
def tile_brick():
    t = R["tijolo"]
    c = C(16, 16)
    c.rect(0, 0, 16, 16, t[2])
    for band in range(4):
        y = band * 4
        c.hline(0, y + 3, 16, t[0])
        off = 0 if band % 2 == 0 else 4
        for x in (off, off + 8):
            c.vline(x % 16, y, 3, t[0])
            c.hline((x + 1) % 16, y, 6, t[3])          # topo do tijolo pega luz
            c.px((x + 6) % 16, y + 2, t[1])            # canto de baixo/direita em sombra
    return c.img


def tile_wood():
    t = R["taco"]
    c = C(16, 16)
    c.rect(0, 0, 16, 16, t[2])
    for i, y in enumerate((0, 4, 8, 12)):
        c.hline(0, y + 3, 16, t[0])
        c.hline(0, y, 16, t[3]) if i % 2 == 0 else None
        c.vline((5 + i * 6) % 16, y, 3, t[0])
        c.px((2 + i * 5) % 16, y + 1, t[1])
        c.px((3 + i * 5) % 16, y + 1, t[1])
    return c.img


def tile_cold():
    t = R["frio"]
    c = C(16, 16)
    c.rect(0, 0, 16, 16, t[2])
    c.hline(0, 15, 16, t[0])
    c.vline(15, 0, 16, t[0])
    c.hline(0, 0, 15, t[3])
    c.vline(0, 0, 15, t[3])
    c.dither(9, 9, 6, 6, t[2], t[1], 0.3)             # leve variação (piso frio, brilho)
    return c.img


def tile_corridor():
    t = R["corredor"]
    c = C(16, 16)
    c.rect(0, 0, 8, 8, t[1])
    c.rect(8, 8, 8, 8, t[1])
    c.rect(8, 0, 8, 8, t[3])
    c.rect(0, 8, 8, 8, t[3])
    c.hline(0, 0, 8, t[2])
    c.hline(8, 8, 8, t[2])
    return c.img


def tile_wall():
    """Parede vista de frente (16x32): moldura, parede com luz pontilhada no alto, rodapé."""
    p, m = R["parede"], R["moldura"]
    c = C(16, 32)
    c.rect(0, 0, 16, 32, p[2])
    c.rect(0, 0, 16, 3, m[2])
    c.hline(0, 0, 16, m[3])
    c.hline(0, 3, 16, m[0])
    c.dither(0, 4, 16, 6, p[3], p[2], 0.55)           # luz do teto se espalhando
    c.dither(0, 22, 16, 5, p[2], p[1], 0.45)          # parede escurece perto do chão
    c.rect(0, 27, 16, 4, p[1])
    c.hline(0, 27, 16, p[3])
    c.hline(0, 31, 16, m[0])
    return c.img


def tile_frame():
    m = R["moldura"]
    c = C(16, 16)
    c.rect(0, 0, 16, 16, m[2])
    c.hline(0, 0, 16, m[3])
    c.hline(0, 15, 16, m[0])
    return c.img


# ------------------------------------------------------------------ decoração de parede
def blackboard():
    w, l, g = R["madeira"], R["lousa"], R["papel"]
    c = C(32, 18)
    c.rect(1, 1, 30, 14, w[2])
    c.hline(1, 1, 30, w[3])
    c.vline(30, 1, 14, w[1])
    c.rect(2, 2, 28, 12, l[1])
    c.dither(2, 2, 28, 4, l[1], l[2], 0.35)            # reflexo pontilhado
    for x, y in ((6, 5), (14, 5), (22, 5)):
        c.rect(x, y, 3, 2, g[2])
    c.rect(13, 10, 5, 2, g[2])
    for x in (7, 15, 23):
        c.vline(x, 7, 2, g[1])
    c.hline(7, 9, 17, g[1])
    c.rect(1, 15, 30, 2, w[1])
    c.rect(26, 14, 3, 1, g[2])                        # giz
    return finish(c)


def clock():
    p, m = R["plastico"], R["metal"]
    c = C(10, 10)
    c.disc(5, 5, 4, p)
    c.vline(5, 2, 3, m[0])
    c.hline(5, 5, 2, m[0])
    return finish(c)


def window():
    m, s = R["moldura"], R["tela_on"]
    c = C(16, 16)
    c.rect(1, 1, 14, 12, s[2])
    c.dither(1, 1, 14, 12, s[2], s[3], 0.25)          # céu claro
    c.px(3, 3, s[3]); c.px(4, 3, s[3]); c.px(3, 4, s[3])
    c.vline(7, 1, 12, m[2])
    c.hline(1, 6, 14, m[2])
    c.rect(0, 13, 16, 2, m[1])
    c.hline(0, 13, 16, m[3])
    return finish(c)


def poster(kind):
    pa, b, y = R["papel"], R["azul"], R["amarelo"]
    c = C(10, 12)
    c.rect(1, 1, 8, 10, pa[2] if kind == "rede" else R["tela_on"][3])
    c.vline(8, 1, 10, pa[0])
    c.hline(1, 10, 8, pa[0])
    if kind == "rede":
        c.rect(4, 4, 2, 2, y[2])
        for x, yy in ((2, 2), (7, 2), (2, 7), (7, 7)):
            c.px(x, yy, b[2])
        c.px(3, 3, b[1]); c.px(6, 3, b[1]); c.px(3, 6, b[1]); c.px(6, 6, b[1])
    else:
        for i, w in enumerate((6, 4, 2)):
            c.hline(5 - w // 2, 3 + i * 2, w, b[2])
        c.px(4, 8, b[1]); c.px(5, 8, b[1])
    return finish(c)


def note():
    y = R["amarelo"]
    c = C(9, 9)
    c.rect(1, 1, 7, 7, y[3])
    c.vline(7, 1, 7, y[2])
    for row in (2, 4, 6):
        c.hline(2, row, 4 if row != 4 else 3, y[1])
    return finish(c, outline=False)


def extinguisher():
    r, m = R["vermelho"], R["metal"]
    c = C(9, 13)
    c.rect(2, 4, 5, 8, r[2])
    c.vline(2, 4, 8, r[3])
    c.vline(6, 4, 8, r[1])
    c.hline(2, 11, 5, r[0])
    c.rect(2, 7, 5, 1, R["plastico"][3])
    c.rect(3, 2, 3, 2, m[2])
    c.hline(5, 1, 3, m[1])
    return finish(c)


# ------------------------------------------------------------------ móveis
def desk(w=32):
    m = R["madeira"]
    c = C(w, 16)
    c.ground_shadow(3, 13, w - 6, 2)
    c.block(1, 1, w - 2, 7, 3, m)
    for x in (6, 15, 24):
        if x + 4 < w - 2:
            c.hline(x, 4, 4, m[2])                      # veios
    for x in (2, w - 5):
        c.rect(x, 11, 3, 4, m[1])
        c.vline(x, 11, 4, m[2])
    return finish(c)


def small_desk():
    m = R["madeira"]
    c = C(16, 16)
    c.ground_shadow(3, 12, 10, 3)
    c.block(1, 3, 14, 5, 3, m)
    c.rect(2, 11, 2, 4, m[1])
    c.rect(12, 11, 2, 4, m[1])
    return finish(c)


def chair():
    m = R["madeira"]
    c = C(16, 16)
    c.ground_shadow(4, 12, 8, 3)
    c.block(4, 1, 8, 1, 4, m)                          # encosto
    c.block(4, 6, 8, 3, 2, m)                          # assento
    c.rect(4, 11, 1, 3, m[0])
    c.rect(11, 11, 1, 3, m[0])
    return finish(c)


def bookshelf():
    m = R["madeira"]
    c = C(16, 32)
    c.block(1, 1, 14, 2, 29, m, line=False)
    colors = [R["vermelho"], R["azul"], R["folha"], R["amarelo"], R["camisa_roxa"]]
    for shelf in range(4):
        y = 4 + shelf * 7
        c.rect(2, y, 12, 6, m[0])                      # fundo da prateleira (sombra)
        c.hline(2, y + 6, 12, m[3])                    # tábua pega luz
        x, i = 2, 0
        while x < 13:
            wdt = 2 if (x + shelf) % 3 else 1
            hgt = 5 if (x + i) % 4 else 4
            ramp = colors[(x + shelf * 2) % len(colors)]
            c.rect(x, y + 6 - hgt, wdt, hgt, ramp[2])
            c.px(x, y + 6 - hgt, ramp[3])
            x += wdt
            i += 1
    return finish(c)


def locker():
    b = R["azul"]
    c = C(16, 32)
    c.block(1, 1, 14, 2, 29, b, line=False)
    c.vline(7, 3, 27, b[0])
    for x in (2, 9):
        for y in (5, 7, 9):
            c.hline(x, y, 4, b[1])
        c.rect(x + 3, 16, 1, 3, R["plastico"][3])
    return finish(c)


def file_cabinet():
    p = R["plastico"]
    c = C(16, 24)
    c.block(1, 1, 14, 2, 21, p, line=False)
    for y in (4, 10, 16):
        c.rect(2, y, 11, 5, p[2])
        c.hline(2, y, 11, p[3])
        c.hline(2, y + 4, 11, p[1])
        c.hline(5, y + 2, 5, p[0])
    return finish(c)


def plant():
    f, v = R["folha"], R["vermelho"]
    c = C(16, 16)
    c.ground_shadow(4, 14, 8, 1)
    c.block(4, 9, 8, 1, 4, v)                          # vaso
    for cx, cy, r in ((8, 6, 4.2), (5, 5, 2.6), (11, 5, 2.6), (8, 2.6, 2.4)):
        c.disc(cx, cy, r, f)
    return finish(c)


def rack():
    m = R["metal"]
    c = C(16, 32)
    c.block(1, 1, 14, 2, 29, m, line=False)
    for i in range(6):
        y = 4 + i * 4
        c.rect(2, y, 11, 3, m[2])
        c.hline(2, y, 11, m[3])
        c.hline(4, y + 1, 4, m[1])
        c.px(10, y + 1, R["verde_led"][1])
        c.px(12, y + 1, R["amarelo"][2] if i % 2 else R["verde_led"][1])
    return finish(c)


def door():
    m, s = R["madeira"], R["tela_on"]
    c = C(16, 24)
    c.block(1, 1, 14, 0, 22, m, line=False)
    c.rect(3, 3, 10, 7, s[2])
    c.dither(3, 3, 10, 7, s[2], s[3], 0.3)
    c.rect(3, 12, 10, 9, m[2])
    c.hline(3, 12, 10, m[3])
    c.rect(11, 14, 2, 2, R["amarelo"][2])
    return finish(c)


# ------------------------------------------------------------------ equipamentos (mesa + aparelho)
def on_desk(top, x, y, w=32, h=26, desk_img=None):
    c = C(w, h)
    c.paste(desk_img if desk_img is not None else desk(w), 0, h - 16)
    c.paste(top, x, y)
    return c.img


def monitor(on, w=14, h=10):
    m, s = R["metal"], R["tela_on"] if on else R["tela"]
    c = C(w + 2, h + 7)
    c.rect(1, 1, w, h, m[1])
    c.hline(1, 1, w, m[3])
    c.vline(1, 1, h, m[2])
    c.rect(2, 2, w - 2, h - 3, s[1])
    if on:
        c.dither(2, 2, w - 2, h - 3, s[1], s[2], 0.35)
        for i, ln in enumerate((w - 6, w - 8, w - 5)):
            c.hline(3, 3 + i * 2, ln, s[3])
    else:
        c.px(3, 3, s[2]); c.px(4, 3, s[2]); c.px(3, 4, s[2])   # reflexo
    c.px(w - 2, h - 1, R["verde_led"][1] if on else m[3])      # LED
    c.rect(w // 2, h + 1, 2, 3, m[2])
    c.rect(w // 2 - 3, h + 4, 8, 2, m[1])
    c.hline(w // 2 - 3, h + 4, 8, m[2])
    return finish(c)


def keyboard():
    p = R["plastico"]
    c = C(12, 6)
    c.block(1, 1, 10, 2, 2, p)
    for x in range(2, 10, 2):
        c.px(x, 2, p[1])
    return finish(c)


def pc(on):
    base = C(32, 26)
    base.paste(desk(), 0, 10)
    base.paste(monitor(on), 4, 0)
    base.paste(keyboard(), 18, 13)
    return base.img


def notebook(on):
    m, s = R["metal"], R["tela_on"] if on else R["tela"]
    c = C(16, 14)
    c.rect(2, 1, 12, 8, m[1])
    c.hline(2, 1, 12, m[3])
    c.rect(3, 2, 10, 6, s[1])
    if on:
        c.dither(3, 2, 10, 6, s[1], s[2], 0.35)
        c.hline(4, 3, 6, s[3])
        c.hline(4, 5, 4, s[3])
    c.block(1, 9, 14, 2, 2, R["plastico"])
    for x in range(3, 13, 2):
        c.px(x, 10, R["plastico"][1])
    return on_desk(finish(c), 8, 3)


def server(on):
    m = R["metal"]
    c = C(32, 26)
    c.ground_shadow(10, 24, 14, 2)
    c.block(9, 1, 14, 2, 22, m, line=False)
    for i in range(5):
        y = 4 + i * 4
        c.rect(10, y, 11, 3, m[2])
        c.hline(10, y, 11, m[3])
        c.hline(12, y + 1, 4, m[1])
        led = R["verde_led"][1] if on else m[1]
        c.px(18, y + 1, led)
        c.px(20, y + 1, (R["amarelo"][2] if i % 2 else led) if on else m[1])
    return finish(c).copy()


def switch_img(on):
    m = R["metal"]
    c = C(64, 16)
    c.ground_shadow(3, 13, 58, 2)
    c.block(1, 3, 62, 3, 7, m)
    c.rect(4, 7, 9, 1, m[3])
    c.rect(4, 9, 6, 1, m[3])
    for i in range(8):
        x = 18 + i * 5
        c.rect(x, 7, 4, 3, m[0])
        c.hline(x, 9, 4, m[1])
        c.px(x + 1, 4, R["verde_led"][1] if on else m[1])
    return finish(c)


def access_point(on):
    p, m, b = R["plastico"], R["metal"], R["azul"]
    c = C(16, 12)
    c.vline(3, 1, 6, m[1])
    c.vline(12, 1, 6, m[1])
    c.block(1, 6, 14, 2, 3, p)
    c.px(7, 9, R["verde_led"][1] if on else m[2])
    top = finish(c)
    out = C(32, 26)
    out.paste(small_desk(), 8, 10)
    out.paste(top, 8, 1)
    if on:                                             # ondas do Wi-Fi
        for i, w in enumerate((8, 4)):
            out.hline(16 - w // 2, 1 + i * 2, w, b[2])
        out.px(15, 5, b[3]); out.px(16, 5, b[3])
    return out.img


def printer():
    p, m = R["plastico"], R["metal"]
    c = C(16, 12)
    c.rect(4, 1, 8, 3, R["papel"][2])
    c.block(1, 3, 14, 3, 5, p)
    c.rect(3, 8, 10, 1, m[1])
    c.px(12, 5, R["verde_led"][1])
    return on_desk(finish(c), 8, 4)


def panel(on):
    m, s = R["metal"], R["tela_on"] if on else R["tela"]
    c = C(26, 17)
    c.rect(1, 1, 24, 11, m[1])
    c.hline(1, 1, 24, m[3])
    c.rect(2, 2, 22, 9, s[0] if on else s[1])
    if on:
        pts = [(3, 9), (5, 8), (7, 8), (9, 6), (11, 7), (13, 5), (15, 4), (17, 5), (19, 3), (21, 4)]
        for x, y in pts:
            c.px(x, y, s[2]); c.px(x + 1, y, s[2])
        c.hline(2, 10, 22, s[1])
    c.px(22, 11, R["verde_led"][1] if on else m[3])
    c.rect(12, 12, 2, 2, m[2])
    c.rect(9, 14, 8, 2, m[1])
    return on_desk(finish(c), 3, 0)


def thermometer():
    r, p = R["vermelho"], R["plastico"]
    c = C(10, 16)
    c.rect(3, 1, 4, 10, p[3])
    c.vline(6, 1, 10, p[1])
    c.rect(4, 3, 2, 8, r[2])
    c.disc(5, 12, 3.2, r)
    for y in (3, 5, 7):
        c.px(8, y, p[0])
    out = C(32, 26)
    out.paste(small_desk(), 8, 10)
    out.paste(finish(c), 11, 0)
    return out.img


def lamp(on):
    y, p, m = R["amarelo"], R["plastico"], R["metal"]
    c = C(14, 14)
    c.disc(7, 5.5, 4.6, y if on else p)
    c.rect(5, 10, 4, 2, m[2])
    c.hline(5, 12, 4, m[1])
    out = C(32, 26)
    if on:                                             # brilho pontilhado em volta
        for yy in range(0, 14):
            for xx in range(4, 28):
                dx, dy = xx - 16, yy - 6
                if dx * dx + dy * dy * 2 < 120 and (xx + yy) % 2 == 0:
                    out.px(xx, yy, y[3])
    out.paste(small_desk(), 8, 10)
    out.paste(finish(c), 9, 0)
    return out.img


def presence(on):
    p, r = R["plastico"], R["vermelho"] if on else R["metal"]
    c = C(14, 10)
    c.block(1, 2, 12, 2, 5, p)
    c.disc(7, 5, 2.6, r)
    out = C(32, 26)
    out.paste(small_desk(), 8, 10)
    out.paste(finish(c), 9, 2)
    return out.img


# ------------------------------------------------------------------ personagens ("rig" 2D)
def character(direction, frame, anim, shirt="camisa", hair="cabelo", badge=True):
    """Monta o personagem 16x16 por partes.
    anim 'andar': 4 quadros (contato, passagem, contato, passagem) com o corpo 1 px mais baixo no contato.
    anim 'parado': 2 quadros de respiração (ombros e cabeça descem 1 px no quadro 1)."""
    sk, hr, sh, pa = R["pele"], R[hair], R[shirt], R["calca"]
    c = C(16, 16)
    if anim == "andar":
        bob = 1 if frame in (0, 2) else 0
        swing = {0: 1, 1: 0, 2: -1, 3: 0}[frame]      # perna esquerda à frente (+1) / direita (-1)
    else:
        bob = frame
        swing = 0
    c.ground_shadow(4, 14, 8, 2)
    if direction in ("s", "n"):
        # pernas (14 = sola). No contato a perna da frente fica 1 px mais longa (pisa mais "perto")
        for side, x in ((-1, 5), (1, 9)):
            front = (swing == 1 and side == -1) or (swing == -1 and side == 1)
            back = (swing == 1 and side == 1) or (swing == -1 and side == -1)
            top = 11 + bob
            bottom = 14 if not back else 13
            c.rect(x, top, 2, bottom - top, pa[1])
            c.vline(x, top, bottom - top, pa[2])
            c.hline(x, bottom, 2, R["metal"][1])     # sapato
            if front:
                c.hline(x, bottom, 2, R["metal"][2])
        # tronco
        ty = 7 + bob
        c.rect(4, ty, 8, 4, sh[2])
        c.vline(4, ty, 4, sh[3])
        c.vline(11, ty, 4, sh[1])
        c.hline(4, ty + 3, 8, sh[1])
        if direction == "s" and badge:
            c.rect(9, ty + 1, 2, 2, R["amarelo"][2])
        # braços balançam ao contrário das pernas
        for side, x in ((-1, 3), (1, 12)):
            dy = -swing * side if anim == "andar" else 0
            ay = ty + max(0, dy)
            c.rect(x, ay, 1, 3, sh[2] if side < 0 else sh[1])
            c.px(x, ay + 3, sk[2])
        # cabeça
        hy = 1 + bob
        c.rect(4, hy, 8, 6, sk[2])
        c.vline(4, hy, 6, sk[3])
        c.vline(11, hy, 6, sk[1])
        c.hline(5, hy + 5, 6, sk[1])                   # queixo em sombra
        if direction == "s":
            c.rect(4, hy, 8, 2, hr[1])
            c.hline(4, hy, 8, hr[2])
            c.px(4, hy + 2, hr[1]); c.px(11, hy + 2, hr[1])
            c.px(6, hy + 3, R["metal"][0]); c.px(9, hy + 3, R["metal"][0])   # olhos
            c.px(7, hy + 4, sk[1]); c.px(8, hy + 4, sk[1])
        else:
            c.rect(4, hy, 8, 5, hr[1])
            c.hline(4, hy, 8, hr[2])
            c.vline(4, hy, 5, hr[2])
            c.hline(5, hy + 5, 6, sk[1])
    else:  # "w" (esquerda); "e" é o espelho
        top = 11 + bob
        # pernas: a da frente vai para a esquerda, a de trás para a direita
        legs = [(7 - swing, pa[2]), (8 + swing, pa[1])] if swing else [(7, pa[2]), (8, pa[1])]
        for x, col in legs:
            c.rect(x, top, 2 if not swing else 1, 14 - top, col)
            c.hline(x - (1 if x <= 7 else 0), 14, 2, R["metal"][1])
        ty = 7 + bob
        c.rect(5, ty, 6, 4, sh[2])
        c.vline(5, ty, 4, sh[3])
        c.vline(10, ty, 4, sh[1])
        c.hline(5, ty + 3, 6, sh[1])
        ax = 7 + (swing if anim == "andar" else 0)
        c.rect(ax, ty + 1, 2, 3, sh[1])
        c.px(ax, ty + 4, sk[2])
        hy = 1 + bob
        c.rect(5, hy, 6, 6, sk[2])
        c.vline(5, hy, 6, sk[3])
        c.rect(8, hy, 3, 5, hr[1])                     # cabelo atrás
        c.rect(5, hy, 6, 2, hr[1])
        c.hline(5, hy, 6, hr[2])
        c.px(6, hy + 3, R["metal"][0])                 # olho
        c.px(4, hy + 3, sk[2])                         # nariz
        c.hline(5, hy + 5, 5, sk[1])
    return finish(c)


def bit(mood):
    b, s, y = R["azul"], R["tela_on"], R["amarelo"]
    c = C(16, 16)
    c.ground_shadow(4, 15, 8, 1)
    c.vline(8, 1, 2, R["metal"][2])
    c.px(8, 0, y[2])
    c.block(2, 3, 12, 2, 7, b)                         # cabeça
    c.rect(4, 6, 8, 4, R["tela"][0])                   # rosto (tela)
    eye = s[3]
    if mood == "feliz":
        for x in (5, 9):
            c.hline(x, 7, 2, eye)                      # olhos fechados de alegria
        c.hline(6, 9, 4, eye)                          # sorriso
        c.px(5, 8, eye); c.px(10, 8, eye)
    elif mood == "pensando":
        c.hline(5, 7, 2, eye); c.hline(9, 7, 2, eye)
        c.hline(7, 9, 3, eye)
    else:
        c.rect(5, 7, 2, 2, eye); c.rect(9, 7, 2, 2, eye)
        c.hline(6, 9, 4, s[2])
    c.block(5, 12, 6, 1, 2, b)                         # corpo
    c.px(8, 13, y[2])
    c.px(4, 13, b[2]); c.px(11, 13, b[2])              # bracinhos
    return finish(c)


# ------------------------------------------------------------------ validação (como no td2d)
def validate(sprites, walks, max_colors=24):
    report = {"sprites": {}, "problemas": []}
    for name, img in sprites.items():
        colors = {hexof(img.getpixel((x, y))) for y in range(img.height) for x in range(img.width)
                  if img.getpixel((x, y))[3] != 0}
        fora = sorted(c for c in colors if c not in PALETA)
        orphans = 0
        w, h = img.size
        for y in range(h):
            for x in range(w):
                if img.getpixel((x, y))[3] == 0:
                    continue
                if not any(0 <= x + dx < w and 0 <= y + dy < h and img.getpixel((x + dx, y + dy))[3]
                           for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1))):
                    orphans += 1
        report["sprites"][name] = {"tamanho": [w, h], "cores": len(colors), "pixels_soltos": orphans}
        if fora:
            report["problemas"].append(f"{name}: cores fora da paleta {fora}")
        if len(colors) > max_colors:
            report["problemas"].append(f"{name}: {len(colors)} cores (máximo {max_colors})")
    # tremido: o centro de massa não pode pular mais de 2 px entre quadros seguidos
    for clip, frames in walks.items():
        cents = []
        for img in frames:
            pts = [(x, y) for y in range(img.height) for x in range(img.width) if img.getpixel((x, y))[3]]
            cents.append((sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)))
        worst = max(abs(a[0] - b[0]) + abs(a[1] - b[1]) for a, b in zip(cents, cents[1:] + cents[:1]))
        report.setdefault("animacoes", {})[clip] = {"quadros": len(frames), "maior_tremido_px": round(worst, 2)}
        if worst > 2:
            report["problemas"].append(f"{clip}: tremido de {worst:.1f} px")
    return report


# ------------------------------------------------------------------ gerar tudo
def main():
    sprites = {
        "piso_tijolo": tile_brick(), "piso_madeira": tile_wood(), "piso_frio": tile_cold(),
        "piso_corredor": tile_corridor(), "parede": tile_wall(), "moldura": tile_frame(),
        "quadro": blackboard(), "relogio": clock(), "janela": window(),
        "cartaz_rede": poster("rede"), "cartaz_wifi": poster("wifi"), "bilhete": note(),
        "extintor": extinguisher(), "mesa": desk(), "mesinha": small_desk(), "cadeira": chair(),
        "estante": bookshelf(), "armario": locker(), "arquivo": file_cabinet(), "planta": plant(),
        "rack": rack(), "porta": door(), "impressora": printer(), "sensor_temp": thermometer(),
        "bit": bit("normal"), "bit_feliz": bit("feliz"), "bit_pensando": bit("pensando"),
    }
    for on in (False, True):
        suf = "_on" if on else "_off"
        sprites["pc" + suf] = pc(on)
        sprites["notebook" + suf] = notebook(on)
        sprites["servidor" + suf] = server(on)
        sprites["switch" + suf] = switch_img(on)
        sprites["ap" + suf] = access_point(on)
        sprites["painel" + suf] = panel(on)
        sprites["lampada" + suf] = lamp(on)
        sprites["sensor_pres" + suf] = presence(on)

    walks = {}
    names = {"s": "baixo", "n": "cima", "w": "esquerda"}
    for who, kw in (("tecnico", {}), ("visitante", {"shirt": "camisa_roxa", "hair": "cabelo_loiro", "badge": False})):
        for d, nome in names.items():
            frames = [character(d, f, "andar", **kw) for f in range(4)]
            walks[f"{who}_{nome}_andar"] = frames
            for f, img in enumerate(frames):
                sprites[f"{who}_{nome}_{f}"] = img
                if d == "w":
                    sprites[f"{who}_direita_{f}"] = img.transpose(Image.FLIP_LEFT_RIGHT)
            for f in range(2):
                img = character(d, f, "parado", **kw)
                sprites[f"{who}_{nome}_parado_{f}"] = img
                if d == "w":
                    sprites[f"{who}_direita_parado_{f}"] = img.transpose(Image.FLIP_LEFT_RIGHT)
    sprites["visitante"] = sprites["visitante_baixo_0"]

    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.png"):
        old.unlink()
    for name, img in sprites.items():
        img.save(OUT / f"{name}.png")

    report = validate(sprites, walks)
    (TOOLS / "validacao.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))

    # prévia (folha de contato) e GIFs da caminhada para conferência
    keys = list(sprites)
    preview = Image.new("RGBA", (10 * 70, ((len(keys) + 9) // 10) * 70), rgba("#ffffff"))
    for i, name in enumerate(keys):
        img = sprites[name]
        big = img.resize((img.width * 2, img.height * 2), Image.NEAREST)
        preview.alpha_composite(big, ((i % 10) * 70 + 2, (i // 10) * 70 + 2))
    preview.save(TOOLS / "previa.png")
    gif_frames = []
    for f in range(4):
        row = Image.new("RGBA", (16 * 4 * 6, 16 * 6), rgba("#d39f78"))
        for i, nome in enumerate(("baixo", "esquerda", "cima", "direita")):
            spr = sprites[f"tecnico_{nome}_{f}"].resize((96, 96), Image.NEAREST)
            row.alpha_composite(spr, (i * 96, 0))
        gif_frames.append(row.convert("P", palette=Image.ADAPTIVE))
    gif_frames[0].save(TOOLS / "tecnico_andando.gif", save_all=True, append_images=gif_frames[1:], duration=100, loop=0)

    print(f"{len(sprites)} sprites gerados em {OUT}")
    if report["problemas"]:
        print("PROBLEMAS DE VALIDAÇÃO:")
        for p in report["problemas"]:
            print(" -", p)
        sys.exit(5)
    print("Validação OK:", {k: v for k, v in report.get("animacoes", {}).items() if "tecnico" in k})


if __name__ == "__main__":
    main()
