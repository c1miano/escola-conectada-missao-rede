class_name BigButton
extends Button
## Botão do jogo com ícone desenhado + texto. Variantes: primary, secondary, success, star.
## Os tamanhos pedidos pelas telas são reduzidos pela escala de interface (Game.ui_scale()),
## então "Texto grande" deixa todos os botões maiores de uma vez.

var icon_kind := ""
var variant := "primary"
var _icon_size := 9.0


func _init(p_text: String = "", p_icon: String = "", p_variant: String = "primary", min_h: float = 70.0) -> void:
	text = p_text
	icon_kind = p_icon
	variant = p_variant
	var k := Game.ui_scale()
	custom_minimum_size = Vector2(0, maxf(30.0, round(min_h * k * 0.62)))
	_icon_size = round(9.0 * k / 0.7)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(func(): Sfx.play("click"))


func _ready() -> void:
	# larguras mínimas pedidas pelas telas também seguem a escala
	if custom_minimum_size.x > 0 and not has_meta("scaled"):
		custom_minimum_size.x = round(custom_minimum_size.x * Game.ui_scale() * 0.85)
		set_meta("scaled", true)
	_apply_variant()


func set_variant(v: String) -> void:
	variant = v
	_apply_variant()
	queue_redraw()


func _style(bg: Color, border: Color, pressed_look: bool = false) -> StyleBoxFlat:
	var s := preload("res://scripts/ui/theme_builder.gd").button_box(bg, border, pressed_look)
	s.content_margin_left = 12 + (_icon_size * 2.0 + 8.0 if icon_kind != "" else 0.0)
	return s


func _apply_variant() -> void:
	var bg := Palette.PRIMARY
	var hover := Palette.PRIMARY_HOVER
	var border := Palette.FRAME_DARK
	var fg := Palette.TEXT_LIGHT
	match variant:
		"secondary":
			bg = Color("#ecebe4")
			hover = Color("#ffffff")
			fg = Palette.TEXT
		"success":
			bg = Color("#3f9c4e")
			hover = Color("#4cb35c")
		"star":
			bg = Palette.STAR
			hover = Color("#ffd24d")
			fg = Palette.TEXT
	add_theme_stylebox_override("normal", _style(bg, border))
	add_theme_stylebox_override("hover", _style(hover, border))
	add_theme_stylebox_override("pressed", _style(bg.darkened(0.15), border, true))
	add_theme_stylebox_override("disabled", _style(Color("#c9cdd6"), Color("#8e96a6")))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(c, fg)


func _draw() -> void:
	if icon_kind == "":
		return
	var col: Color = get_theme_color("font_color")
	if disabled:
		col = Color("#4a5566")
	Icons.draw(self, icon_kind, Vector2(10 + _icon_size, size.y / 2.0), _icon_size, col)
