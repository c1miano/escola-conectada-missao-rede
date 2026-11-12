class_name BigButton
extends Button
## Botão grande com ícone desenhado + texto. Variantes: primary, secondary, success.

var icon_kind := ""
var variant := "primary"
var _icon_size := 22.0


func _init(p_text: String = "", p_icon: String = "", p_variant: String = "primary", min_h: float = 70.0) -> void:
	text = p_text
	icon_kind = p_icon
	variant = p_variant
	custom_minimum_size = Vector2(0, min_h)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# sem quebra automática: o botão cresce para caber o texto
	pressed.connect(func(): Sfx.play("click"))


func _ready() -> void:
	_apply_variant()


func set_variant(v: String) -> void:
	variant = v
	_apply_variant()
	queue_redraw()


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(4)
	s.border_width_bottom = 8
	s.set_corner_radius_all(3)
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.content_margin_right = 20
	s.content_margin_left = 20 + (_icon_size * 2.0 + 10.0 if icon_kind != "" else 0.0)
	s.anti_aliasing = false
	return s


func _apply_variant() -> void:
	var bg := Palette.PRIMARY
	var hover := Palette.PRIMARY_HOVER
	var border := Palette.PRIMARY_DARK
	var fg := Palette.TEXT_LIGHT
	match variant:
		"secondary":
			bg = Palette.CREAM
			hover = Color("#fff3c4")
			border = Palette.FRAME_DARK
			fg = Palette.PRIMARY_DARK
		"success":
			bg = Palette.SUCCESS
			hover = Color("#26995a")
			border = Color("#135c31")
		"star":
			bg = Palette.STAR
			hover = Color("#ffd24d")
			border = Palette.STAR_DARK
			fg = Palette.TEXT
	add_theme_stylebox_override("normal", _style(bg, border))
	add_theme_stylebox_override("hover", _style(hover, border))
	var pressed_style := _style(bg.darkened(0.15), border)
	pressed_style.border_width_bottom = 4
	pressed_style.content_margin_top = 14
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("disabled", _style(Color("#c9d1dc"), Color("#9aa5b4")))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(c, fg)


func _draw() -> void:
	if icon_kind == "":
		return
	var col: Color = get_theme_color("font_color")
	if disabled:
		col = Color("#4a5566")
	Icons.draw(self, icon_kind, Vector2(20 + _icon_size, size.y / 2.0), _icon_size, col)
