class_name SwitchView
extends DeviceView
## Switch com portas clicáveis (botões grandes numerados).

signal port_clicked(index: int)

var ports: Array[Button] = []
var port_used: Array[bool] = []


func _init(n_ports: int = 4, p_title: String = "Switch") -> void:
	super._init("switch", p_title, "", "switch")
	show_led = false
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	move_child(row, 1)
	for i in n_ports:
		var b := Button.new()
		b.text = "Porta %d" % (i + 1)
		b.custom_minimum_size = Vector2(84, 56)
		b.add_theme_font_size_override("font_size", Game.fs(17))
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx := i
		b.pressed.connect(func(): use_port(idx))
		row.add_child(b)
		ports.append(b)
		port_used.append(false)


func use_port(idx: int) -> void:
	if DeviceView.interceptor.is_valid():
		DeviceView.interceptor.call(ports[idx], func(): port_clicked.emit(idx))
	else:
		port_clicked.emit(idx)


func set_port_used(i: int, used: bool) -> void:
	port_used[i] = used
	var b := ports[i]
	if used:
		b.text = "Porta %d\nligada" % (i + 1)
		b.add_theme_stylebox_override("normal", _port_style(Palette.SUCCESS))
		b.add_theme_stylebox_override("hover", _port_style(Palette.SUCCESS.lightened(0.1)))
	else:
		b.text = "Porta %d" % (i + 1)
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")


func free_port() -> int:
	for i in port_used.size():
		if not port_used[i]:
			return i
	return -1


func port_anchor(i: int) -> Vector2:
	return ports[i].get_global_rect().get_center()


func _port_style(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = col.darkened(0.3)
	s.set_border_width_all(3)
	s.set_corner_radius_all(10)
	s.content_margin_left = 6
	s.content_margin_right = 6
	return s
