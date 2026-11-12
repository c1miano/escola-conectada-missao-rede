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
	art.custom_minimum_size = Vector2(140, 104) if kind != "switch" else Vector2(260, 70)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_art)
	add_child(art)
	name_label = Label.new()
	name_label.text = p_title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	add_child(name_label)
	info_label = Label.new()
	info_label.text = p_info
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Palette.TEXT_SOFT)
	info_label.visible = p_info != ""
	add_child(info_label)
	set_process(false)


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


# ------------------------------------------------------------------ desenho
func _draw_art() -> void:
	var r := Rect2(Vector2.ZERO, art.size)
	var c := r.get_center()
	if highlighted:
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		var hr := r.grow(6 + pulse * 6)
		art.draw_rect(hr, Color(Palette.FOCUS, 0.25 + 0.3 * pulse), true)
		art.draw_rect(hr, Palette.FOCUS, false, 4)
		# seta apontando para o equipamento
		var top := Vector2(c.x, -22 - pulse * 8)
		art.draw_colored_polygon(PackedVector2Array([top + Vector2(-16, -18), top + Vector2(16, -18), top + Vector2(0, 4)]), Palette.FOCUS)
	if selected:
		art.draw_rect(r.grow(4), Color(Palette.FOCUS, 0.18), true)
		art.draw_rect(r.grow(4), Palette.FOCUS, false, 5)
		# selo "selecionado" com símbolo de check
		art.draw_circle(r.position + Vector2(r.size.x - 4, 4), 15, Palette.FOCUS)
		Icons.draw(art, "check", r.position + Vector2(r.size.x - 4, 4), 11, Color.WHITE)
	if has_focus() and not selected:
		art.draw_rect(r.grow(3), Palette.FOCUS, false, 3)
	match kind:
		"pc": _pc(c)
		"notebook": _notebook(c)
		"server": _server(c)
		"switch": _switch(r)
		"ap": _ap(c)
		"sensor_temp": _thermo(c)
		"lamp": _lamp(c)
		"sensor_pres": _presence(c)
		"panel": _panel(c)
		"printer": _printer(c)
		"router": _ap(c)
		_: art.draw_circle(c, 30, Palette.DEVICE)
	if show_led and kind != "switch":
		_led(Vector2(r.size.x - 14, r.size.y - 12))


func _led(p: Vector2) -> void:
	if online:
		art.draw_circle(p, 11, Palette.LED_ON)
		art.draw_arc(p, 11, 0, TAU, 20, Color("#0f5c2b"), 2, true)
		Icons.draw(art, "check", p, 8, Color.WHITE)
	else:
		art.draw_circle(p, 11, Color("#dddddd"))
		art.draw_arc(p, 11, 0, TAU, 20, Palette.LED_OFF, 2, true)
		art.draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), Palette.LED_OFF, 3)


func _screen_color() -> Color:
	return Palette.SCREEN_ON if online else Palette.SCREEN


func _pc(c: Vector2) -> void:
	var mon := Rect2(c + Vector2(-50, -46), Vector2(100, 66))
	art.draw_rect(mon, Palette.DEVICE_DARK)
	art.draw_rect(mon.grow(-6), _screen_color())
	if online:
		for i in 3:
			art.draw_line(mon.position + Vector2(14, 16 + i * 12), mon.position + Vector2(60 + i * 8, 16 + i * 12), Color("#1d4f7a"), 4)
	if screen_text != "":
		_screen_label(mon, screen_text)
	art.draw_rect(Rect2(c + Vector2(-8, 20), Vector2(16, 14)), Palette.DEVICE_DARK)
	art.draw_rect(Rect2(c + Vector2(-34, 32), Vector2(68, 8)), Palette.DEVICE_DARK)


func _screen_label(rect: Rect2, s: String) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	art.draw_rect(Rect2(rect.get_center() - Vector2(w / 2 + 4, 12), Vector2(w + 8, 22)), Color(1, 1, 1, 0.9))
	art.draw_string(font, rect.get_center() + Vector2(-w / 2, 5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.TEXT)


func _notebook(c: Vector2) -> void:
	var scr := Rect2(c + Vector2(-44, -42), Vector2(88, 56))
	art.draw_rect(scr, Palette.DEVICE_DARK)
	art.draw_rect(scr.grow(-5), _screen_color())
	art.draw_colored_polygon(PackedVector2Array([c + Vector2(-56, 16), c + Vector2(56, 16), c + Vector2(64, 30), c + Vector2(-64, 30)]), Palette.DEVICE_DARK)


func _server(c: Vector2) -> void:
	var body := Rect2(c + Vector2(-34, -50), Vector2(68, 98))
	art.draw_rect(body, Palette.DEVICE_DARK)
	for i in 4:
		var y := body.position.y + 10 + i * 22
		art.draw_rect(Rect2(Vector2(body.position.x + 8, y), Vector2(52, 14)), Color("#56657e"))
		art.draw_circle(Vector2(body.position.x + 50, y + 7), 3, Palette.LED_ON if online else Palette.LED_OFF)


func _switch(r: Rect2) -> void:
	var body := Rect2(r.position + Vector2(6, 10), r.size - Vector2(12, 20))
	art.draw_rect(body, Palette.DEVICE_DARK)
	art.draw_string(ThemeDB.fallback_font, body.position + Vector2(12, body.size.y / 2 + 7), "SWITCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	for i in 6:
		art.draw_circle(body.position + Vector2(body.size.x - 14 - i * 16, 12), 4, Palette.LED_ON if online else Palette.LED_OFF)


func _ap(c: Vector2) -> void:
	var body := Rect2(c + Vector2(-46, 4), Vector2(92, 30))
	art.draw_rect(body, Color("#f4f6f8"))
	art.draw_rect(body, Palette.DEVICE_DARK, false, 3)
	art.draw_line(c + Vector2(-30, 4), c + Vector2(-38, -30), Palette.DEVICE_DARK, 5)
	art.draw_line(c + Vector2(30, 4), c + Vector2(38, -30), Palette.DEVICE_DARK, 5)
	if online:
		Icons.draw(art, "wifi", c + Vector2(0, -26), 26, Palette.CABLE)


func _thermo(c: Vector2) -> void:
	art.draw_rect(Rect2(c + Vector2(-11, -46), Vector2(22, 66)), Color.WHITE)
	art.draw_rect(Rect2(c + Vector2(-11, -46), Vector2(22, 66)), Palette.DEVICE_DARK, false, 3)
	art.draw_circle(c + Vector2(0, 28), 18, Color("#d9480f"))
	art.draw_rect(Rect2(c + Vector2(-5, -30), Vector2(10, 52)), Color("#d9480f"))
	if value_text != "":
		art.draw_string(ThemeDB.fallback_font, c + Vector2(22, -6), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXT)


func _lamp(c: Vector2) -> void:
	if lamp_on:
		art.draw_circle(c + Vector2(0, -12), 46, Color(1, 0.9, 0.3, 0.35))
	art.draw_circle(c + Vector2(0, -12), 28, Color("#ffe066") if lamp_on else Color("#f1f3f5"))
	art.draw_arc(c + Vector2(0, -12), 28, 0, TAU, 32, Palette.DEVICE_DARK, 3, true)
	art.draw_rect(Rect2(c + Vector2(-14, 14), Vector2(28, 20)), Palette.DEVICE_DARK)
	if lamp_on:
		for i in 6:
			var a := -PI + i * PI / 5.0
			art.draw_line(c + Vector2(0, -12) + Vector2(cos(a), sin(a)) * 34, c + Vector2(0, -12) + Vector2(cos(a), sin(a)) * 44, Color("#e0a800"), 3)


func _presence(c: Vector2) -> void:
	art.draw_arc(c + Vector2(0, 10), 30, PI, TAU, 24, Palette.DEVICE_DARK, 4, true)
	art.draw_rect(Rect2(c + Vector2(-34, 10), Vector2(68, 14)), Palette.DEVICE_DARK)
	art.draw_circle(c + Vector2(0, -4), 9, Color("#c92a2a") if online else Palette.LED_OFF)
	if value_text != "":
		art.draw_string(ThemeDB.fallback_font, c + Vector2(-50, 50), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.TEXT)


func _panel(c: Vector2) -> void:
	var mon := Rect2(c + Vector2(-60, -48), Vector2(120, 76))
	art.draw_rect(mon, Palette.DEVICE_DARK)
	art.draw_rect(mon.grow(-6), Color("#0b1d33") if not online else Color("#123a5e"))
	if online:
		var pts := PackedVector2Array()
		for i in 8:
			pts.append(mon.position + Vector2(12 + i * 13, 52 - (i * 37 % 23)))
		art.draw_polyline(pts, Palette.SCREEN_ON, 3, true)
	if screen_text != "":
		_screen_label(mon, screen_text)
	art.draw_rect(Rect2(c + Vector2(-8, 28), Vector2(16, 10)), Palette.DEVICE_DARK)


func _printer(c: Vector2) -> void:
	art.draw_rect(Rect2(c + Vector2(-46, -14), Vector2(92, 42)), Palette.DEVICE_DARK)
	art.draw_rect(Rect2(c + Vector2(-30, -40), Vector2(60, 28)), Color.WHITE)
	art.draw_rect(Rect2(c + Vector2(-30, -40), Vector2(60, 28)), Palette.DEVICE_DARK, false, 2)
