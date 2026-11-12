class_name DeviceView
extends VBoxContainer
## Equipamento clicável: desenho + nome + informação (ex.: IP).
## Estado ligado/desligado aparece com luz E com símbolo (não só cor).

signal clicked(device: DeviceView)

var kind := "pc"
var device_id := ""
var online := false:
	set(v):
		online = v
		_redraw()
var show_led := true
var selected := false:
	set(v):
		selected = v
		_redraw()
var highlighted := false:
	set(v):
		highlighted = v
		set_process(true)
		_redraw()
var dimmed := false:
	set(v):
		dimmed = v
		modulate.a = 0.45 if v else 1.0
var value_text := ""       # texto desenhado no próprio aparelho (ex.: "31 °C")
var lamp_on := false:
	set(v):
		lamp_on = v
		_redraw()
var screen_text := ""

var art: Control
var name_label: Label
var info_label: Label
var _t := 0.0


func _init(p_kind: String = "pc", p_title: String = "", p_info: String = "", p_id: String = "") -> void:
	kind = p_kind
	device_id = p_id if p_id != "" else p_title
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 2)
	art = Control.new()
	art.custom_minimum_size = Vector2(130, 92) if kind != "switch" else Vector2(210, 52)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_art)
	add_child(art)
	name_label = Label.new()
	name_label.text = p_title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_stylebox_override("normal", _label_box(Color(1, 1, 1, 0.92)))
	add_child(name_label)
	info_label = Label.new()
	info_label.text = p_info
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Palette.TEXT)
	info_label.add_theme_stylebox_override("normal", _label_box(Color("#fff3c4")))
	info_label.visible = p_info != ""
	add_child(info_label)
	set_process(false)


func _label_box(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Palette.FRAME_DARK
	sb.set_border_width_all(2)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	return sb


func set_info(t: String) -> void:
	info_label.text = t
	info_label.visible = t != ""


func set_title(t: String) -> void:
	name_label.text = t


## Ponto onde os cabos se ligam (centro do desenho).
func anchor() -> Vector2:
	return art.get_global_rect().get_center()


func _redraw() -> void:
	if art:
		art.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if highlighted:
		art.queue_redraw()
	else:
		set_process(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit(self)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		clicked.emit(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		_redraw()


# ------------------------------------------------------------------ desenho (pixel art)
const SPRITE := {
	"pc": "pc", "notebook": "notebook", "server": "servidor", "switch": "switch",
	"ap": "ap", "panel": "painel", "lamp": "lampada", "sensor_pres": "sensor_pres",
	"sensor_temp": "sensor_temp", "printer": "impressora", "router": "ap",
}
const HAS_STATE := ["pc", "notebook", "server", "switch", "ap", "panel", "sensor_pres", "router"]


func sprite_name() -> String:
	var base: String = SPRITE.get(kind, "pc")
	if kind == "lamp":
		return base + ("_on" if lamp_on else "_off")
	if kind in HAS_STATE:
		return base + ("_on" if online else "_off")
	return base


func _draw_art() -> void:
	var r := Rect2(Vector2.ZERO, art.size)
	var c := r.get_center()
	var sz := Sprites.size_of(sprite_name())
	var origin := (c - sz / 2.0).round()
	var sprite_rect := Rect2(origin, sz)
	# sombra no chão
	art.draw_rect(Rect2(origin + Vector2(6, sz.y - 6), Vector2(sz.x - 12, 6)), Color(0.1, 0.1, 0.25, 0.25))
	if highlighted:
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		var hr := sprite_rect.grow(6 + round(pulse * 4))
		art.draw_rect(hr, Color(Palette.FOCUS, 0.22 + 0.25 * pulse), true)
		art.draw_rect(hr, Palette.FOCUS, false, 4)
		var top := Vector2(c.x, hr.position.y - 8 - round(pulse * 6))
		art.draw_colored_polygon(PackedVector2Array([top + Vector2(-15, -18), top + Vector2(15, -18), top + Vector2(0, 0)]), Palette.FOCUS)
		art.draw_polyline(PackedVector2Array([top + Vector2(-15, -18), top + Vector2(15, -18), top + Vector2(0, 0), top + Vector2(-15, -18)]), Palette.FRAME_DARK, 3)
	if selected:
		art.draw_rect(sprite_rect.grow(5), Color(Palette.FOCUS, 0.18), true)
		art.draw_rect(sprite_rect.grow(5), Palette.FOCUS, false, 5)
	elif has_focus():
		art.draw_rect(sprite_rect.grow(4), Palette.FOCUS, false, 3)
	Sprites.draw(art, sprite_name(), origin)
	if selected:
		# selo "selecionado": quadrado com check (não depende só da cor)
		var b := sprite_rect.position + Vector2(sprite_rect.size.x - 4, -4)
		art.draw_rect(Rect2(b - Vector2(14, 14), Vector2(28, 28)), Palette.FOCUS)
		art.draw_rect(Rect2(b - Vector2(14, 14), Vector2(28, 28)), Palette.FRAME_DARK, false, 3)
		Icons.draw(art, "check", b, 10, Color.WHITE)
	if screen_text != "":
		var sc := Vector2(12, 5) * Sprites.SCALE if kind == "pc" else Vector2(16, 6) * Sprites.SCALE
		_tag(origin + sc, screen_text)
	if value_text != "":
		_tag(origin + Vector2(sz.x - 6, 18), value_text)
	if show_led and kind != "switch":
		_led(Vector2(sprite_rect.end.x + 2, sprite_rect.end.y - 18))


func _tag(center: Vector2, s: String) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var box := Rect2(center - Vector2(w / 2.0 + 5, 12), Vector2(w + 10, 24)).abs()
	art.draw_rect(box, Color.WHITE)
	art.draw_rect(box, Palette.FRAME_DARK, false, 2)
	art.draw_string(font, box.position + Vector2(5, 18), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.TEXT)


## Indicador de estado: quadrado verde com check (ligado) ou cinza com traço (desligado).
func _led(p: Vector2) -> void:
	var box := Rect2(p - Vector2(12, 12), Vector2(24, 24))
	art.draw_rect(box, Palette.LED_ON if online else Color("#dddddd"))
	art.draw_rect(box, Palette.FRAME_DARK, false, 3)
	if online:
		Icons.draw(art, "check", p, 8, Color.WHITE)
	else:
		art.draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), Palette.LED_OFF, 3)
