extends RefCounted
## Tema compacto, inspirado em jogos sociais em pixel art: janelas claras com cantos levemente
## arredondados, borda escura fina, sombra curta, fonte em pixel e botões pequenos.
## O foco do teclado continua bem visível. "Texto grande" aumenta tudo (Game.ui_scale()).


static func _box(bg: Color, border: Color, bw: int = 2, radius: int = 5, mx: int = 10, my: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.anti_aliasing = false
	return s


## Botão com "degrau" embaixo (parece apertável).
static func button_box(bg: Color, border: Color, pressed: bool = false) -> StyleBoxFlat:
	var s := _box(bg, border, 2, 5, 12, 5)
	s.border_width_bottom = 2 if pressed else 4
	if pressed:
		s.content_margin_top = 7
	return s


static func panel_box() -> StyleBoxFlat:
	var s := _box(Palette.PANEL, Palette.FRAME_DARK, 2, 6, 12, 10)
	s.shadow_color = Color(0.05, 0.05, 0.15, 0.35)
	s.shadow_size = 1
	s.shadow_offset = Vector2(2, 3)
	return s


static func build(large_text: bool) -> Theme:
	var t := Theme.new()
	var base := int(round(22 * (1.25 if large_text else 0.98)))
	t.default_font = Game.ui_font
	t.default_font_size = base

	# Botões
	t.set_font("font", "Button", Game.ui_font_bold)
	t.set_stylebox("normal", "Button", button_box(Palette.PRIMARY, Palette.FRAME_DARK))
	t.set_stylebox("hover", "Button", button_box(Palette.PRIMARY_HOVER, Palette.FRAME_DARK))
	t.set_stylebox("pressed", "Button", button_box(Palette.PRIMARY_DARK, Palette.FRAME_DARK, true))
	t.set_stylebox("disabled", "Button", button_box(Color("#c9cdd6"), Color("#8e96a6")))
	var focus := _box(Color(0, 0, 0, 0), Palette.FOCUS, 3, 6)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Palette.TEXT_LIGHT)
	t.set_color("font_disabled_color", "Button", Color("#4a5566"))
	t.set_font_size("font_size", "Button", base)

	# Janelas e painéis
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())

	# Textos
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_font_size("font_size", "Label", base)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_font("normal_font", "RichTextLabel", Game.ui_font)
	t.set_font("bold_font", "RichTextLabel", Game.ui_font_bold)
	t.set_font_size("normal_font_size", "RichTextLabel", base)
	t.set_font_size("bold_font_size", "RichTextLabel", base)

	# Campo de texto
	t.set_stylebox("normal", "LineEdit", _box(Color.WHITE, Palette.FRAME_DARK, 2, 4, 8, 4))
	t.set_stylebox("focus", "LineEdit", _box(Color.WHITE, Palette.FOCUS, 3, 4, 8, 4))
	t.set_color("font_color", "LineEdit", Palette.TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color("#6b7789"))
	t.set_font_size("font_size", "LineEdit", base)

	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_font_size("font_size", "TooltipLabel", base)
	return t
