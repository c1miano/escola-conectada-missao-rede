extends ScreenBase
## Novo jogador: nome, avatar e modo de jogo.

var _name_edit: LineEdit
var _avatar := 0
var _mode := Game.MODE_GUIDED
var _avatar_buttons: Array = []
var _mode_buttons := {}
var _start: BigButton
var _msg: Label


func build() -> void:
	background()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var win := UiWindow.create("Novo jogador", 640.0 * Game.ui_scale() / 0.7)
	center.add_child(win.root)
	var body: VBoxContainer = win.body

	text(body, "1. Qual é o seu nome?")
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Digite seu nome"
	_name_edit.max_length = 20
	_name_edit.text_changed.connect(func(_t): _refresh())
	_name_edit.text_submitted.connect(func(_t): _go())
	body.add_child(_name_edit)

	text(body, "2. Escolha seu avatar:")
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	body.add_child(grid)
	for i in Game.AVATAR_COUNT:
		var b := Button.new()
		b.custom_minimum_size = Vector2(16, 16) * 4 + Vector2(10, 10)
		b.tooltip_text = "Avatar %d" % (i + 1)
		b.focus_mode = Control.FOCUS_ALL
		var av := AvatarView.new(i, 4)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(av)
		var idx := i
		b.pressed.connect(func():
			_avatar = idx
			Sfx.play("select")
			_refresh())
		grid.add_child(b)
		_avatar_buttons.append(b)

	text(body, "3. Como você quer jogar?")
	var modes := HBoxContainer.new()
	body.add_child(modes)
	_mode_buttons[Game.MODE_GUIDED] = button(modes, "Guiado: Bit mostra o caminho", "help", func():
		_mode = Game.MODE_GUIDED
		_refresh(), "secondary", 64)
	_mode_buttons[Game.MODE_EXPLORER] = button(modes, "Explorador: mais desafios", "map", func():
		_mode = Game.MODE_EXPLORER
		_refresh(), "secondary", 64)

	_msg = Label.new()
	_msg.add_theme_color_override("font_color", Palette.ATTENTION)
	body.add_child(_msg)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(bottom)
	_start = button(bottom, "Começar", "play", _go, "success", 76)
	button(bottom, "Voltar", "back", func(): Game.goto("players" if not Game.list_profiles().is_empty() else "title"), "secondary", 76)
	_refresh()
	_name_edit.grab_focus.call_deferred()
	Voice.say("Novo jogador. Digite seu nome, escolha um avatar e o modo de jogo.")


func _refresh() -> void:
	for i in _avatar_buttons.size():
		var b: Button = _avatar_buttons[i]
		var st := StyleBoxFlat.new()
		st.bg_color = Color("#fff3c4") if i == _avatar else Color.WHITE
		st.border_color = Palette.FOCUS if i == _avatar else Palette.FRAME_DARK
		st.set_border_width_all(4 if i == _avatar else 2)
		st.set_corner_radius_all(5)
		for s in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(s, st)
	for m in _mode_buttons:
		(_mode_buttons[m] as BigButton).set_variant("success" if m == _mode else "secondary")
	_start.disabled = _name_edit.text.strip_edges() == ""


func _go() -> void:
	var n := _name_edit.text.strip_edges()
	if n == "":
		_msg.text = "Digite seu nome para começar."
		_name_edit.grab_focus()
		return
	Game.create_profile(n, _avatar, _mode)
	Sfx.play("ok")
	Game.goto("map")
