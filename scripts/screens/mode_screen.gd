extends ScreenBase
## Escolha do modo: Guiado ou Explorador. Os dois concluem a história e dão as mesmas conquistas.


func build() -> void:
	background()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	center.add_child(col)
	heading(col, "Como você quer jogar?", 40, Color.WHITE)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	col.add_child(row)
	_card(row, "Modo Guiado", "Bit mostra o caminho.\nInstruções curtas.\nPoucas escolhas por vez.", Game.MODE_GUIDED, "help")
	_card(row, "Modo Explorador", "Menos orientações.\nMais opções.\nDesafios extras.", Game.MODE_EXPLORER, "map")
	var back := button(col, "Voltar", "back", func(): Game.goto("title"), "secondary", 64)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Voice.say("Como você quer jogar? Modo Guiado: Bit mostra o caminho. Modo Explorador: menos orientações e desafios extras.")


func _card(parent: Control, title: String, desc: String, mode: String, icon: String) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 0) * (Game.ui_scale() / 0.7)
	parent.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(0, 60)
	ic.draw.connect(func():
		ic.draw_circle(ic.size / 2.0, 26, Palette.PRIMARY)
		Icons.draw(ic, icon, ic.size / 2.0, 16, Color.WHITE))
	box.add_child(ic)
	heading(box, title, 32)
	var d := text(box, desc)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := button(box, "Escolher", "play", func():
		Game.new_game(mode)
		Game.goto("map"), "success", 80)
	if mode == Game.MODE_GUIDED:
		b.grab_focus.call_deferred()
