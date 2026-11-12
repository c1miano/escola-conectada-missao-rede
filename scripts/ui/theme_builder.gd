extends RefCounted
## Tema com botões grandes, cantos arredondados e foco bem visível (navegação por teclado).


static func _box(bg: Color, border: Color, bw: int = 3, radius: int = 14, margin: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin + 6
	s.content_margin_right = margin + 6
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	s.anti_aliasing = true
	return s


static func build(large_text: bool) -> Theme:
	var t := Theme.new()
	var base := 26 if large_text else 22
	t.default_font_size = base

	# Botões
	t.set_stylebox("normal", "Button", _box(Palette.PRIMARY, Palette.PRIMARY_DARK))
	t.set_stylebox("hover", "Button", _box(Palette.PRIMARY_HOVER, Palette.PRIMARY_DARK))
	t.set_stylebox("pressed", "Button", _box(Palette.PRIMARY_DARK, Palette.PRIMARY_DARK))
	t.set_stylebox("disabled", "Button", _box(Color("#b8c2cf"), Color("#9aa5b4")))
	var focus := _box(Color(0, 0, 0, 0), Palette.FOCUS, 5, 16)
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Palette.TEXT_LIGHT)
	t.set_color("font_disabled_color", "Button", Color("#4a5566"))
	t.set_font_size("font_size", "Button", base + 2)

	# Painéis
	t.set_stylebox("panel", "PanelContainer", _box(Palette.PANEL, Palette.PANEL_BORDER, 3, 18, 14))
	t.set_stylebox("panel", "Panel", _box(Palette.PANEL, Palette.PANEL_BORDER, 3, 18, 14))

	# Textos
	t.set_color("font_color", "Label", Palette.TEXT)
	t.set_font_size("font_size", "Label", base)
	t.set_color("default_color", "RichTextLabel", Palette.TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", base)
	t.set_font_size("bold_font_size", "RichTextLabel", base)

	# Campo de texto
	t.set_stylebox("normal", "LineEdit", _box(Color.WHITE, Palette.PANEL_BORDER, 3, 10, 10))
	t.set_stylebox("focus", "LineEdit", _box(Color.WHITE, Palette.FOCUS, 4, 10, 10))
	t.set_color("font_color", "LineEdit", Palette.TEXT)
	t.set_font_size("font_size", "LineEdit", base)
	t.set_color("font_placeholder_color", "LineEdit", Color("#6b7789"))

	# Rolagem mais grossa (fácil de pegar com o mouse)
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 14)
	return t
