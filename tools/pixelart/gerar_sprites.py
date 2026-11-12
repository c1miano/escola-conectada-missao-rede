#!/usr/bin/env python3
"""Gera a pixel art do jogo (estilo top-down, grade de 16x16).

Técnicas seguidas (guia "pixel-art-professional"):
- paleta limitada e única para o jogo todo, com rampas de cor e hue shifting
  (sombras puxam para azul/roxo, luzes para amarelo);
- contorno escuro colorido (nunca preto puro), luz vindo de cima/esquerda;
- sem antialiasing (sprites pequenos), escala sempre inteira no Godot (filtro nearest).

Uso:  python3 tools/pixelart/gerar_sprites.py
Saída: assets/sprites/*.png (1 pixel = 1 pixel; o jogo amplia 3x ou 4x).
Os PNGs podem ser abertos e retocados no Aseprite.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites"

# ------------------------------------------------------------------ paleta
PAL = {
    ".": None,
    "k": "#1e1b33",  # contorno (azul-arroxeado escuro)
    "d": "#3d3f5c", "g": "#6c708f", "G": "#a3a7c2", "w": "#d8dbea", "W": "#f6f6fc",
    "B": "#1f4f99", "b": "#2f7ad6", "c": "#6cc3f5", "C": "#c4ecff",
    "s": "#183a5e",  # tela desligada
    "E": "#1d6b45", "e": "#2fb86a", "f": "#9be38f",
    "Y": "#b86f12", "y": "#f5b82e", "L": "#ffe58a",
    "R": "#8c2a3a", "r": "#d9484f", "P": "#f29aa0",
    "N": "#5c3424", "n": "#8f5634", "l": "#c4844f", "h": "#e2ad72",
    "o": "#d6a77c", "O": "#c38f68", "m": "#a8705e",  # piso de tijolos
    "v": "#e7e6f8", "V": "#c9c9ea", "a": "#5a78c2", "A": "#2d3b70",  # parede e moldura
    "p": "#f2c29b", "q": "#c98a6a", "H": "#4a2a1a",  # pele e cabelo
    "t": "#2a9d8f", "T": "#1d6f66", "j": "#3a4f86", "J": "#26355e",  # roupa
    "u": "#8e6cc9", "U": "#5b3f8f",
    "x": "#7a7f99",  # LED (trocado por verde quando ligado)
    "z": "#9fd3e8", "Z": "#5fa3c4",  # piso frio (servidores)
}


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def from_rows(rows, swap=None):
    swap = swap or {}
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row.ljust(w, ".")):
            ch = swap.get(ch, ch)
            col = PAL.get(ch)
            if col is None and ch != ".":
                raise ValueError(f"cor desconhecida {ch!r}")
            if col:
                img.putpixel((x, y), hexrgb(col))
    return img


class Canvas:
    """Desenho por primitivas (para móveis e tiles regulares)."""

    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def px(self, x, y, c):
        if 0 <= x < self.img.width and 0 <= y < self.img.height:
            self.img.putpixel((x, y), hexrgb(PAL[c]))

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.px(xx, yy, c)

    def box(self, x, y, w, h, fill, line="k"):
        self.rect(x, y, w, h, line)
        self.rect(x + 1, y + 1, w - 2, h - 2, fill)

    def hline(self, x, y, w, c):
        self.rect(x, y, w, 1, c)

    def vline(self, x, y, h, c):
        self.rect(x, y, 1, h, c)

    def paste(self, other, x, y):
        self.img.alpha_composite(other, (x, y))


def save(name, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png")


# ------------------------------------------------------------------ tiles
def floor_brick():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "o")
    for band in range(4):
        y = band * 4
        c.hline(0, y + 3, 16, "m")
        off = 0 if band % 2 == 0 else 4
        for x in (off, off + 8):
            c.vline(x % 16, y, 3, "m")
        c.px((off + 2) % 16, y + 1, "h")      # brilho
        c.px((off + 6) % 16, y + 2, "O")      # sombra
    return c.img


def floor_tile_cold():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "z")
    c.hline(0, 15, 16, "Z")
    c.vline(15, 0, 16, "Z")
    c.px(2, 2, "C")
    c.px(3, 2, "C")
    c.px(2, 3, "C")
    return c.img


def floor_wood():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "l")
    for y in (3, 7, 11, 15):
        c.hline(0, y, 16, "n")
    for i, y in enumerate((0, 4, 8, 12)):
        c.vline((5 + i * 6) % 16, y, 3, "n")
        c.px((2 + i * 5) % 16, y + 1, "h")
    return c.img


def floor_corridor():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "w")
    c.rect(0, 0, 8, 8, "G")
    c.rect(8, 8, 8, 8, "G")
    c.px(1, 1, "w")
    c.px(9, 9, "w")
    return c.img


def wall():
    """Parede vista de frente (16x32): moldura no alto, rodapé embaixo."""
    c = Canvas(16, 32)
    c.rect(0, 0, 16, 32, "v")
    c.rect(0, 0, 16, 3, "a")
    c.hline(0, 3, 16, "A")
    c.rect(0, 28, 16, 3, "V")
    c.hline(0, 31, 16, "A")
    c.px(4, 12, "W")
    return c.img


def frame_tile():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "a")
    c.hline(0, 15, 16, "A")
    c.hline(0, 0, 16, "c")
    return c.img


# ------------------------------------------------------------------ decoração de parede
def blackboard():
    c = Canvas(32, 18)
    c.box(0, 0, 32, 16, "E", "N")
    c.rect(1, 1, 30, 14, "n")
    c.rect(2, 2, 28, 12, "E")
    # desenho de rede em giz
    for x, y in ((6, 5), (14, 5), (22, 5)):
        c.rect(x, y, 3, 2, "W")
    c.rect(13, 10, 5, 2, "W")
    for x in (7, 15, 23):
        c.vline(x, 7, 2, "f")
    c.hline(7, 9, 17, "f")
    c.vline(15, 9, 1, "f")
    c.rect(27, 12, 2, 1, "W")
    c.rect(1, 16, 30, 2, "N")
    return c.img


def clock():
    return from_rows([
        "..kkkk..",
        ".kWWWWk.",
        "kWWkWWWk",
        "kWWkWWWk",
        "kWWkkkWk",
        "kWWWWWWk",
        ".kWWWWk.",
        "..kkkk..",
    ])


def window():
    c = Canvas(16, 16)
    c.box(0, 0, 16, 14, "c", "a")
    c.rect(1, 1, 14, 12, "c")
    c.vline(7, 1, 12, "a")
    c.hline(1, 6, 14, "a")
    c.px(2, 2, "C"); c.px(3, 2, "C"); c.px(2, 3, "C")
    c.px(9, 8, "C"); c.px(10, 8, "C")
    c.rect(0, 14, 16, 2, "A")
    return c.img


def poster_net():
    return from_rows([
        "kkkkkkkkkk",
        "kLLLLLLLLk",
        "kLbLLLLbLk",
        "kLLkLLkLLk",
        "kLLLyyLLLk",
        "kLLLyyLLLk",
        "kLLkLLkLLk",
        "kLbLLLLbLk",
        "kLLLLLLLLk",
        "kLggggggLk",
        "kLLLLLLLLk",
        "kkkkkkkkkk",
    ])


def poster_wifi():
    return from_rows([
        "kkkkkkkkkk",
        "kCCCCCCCCk",
        "kCCbbbbCCk",
        "kCbCCCCbCk",
        "kCCCbbCCCk",
        "kCCbCCbCCk",
        "kCCCCCCCCk",
        "kCCCbbCCCk",
        "kCCCCCCCCk",
        "kCggggggCk",
        "kCCCCCCCCk",
        "kkkkkkkkkk",
    ])


def note():
    return from_rows([
        "LLLLLLL.",
        "LyyyyyLL",
        "LLLLLLLL",
        "LyyyyLLL",
        "LLLLLLLL",
        "LyyyyyLL",
        "LLLLLLLL",
        ".LLLLLL.",
    ])


def extinguisher():
    return from_rows([
        "..kk....",
        ".kddkk..",
        "..kk.k..",
        ".krrk...",
        "krrPrk..",
        "krrrrk..",
        "kWWWWk..",
        "krrrrk..",
        "krrrrk..",
        "kRrrRk..",
        ".kkkk...",
    ])


# ------------------------------------------------------------------ móveis
def desk():
    """Mesa vista de cima/frente (32x16)."""
    c = Canvas(32, 16)
    c.box(1, 0, 30, 11, "l")
    c.hline(2, 1, 28, "h")
    for x in (6, 15, 24):
        c.hline(x, 4, 4, "n")
    c.rect(2, 8, 28, 2, "n")
    c.hline(1, 10, 30, "k")
    for x in (2, 27):
        c.rect(x, 11, 3, 4, "k")
        c.rect(x + 1, 11, 1, 3, "N")
    return c.img


def small_desk():
    c = Canvas(16, 16)
    c.box(1, 2, 14, 8, "l")
    c.hline(2, 3, 12, "h")
    c.rect(2, 7, 12, 2, "n")
    c.rect(2, 10, 2, 4, "k")
    c.rect(12, 10, 2, 4, "k")
    return c.img


def chair():
    return from_rows([
        "................",
        ".....kkkkkk.....",
        "....knnnnnnk....",
        "....knllllnk....",
        "....knnnnnnk....",
        "....kkkkkkkk....",
        "....khhhhhhk....",
        "....kllllllk....",
        "....kkkkkkkk....",
        "....kN....Nk....",
        "....kk....kk....",
    ] + ["................"] * 5)


def bookshelf():
    c = Canvas(16, 32)
    c.box(0, 0, 16, 32, "n", "k")
    c.rect(1, 1, 14, 1, "l")
    colors = ["r", "b", "e", "y", "u", "R", "c", "Y"]
    for shelf in range(4):
        y = 2 + shelf * 7
        c.rect(1, y + 6, 14, 1, "N")
        x = 2
        i = shelf
        while x < 14:
            w = 2 if (x + shelf) % 3 else 1
            h = 5 if (x + i) % 4 else 4
            col = colors[(x + shelf * 3) % len(colors)]
            c.rect(x, y + 6 - h, w, h, col)
            x += w + (1 if (x + shelf) % 5 == 0 else 0)
    return c.img


def locker():
    c = Canvas(16, 32)
    c.box(0, 0, 16, 32, "b", "k")
    c.hline(1, 1, 14, "c")
    c.vline(7, 1, 30, "B")
    for x in (2, 9):
        for y in (4, 6, 8):
            c.hline(x, y, 4, "B")
        c.rect(x + 3, 15, 1, 3, "W")
    c.hline(1, 30, 14, "B")
    return c.img


def file_cabinet():
    c = Canvas(16, 24)
    c.box(1, 0, 14, 24, "G", "k")
    for y in (2, 9, 16):
        c.box(2, y, 12, 6, "w", "g")
        c.hline(6, y + 2, 4, "d")
    return c.img


def plant():
    return from_rows([
        ".......kk.......",
        "....kk.kek.kk...",
        "...kefkkeekfek..",
        "...keefkekfeek..",
        "....keeekeeek...",
        "..kkkeeeEeekkk..",
        ".kfeeekEEeeefk..",
        ".kkeeeEeEeeekk..",
        "...kkeeEeekk....",
        ".....kkkkk......",
        "....krrrrrk.....",
        "....kRrrrRk.....",
        ".....kRrRk......",
        ".....kRRRk......",
        "......kkk.......",
        "................",
    ])


def rack():
    """Rack de servidores (16x32) para decorar a sala de servidores."""
    c = Canvas(16, 32)
    c.box(0, 0, 16, 32, "d", "k")
    for i in range(6):
        y = 2 + i * 5
        c.box(1, y, 14, 4, "g", "k")
        c.hline(3, y + 1, 6, "d")
        c.px(11, y + 1, "e")
        c.px(13, y + 1, "y" if i % 2 else "e")
    return c.img


def door():
    c = Canvas(16, 24)
    c.box(0, 0, 16, 24, "n", "k")
    c.box(2, 2, 12, 9, "c", "N")
    c.box(2, 12, 12, 10, "l", "N")
    c.rect(11, 14, 2, 2, "y")
    return c.img


# ------------------------------------------------------------------ equipamentos
def monitor():
    return [
        "................",
        ".kkkkkkkkkkkkkk.",
        ".kddddddddddddk.",
        ".kdssssssssssdk.",
        ".kdsCssssssssdk.",
        ".kdssssssssssdk.",
        ".kdssssssssssdk.",
        ".kdssssssssssdk.",
        ".kdssssssssssdk.",
        ".kdddddddddxddk.",
        ".kkkkkkkkkkkkkk.",
        "......kggk......",
        "......kggk......",
        "....kkggggkk....",
        "....kddddddk....",
        "....kkkkkkkk....",
    ]


def lit(rows, screen="c"):
    """Versão ligada: tela acesa com linhas de texto e LED verde."""
    out = []
    for y, r in enumerate(rows):
        r = r.replace("s", screen).replace("x", "e")
        out.append(r)
    return out


def on_desk(top_rows, top_x=8, top_y=0, w=32, h=26):
    c = Canvas(w, h)
    c.paste(desk(), 0, h - 16)
    c.paste(from_rows(top_rows), top_x, top_y)
    return c.img


def keyboard_overlay(img):
    c = Canvas(img.width, img.height)
    c.paste(img, 0, 0)
    c.box(19, 16, 10, 4, "w", "k")
    c.hline(20, 17, 8, "G")
    return c.img


def pc(on):
    rows = monitor()
    if on:
        rows = lit(rows)
        rows[4] = ".kdcCCCCCcccdk."[:15] + "."
        rows[4] = ".kdcCCCCCCcccdk."
        rows[6] = ".kdcCCCCcccccdk."
        rows[8] = ".kdcCCCcccccccdk."[:16]
    return keyboard_overlay(on_desk(rows, top_x=4))


def notebook(on):
    rows = [
        "................",
        "................",
        "..kkkkkkkkkkkk..",
        "..kddddddddddk..",
        "..kdssssssssdk..",
        "..kdsCssssssdk..",
        "..kdssssssssdk..",
        "..kdssssssssdk..",
        "..kdssssssssdk..",
        "..kddddddddddk..",
        ".kkkkkkkkkkkkkk.",
        ".kGGGGGGGGGGGGk.",
        ".kGwGwGwGwGwxGk.",
        ".kGGGGGGGGGGGGk.",
        "..kkkkkkkkkkkk..",
        "................",
    ]
    if on:
        rows = lit(rows)
    return on_desk(rows, top_x=8, top_y=2)


def server(on):
    c = Canvas(32, 26)
    c.box(8, 0, 16, 26, "d", "k")
    c.hline(9, 1, 14, "g")
    for i in range(5):
        y = 3 + i * 4
        c.box(9, y, 14, 4, "g", "k")
        c.hline(11, y + 1, 5, "d")
        c.px(19, y + 1, "e" if on else "x")
        c.px(21, y + 1, ("y" if i % 2 else "e") if on else "x")
    c.rect(9, 23, 14, 2, "d")
    return c.img


def switch_img(on):
    c = Canvas(64, 16)
    c.box(0, 3, 64, 11, "d", "k")
    c.hline(1, 4, 62, "g")
    for i in range(8):
        x = 18 + i * 5
        c.box(x, 7, 4, 4, "k", "k")
        c.px(x + 1, 8, "G")
        c.px(x + 2, 5, "e" if on else "x")
    c.rect(3, 6, 10, 2, "G")
    c.rect(3, 9, 7, 1, "G")
    return c.img


def access_point(on):
    rows = [
        "................",
        "..k..........k..",
        "..kk........kk..",
        "...kk......kk...",
        "....k......k....",
        "....k......k....",
        "....k......k....",
        "..kkkkkkkkkkkk..",
        ".kWWWWWWWWWWWWk.",
        ".kWWWWWWWWWWWWk.",
        ".kwwwwwxwwwwwwk.",
        ".kkkkkkkkkkkkkk.",
        "................",
        "................",
        "................",
        "................",
    ]
    if on:
        rows = [r.replace("x", "e") for r in rows]
        rows[0] = "......bbbb......"
        rows[1] = "..k..b....b..k.."
        rows[3] = "...kk.bbbb.kk..."
    c = Canvas(32, 26)
    c.paste(small_desk(), 8, 10)
    c.paste(from_rows(rows), 8, 0)
    return c.img


def printer():
    rows = [
        "................",
        "....kkkkkkkk....",
        "....kWWWWWWk....",
        "....kWggggWk....",
        "..kkkkkkkkkkkk..",
        ".kGGGGGGGGGGGGk.",
        ".kGGGGGGGGGeGGk.",
        ".kddddddddddddk.",
        ".kdkkkkkkkkkkdk.",
        ".kddddddddddddk.",
        "..kkkkkkkkkkkk..",
    ]
    return on_desk(rows, top_x=8, top_y=2)


def panel(on):
    rows = [
        "........................",
        ".kkkkkkkkkkkkkkkkkkkkkk.",
        ".kddddddddddddddddddddk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdssssssssssssssssssdk.",
        ".kdddddddddddddddddxddk.",
        ".kkkkkkkkkkkkkkkkkkkkkk.",
        "..........kggk..........",
        "........kkggggkk........",
        "........kddddddk........",
        "........kkkkkkkk........",
    ]
    if on:
        rows = [r.replace("x", "e") for r in rows]
        rows = [r.replace("s", "B") for r in rows]
        graph = [(3, 9), (5, 8), (7, 8), (9, 6), (11, 7), (13, 5), (15, 4), (17, 5), (19, 3)]
        rows = [list(r) for r in rows]
        for x, y in graph:
            rows[y][x] = "c"
            rows[y][x + 1] = "c"
        rows = ["".join(r) for r in rows]
    return on_desk(rows, top_x=4, top_y=0)


def thermometer():
    rows = [
        "......kkkk......",
        ".....kWWWWk.....",
        ".....kWrrWk.....",
        ".....kWrrWk..k..",
        ".....kWrrWk.....",
        ".....kWrrWk..k..",
        ".....kWrrWk.....",
        ".....kWrrWk..k..",
        "....kkrrrrkk....",
        "...krrrPrrrrk...",
        "...krrPPrrrrk...",
        "...krrrrrrrRk...",
        "....kRrrrrRk....",
        ".....kkkkkk.....",
        "................",
        "................",
    ]
    c = Canvas(32, 26)
    c.paste(small_desk(), 8, 10)
    c.paste(from_rows(rows), 8, 0)
    return c.img


def lamp(on):
    rows = [
        ".....kkkkkk.....",
        "....kWWWWWWk....",
        "...kWWWWWWWWk...",
        "...kWWWWWWWWk...",
        "...kWWWWWWWWk...",
        "....kWWWWWWk....",
        ".....kWWWWk.....",
        "......kggk......",
        ".....kggggk.....",
        ".....kddddk.....",
        "......kkkk......",
    ]
    if on:
        rows = [r.replace("W", "L") for r in rows]
        rows[2] = "...kLLWWLLLLk..."
    c = Canvas(32, 26)
    if on:
        glow = Canvas(32, 26)
        for y in range(0, 14):
            for x in range(4, 28):
                dx, dy = x - 16, y - 6
                if dx * dx + dy * dy * 2 < 130 and (x + y) % 2 == 0:
                    glow.px(x, y, "L")
        c.paste(glow.img, 0, 0)
    c.paste(small_desk(), 8, 10)
    c.paste(from_rows(rows), 8, 0)
    return c.img


def presence(on):
    rows = [
        "................",
        "................",
        "....kkkkkkkk....",
        "...kWWWWWWWWk...",
        "..kWWkkkkkkWWk..",
        "..kWkrrrrrrkWk..",
        "..kWkrPrrrrkWk..",
        "..kWWkkkkkkWWk..",
        "...kWWWWWWWWk...",
        "....kkkkkkkk....",
    ]
    if not on:
        rows = [r.replace("r", "d").replace("P", "g") for r in rows]
    c = Canvas(32, 26)
    c.paste(small_desk(), 8, 10)
    c.paste(from_rows(rows), 8, 0)
    return c.img


# ------------------------------------------------------------------ personagens
BIT = [
    ".......yy.......",
    ".......kk.......",
    "...kkkkkkkkkk...",
    "..kccbbbbbbbbk..",
    "..kbkkkkkkkkbk..",
    "..kbkCCkkCCkbk..",
    "..kbkCCkkCCkbk..",
    "..kbkkkkkkkkbk..",
    "..kbkkCCCCkkbk..",
    "..kBbbbbbbbbBk..",
    "...kkkkkkkkkk...",
    "....kbbyybbk....",
    "...kbkbbbbkbk...",
    "...kk.kBBk.kk...",
    "......kBBk......",
    ".....kkk.kkk....",
]


def bit(mood):
    rows = list(BIT)
    if mood == "feliz":
        rows[5] = "..kbkCkkkkCkbk.."
        rows[6] = "..kbCkCkkCkCbk.."
        rows[8] = "..kbkCkkkkCkbk.."
        rows[7] = "..kbkkkkkkkkbk.."
        rows[8] = "..kbkCCCCCCkbk.."
    elif mood == "pensando":
        rows[5] = "..kbkkkkkkkkbk.."
        rows[6] = "..kbkCCkkCCkbk.."
        rows[8] = "..kbkkkCCCkkbk.."
    return from_rows(rows)


# Técnico de informática (camiseta azul-petróleo, crachá amarelo)
TECH_DOWN = [
    "................",
    ".....kkkkkk.....",
    "....kHHHHHHk....",
    "...kHHHHHHHHk...",
    "...kHpppppHHk...",
    "...kppkppkppk...",
    "...kppppppppk...",
    "....kpqqqqpk....",
    "....kkttttkk....",
    "...kTttttttTk...",
    "..kpkttttyyTpk..",
    "..kqkttttttkqk..",
    "....kjjjjjjk....",
    "....kjjkkjjk....",
    "....kJJk.kJJk...",
    "....kkk...kkk...",
]
TECH_UP = [
    "................",
    ".....kkkkkk.....",
    "....kHHHHHHk....",
    "...kHHHHHHHHk...",
    "...kHHHHHHHHk...",
    "...kHHHHHHHHk...",
    "...kqHHHHHHqk...",
    "....kqqqqqqk....",
    "....kkttttkk....",
    "...kTttttttTk...",
    "..kpkttttttTpk..",
    "..kqkTTTTTTkqk..",
    "....kjjjjjjk....",
    "....kjjkkjjk....",
    "....kJJk.kJJk...",
    "....kkk...kkk...",
]
TECH_LEFT = [
    "................",
    ".....kkkkkk.....",
    "....kHHHHHHk....",
    "...kHHHHHHHHk...",
    "...kpHHHHHHHk...",
    "...kkpkpHHHHk...",
    "...kppppHHHk....",
    "....kqqpppk.....",
    ".....kkttkk.....",
    "....kttttTk.....",
    "....ktpttTk.....",
    "....kqkttTk.....",
    ".....kjjjk......",
    ".....kjjjk......",
    ".....kJJJk......",
    ".....kkkk.......",
]


def walk_frame(rows, step):
    """Segundo quadro da caminhada: pernas alternadas."""
    rows = list(rows)
    if rows is TECH_LEFT or rows[14].startswith(".....kJJJk"):
        rows[13] = "....kjjkjjk....."
        rows[14] = "...kJJk.kJJk...."
        rows[15] = "...kkk...kkk...."
    else:
        rows[13] = "....kjjkkjjk...." if step else rows[13]
        rows[14] = "....kJJk.kkk...."
        rows[15] = "....kkk.........".ljust(16, ".")
    return rows


def mirror(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def person():
    rows = [r.replace("t", "u").replace("T", "U").replace("H", "Y").replace("y", "u") for r in TECH_DOWN]
    return from_rows(rows)


# ------------------------------------------------------------------ gerar tudo
def main():
    sprites = {
        "piso_tijolo": floor_brick(),
        "piso_madeira": floor_wood(),
        "piso_frio": floor_tile_cold(),
        "piso_corredor": floor_corridor(),
        "parede": wall(),
        "moldura": frame_tile(),
        "quadro": blackboard(),
        "relogio": clock(),
        "janela": window(),
        "cartaz_rede": poster_net(),
        "cartaz_wifi": poster_wifi(),
        "bilhete": note(),
        "extintor": extinguisher(),
        "mesa": desk(),
        "mesinha": small_desk(),
        "cadeira": chair(),
        "estante": bookshelf(),
        "armario": locker(),
        "arquivo": file_cabinet(),
        "planta": plant(),
        "rack": rack(),
        "porta": door(),
        "impressora": printer(),
        "sensor_temp": thermometer(),
        "bit": bit("normal"),
        "bit_feliz": bit("feliz"),
        "bit_pensando": bit("pensando"),
        "visitante": person(),
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
    for name, rows in (("baixo", TECH_DOWN), ("cima", TECH_UP), ("esquerda", TECH_LEFT)):
        sprites[f"tecnico_{name}_0"] = from_rows(rows)
        sprites[f"tecnico_{name}_1"] = from_rows(walk_frame(rows, 1))
    sprites["tecnico_direita_0"] = mirror(sprites["tecnico_esquerda_0"])
    sprites["tecnico_direita_1"] = mirror(sprites["tecnico_esquerda_1"])
    for name, img in sprites.items():
        save(name, img)
    # folha de contato para conferência rápida (não usada no jogo)
    preview = Image.new("RGBA", (8 * 70, ((len(sprites) + 7) // 8) * 70), hexrgb("#ffffff"))
    for i, (name, img) in enumerate(sprites.items()):
        big = img.resize((img.width * 2, img.height * 2), Image.NEAREST)
        preview.alpha_composite(big, ((i % 8) * 70 + 2, (i // 8) * 70 + 2))
    preview.save(ROOT / "tools" / "pixelart" / "previa.png")
    print(f"{len(sprites)} sprites gerados em {OUT}")


if __name__ == "__main__":
    main()
